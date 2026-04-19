---
service: "message2ledger"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumMessage2LedgerMysql"
    type: "mysql"
    purpose: "Operational datastore and queue state for messages, attempts, subjects, and replay metadata"
---

# Data Stores

## Overview

message2ledger owns a single MySQL 5.7 database (`continuumMessage2LedgerMysql`) that serves as both the operational message store and the persistent queue backing the Async Task Processor. All inbound MBus events are written here before processing, and all attempt state, subject metadata, activity records, and replay history are maintained in this store. Schema migrations are managed by Flyway.

## Stores

### message2ledger MySQL (`continuumMessage2LedgerMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumMessage2LedgerMysql` |
| Purpose | Operational datastore and queue state for messages, attempts, subjects, and replay metadata |
| Ownership | owned |
| Migrations path | Managed by Flyway 7.15.0 (path to be confirmed in service repository) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `messages` | Persists raw inbound MBus message envelopes for order and inventory events | message id, topic, region, payload, status, created_at |
| `attempts` | Tracks each processing attempt for a message, including success/failure state and error details | attempt id, message id, status, attempt_count, error, updated_at |
| `subjects` | Stores subject (unit/order) metadata associated with a message for enrichment context | subject id, message id, subject_type, external_id |
| `activity` | Records unit lifecycle activity for admin investigation via `/admin/units/{id}/activity` | activity id, unit id, event_type, occurred_at |

#### Access Patterns

- **Read**: `m2l_persistence` loads message and attempt records for in-flight processing; `m2l_replayAndRetryApi` reads message and attempt history for admin queries; `m2l_processingOrchestrator` reads queue state to schedule and execute next attempts; reconciliation flow queries EDW and then cross-references against this store
- **Write**: `m2l_mbusIngress` inserts new message envelopes on event receipt; `m2l_processingOrchestrator` updates attempt state throughout the processing lifecycle; `m2l_accountingIntegration` writes final processing outcomes and statuses after ledger post
- **Indexes**: Index details to be confirmed in service repository migration scripts

## Caches

> No evidence found for any cache layer. message2ledger does not use Redis, Memcached, or in-memory caches.

## Data Flows

Inbound MBus events are written to the `messages` table by `m2l_mbusIngress` immediately on receipt. The `m2l_processingOrchestrator` (backed by the KillBill Queue) reads pending messages and creates rows in `attempts` as processing progresses. On successful ledger post, `m2l_accountingIntegration` writes the final status back to the `attempts` and `messages` tables. The EDW (`edw`) is queried via JDBC as a read-only source to identify messages eligible for automated reconciliation replay; no data is written to EDW by this service.
