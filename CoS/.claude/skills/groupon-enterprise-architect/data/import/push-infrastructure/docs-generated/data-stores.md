---
service: "push-infrastructure"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "externalTransactionalDatabase_3f1a"
    type: "postgresql/mysql"
    purpose: "Message state, campaign records, error log, scheduling metadata"
  - id: "externalRedisCluster_5b2e"
    type: "redis"
    purpose: "Template cache, delivery queues, rate-limit counters"
  - id: "externalHdfs_7c9d"
    type: "hdfs"
    purpose: "Batch delivery log archive"
---

# Data Stores

## Overview

Push Infrastructure uses three distinct storage layers: a relational database (PostgreSQL/MySQL) for durable transactional state, a Redis cluster for low-latency caching and queue management, and HDFS for batch delivery log archival. The relational database is the system of record for message lifecycle state, error tracking, and scheduling metadata. Redis accelerates template rendering and enforces per-user rate limits. HDFS stores completed delivery logs for downstream analytics.

## Stores

### Transactional Database (`externalTransactionalDatabase_3f1a`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL / MySQL |
| Architecture ref | `externalTransactionalDatabase_3f1a` |
| Purpose | Message state, campaign records, scheduling metadata, error log |
| Ownership | shared |
| Migrations path | > No evidence of migrations path found in inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `messages` (logical) | Tracks lifecycle state of each message delivery attempt | messageId, userId, channel, status, createdAt, updatedAt |
| `campaigns` (logical) | Stores campaign assembly and scheduling metadata | campaignId, templateId, scheduleTime, status |
| `errors` (logical) | Records failed delivery attempts for retry management | errorId, messageId, errorCode, errorMessage, retryCount, timestamp |
| `schedules` (logical) | Quartz job metadata for time-delayed and cron sends | jobId, triggerTime, payload, status |

#### Access Patterns

- **Read**: Message state lookups by messageId and userId; campaign metadata reads during assembly; error record queries for retry eligibility
- **Write**: Message state transitions on each lifecycle event; error record inserts on delivery failure; schedule record creates/updates; campaign status updates on delivery completion
- **Indexes**: Indexes expected on messageId, userId, campaignId, and status columns for query performance (specific index definitions not visible in inventory)

---

### Redis Cluster (`externalRedisCluster_5b2e`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `externalRedisCluster_5b2e` |
| Purpose | Template cache, delivery queues, per-user rate-limit counters |
| Ownership | shared |
| Migrations path | > Not applicable — schema-less |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Template cache entries | Stores pre-rendered or fetched FreeMarker template content indexed by template identifier | templateId, renderedContent |
| Delivery queues | Per-channel lists/queues holding messages awaiting dispatch | channel (push/email/sms), userId, messagePayload |
| Rate-limit counters | Per-user/channel sliding window counters for delivery rate enforcement | userId, channel, count, windowExpiry |

#### Access Patterns

- **Read**: Template cache GET by templateId before each render; rate-limit counter GET before each delivery attempt; queue POP on processor worker cycle
- **Write**: Template cache SET/SETEX on cache miss (populated from template store); rate-limit INCR with TTL-based expiry; queue PUSH on message enqueue; cache DEL on invalidation via `/cache/invalidate`
- **Indexes**: Redis key-based access; no secondary indexes

---

### HDFS (`externalHdfs_7c9d`)

| Property | Value |
|----------|-------|
| Type | Hadoop HDFS |
| Architecture ref | `externalHdfs_7c9d` |
| Purpose | Batch delivery log archive for analytics and auditing |
| Ownership | shared |
| Migrations path | > Not applicable — file-based storage |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Delivery log files | Append-only batch records of completed message delivery events | timestamp, messageId, userId, channel, status, campaignId |

#### Access Patterns

- **Read**: Batch analytics jobs read log files from HDFS for reporting and aggregation
- **Write**: Push Infrastructure writes delivery event batches to HDFS using the Hadoop client (hadoop 2.5.0-cdh5.3.1) on completion of delivery cycles
- **Indexes**: > Not applicable — file-based sequential access

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Template cache | Redis | Stores rendered/fetched FreeMarker templates to avoid repeated retrieval and compilation | Configurable per template; invalidated explicitly via `/cache/invalidate` |
| Rate-limit counters | Redis | Sliding-window counters to enforce per-user/channel delivery rate limits | Short TTL aligned to rate-limit window |
| Delivery queues | Redis | Transient per-channel message queues between ingestion and dispatch workers | Consumed on processing; no explicit expiry under normal operation |

## Data Flows

1. Message ingestion (REST API or Kafka consumer) writes initial message state to the **Transactional Database** and pushes a queue entry to **Redis**.
2. Queue processor workers consume from **Redis** delivery queues, fetch the FreeMarker template from the **Redis template cache** (populating from the template store on cache miss), render the message, and dispatch to the channel (SMTP/SMS/FCM/APNs).
3. On delivery completion, the message state in the **Transactional Database** is updated and a delivery log record is written to **HDFS** for archival.
4. Delivery status events are published to **RabbitMQ** `status-exchange` for upstream consumption.
5. On delivery failure, error records are inserted into the **Transactional Database** and made available for retry via the error management API.
