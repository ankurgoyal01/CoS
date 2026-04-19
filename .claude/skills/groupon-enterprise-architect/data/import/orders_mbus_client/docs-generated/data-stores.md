---
service: "orders_mbus_client"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumOrdersMbusClientMessageStore"
    type: "mysql"
    purpose: "Durable outbound message queue with distributed locking and retry state"
---

# Data Stores

## Overview

Orders Mbus Client owns a single MySQL database that acts as a durable outbound message queue. Messages are written to this store (by the Orders Core Service or by the OMC itself), and the `MessagePublishingJob` Quartz job reads, locks, and publishes them to MBus. The store also tracks retry counts and message lifecycle status to support exponential-backoff retry and eventual abandonment.

## Stores

### orders_mbus_client Message Store (`continuumOrdersMbusClientMessageStore`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumOrdersMbusClientMessageStore` |
| Purpose | Durable outbound message queue with status tracking, distributed locking, and retry metadata |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `messages` | Stores outbound MBus messages pending publication, with lifecycle and lock metadata | `id`, `uuid`, `publisher`, `destination`, `content`, `status`, `retry_count`, `lock_key`, `release_at`, `created_at`, `updated_at` |

**Schema details (from Flyway migrations):**

- `V1.0__init.sql` — Creates `messages` table with `status ENUM('pending', 'failed', 'abandoned', 'completed')` and indexes on `uuid` and `status`.
- `V1.1__introduceProcessingMessageStatus.sql` — Adds `processing` to the status enum.
- `V1.2__introduceLockFieldOnMessages.sql` — Adds `lock_key VARCHAR(50)` and `release_at TIMESTAMP` columns with an index on `lock_key` for distributed publish locking.
- `V1.3__alterSizeOfLockKeyFieldOnMessages.sql` — Increases `lock_key` column size.

#### Access Patterns

- **Read**: `MessageDAO.getPersistedMessagesByLockKey(lockKey)` — fetches batch of messages locked by the current worker instance. `MessageDAO.getMessageCountForStatus(status)` — used by `MonitoringJob` to emit pending/processing/failed counts.
- **Write**: `lockPendingMessagesWithBatch(lockKey, releaseAt, batchSize)` — atomically locks up to `batchFetchSize` pending rows. `updatePersistedMessage(id, status, retryCount)` — marks messages as `completed`, `failed`, or `abandoned` after publish attempt. `lockMessageById(id, lockKey, releaseAt)` — locks a single failed message for manual retry.
- **Indexes**: `index_messages_on_uuid` (on `uuid`), `index_messages_on_status` (on `status`), `index_lock_key` (on `lock_key`).

**Production database host (NA)**: `orders-mbus-client-rw-na-production-db.gds.prod.gcp.groupondev.com`, database `orders_msg_prod`.

**Staging database host (NA)**: `orders-mbus-client-rw-na-staging-db.gds.stable.gcp.groupondev.com`, database `orders_msg_stg`.

## Caches

> No evidence found in codebase. The service does not use any caching layer.

## Data Flows

Outbound messages are inserted into `messages` by an upstream producer (Orders Core Service acts as publisher in the seed data). The `MessagePublishingJob` (every second via Quartz cron `0/1 * * * * ?`) locks a batch of `pending` rows, changes status to `processing`, and attempts to publish each to MBus. On success the row moves to `completed`. On failure the row moves to `failed` and a one-shot `RetryPublishingJob` is scheduled with exponential backoff (`2^retryCount` seconds). After `maxRetryCount` failures the row transitions to `abandoned`. A distributed lock key (`hostname-threadId-timestamp`) prevents concurrent replicas from processing the same message batch simultaneously.
