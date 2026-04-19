---
service: "inbox_management_platform"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumInboxManagementRedis"
    type: "redis"
    purpose: "Queues, locks, and transient state"
  - id: "continuumInboxManagementPostgres"
    type: "postgresql"
    purpose: "Runtime config and send error state"
  - id: "edw"
    type: "hive/teradata"
    purpose: "User attribute source (read-only)"
---

# Data Stores

## Overview

InboxManagement uses three data stores: a sharded Redis cluster as the operational high-throughput queue and lock store, a PostgreSQL instance for durable configuration and error state, and the Enterprise Data Warehouse (EDW via Hive JDBC) as a read-only source for user attribute loading. Redis is the hot path; Postgres is the system of record for config and errors; EDW is a periodic batch read.

## Stores

### Inbox Management Redis (`continuumInboxManagementRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumInboxManagementRedis` |
| Purpose | Sharded queue store for calculation and dispatch priority queues; distributed user locks preventing duplicate processing |
| Ownership | owned |
| Migrations path | > Not applicable — Redis schema is application-managed |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Calc queue | Priority queue of user-campaign pairs awaiting coordination processing | user_id, campaign_id, priority_score |
| Dispatch queue | Queue of dispatch-ready events awaiting RocketMan publication | user_id, campaign_id, channel, payload |
| User lock | Distributed lock preventing concurrent processing of the same user | user_id, ttl |
| Transient state | Short-lived operational state for in-flight coordination work | varies by workflow |

#### Access Patterns

- **Read**: `inbox_coordinationWorker` dequeues from calc queue; `inbox_dispatchScheduler` dequeues from dispatch queue; `inbox_queueMonitor` reads queue depths
- **Write**: `inbox_coordinationWorker` enqueues dispatch candidates; `inbox_userSyncProcessor` writes sync state; lock acquisition and release on all processing paths
- **Indexes**: Redis sorted sets used for priority queues (score = calculated send priority)

---

### Inbox Management Postgres (`continuumInboxManagementPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumInboxManagementPostgres` |
| Purpose | Durable operational store for runtime configuration key-value pairs and send error records |
| Ownership | owned |
| Migrations path | > Not discoverable from architecture model; to be confirmed by service owner |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Config store | Runtime configuration key-value pairs including throttle rates, daemon flags, circuit breakers | config_key, config_value, updated_at |
| Send error records | Persistent error state for failed send attempts, used for retry and reporting | send_id, user_id, campaign_id, error_type, error_at, retry_count |

#### Access Patterns

- **Read**: `inbox_configAndStateAccess` reads config on daemon startup and on admin query; `inbox_errorListener` reads error history for retry decisions
- **Write**: `inbox_adminApi` writes config changes via `inbox_configAndStateAccess`; `inbox_errorListener` inserts and updates error records
- **Indexes**: Config key indexed for point lookups; error records indexed by send_id and user_id

---

### Enterprise Data Warehouse — EDW (`edw`)

| Property | Value |
|----------|-------|
| Type | hive/teradata |
| Architecture ref | `edw` |
| Purpose | Source of user attribute data loaded during user synchronization (read-only) |
| Ownership | external |
| Migrations path | > Not applicable — read-only access |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| User attributes | Demographic and behavioral attributes used to enrich dispatch decisions | user_id, attribute_key, attribute_value |

#### Access Patterns

- **Read**: `inbox_userSyncProcessor` reads user attribute snapshots via Hive JDBC (hive-jdbc 2.0.0) during synchronization runs
- **Write**: Not applicable — InboxManagement has read-only access
- **Indexes**: Queried by user_id batch ranges

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumInboxManagementRedis` | redis | Calc/dispatch priority queues and user locks (also serves as primary queue store) | TTL per lock; queue entries expire after configurable window |

## Data Flows

1. Campaign Management publishes CampaignSendEvents; `inbox_coordinationWorker` writes user-campaign entries to the Redis calc queue.
2. EDW user attributes are periodically batch-loaded by `inbox_userSyncProcessor` into Redis and/or Postgres sync state.
3. Coordination workers dequeue from Redis, process, and promote dispatch-ready records back to Redis dispatch queue.
4. `inbox_dispatchScheduler` dequeues from Redis dispatch queue, and `inbox_rocketmanPublisher` produces SendEvents to Kafka.
5. Send errors flow back via Kafka to `inbox_errorListener`, which persists records to Postgres for tracking and retry.
6. Admin config changes are written to Postgres via the Admin API and read by all running daemons through `inbox_configAndStateAccess`.
