---
service: "gaurun"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "kafka-topics"
    type: "kafka"
    purpose: "Notification queuing and retry durability"
  - id: "in-memory-queues"
    type: "in-memory"
    purpose: "Per-context buffering between Kafka consumers and push workers"
  - id: "send-log-files"
    type: "file"
    purpose: "Push delivery audit log for analytics and failure replay"
---

# Data Stores

## Overview

Gaurun is stateless and owns no persistent database. Its durability model relies on Kafka topics for notification queuing and retry, Go channel-based in-memory queues for worker dispatch, and rolling log files for push delivery audit. Log files are shipped to the central Kafka cluster by a Logstash sidecar.

## Stores

### Kafka Topics (`kafka-topics`)

| Property | Value |
|----------|-------|
| Type | Kafka |
| Architecture ref | `kafkaCluster_2f6b9d` |
| Purpose | Durable notification queuing for Android/iOS push delivery and retry |
| Ownership | Shared (cluster managed externally) |
| Migrations path | Not applicable |

#### Key Topics

| Topic | Purpose | Key Fields |
|-------|---------|-----------|
| `android_gaurun_pn` | Android notification queue between ingestor and push workers | `token`, `platform`, `context`, `message`, `vctx` |
| `ios_gaurun_pn` | iOS notification queue between ingestor and push workers | `token`, `platform`, `context`, `message`, `vctx` |
| `mta.gaurun.retry` | Failed notification retry queue with minimum age enforcement | `token`, `platform`, `context`, `attempts`, `created` |

#### Access Patterns

- **Read**: Kafka consumers (`gaurunKafkaConsumer`, `RetryQueueProcessorNew`) poll continuously with offset reset `earliest`. Three consumer goroutines per topic (`StartKafkaConsumer` spawns 3).
- **Write**: Kafka producers (`gaurunKafkaProducer`) publish JSON-marshalled `RequestGaurunNotification` records. Producer uses `acks=1`, `compression.codec=lz4`, `queue.buffering.max.ms=100`. On local queue full, flushes with 30-second timeout.
- **Indexes**: Not applicable (Kafka).

### In-Memory Channel Queues (`in-memory-queues`)

| Property | Value |
|----------|-------|
| Type | in-memory (Go channels) |
| Architecture ref | `gaurunQueueManager` |
| Purpose | Per-context buffering between Kafka consumers and platform push workers |
| Ownership | Owned (ephemeral, per-process) |
| Migrations path | Not applicable |

#### Key Queues

| Queue | Purpose | Key Fields |
|-------|---------|-----------|
| `AndroidProducerQueueNotification` | Android notifications staged for Kafka publication | `RequestGaurunNotification`, capacity 100,000 |
| `APNSProducerQueueNotification` | iOS notifications staged for Kafka publication | `RequestGaurunNotification`, capacity 100,000 |
| `QueueMerchantNotification` | Merchant Android notifications (bypasses Kafka) | `RequestGaurunNotification`, capacity 100 |
| Per-context queues (e.g., `android-fcm-consumer`, `iphone-consumer`) | Named queues created from `[android-context]` and `[ios-context]` TOML entries | `RequestGaurunNotification` |

#### Access Patterns

- **Read**: Platform push workers block on their assigned channel (`pushNotificationIosWorker`, `pushNotificationAndroidWorker`, `pushNotificationMerchantWorker`).
- **Write**: Kafka consumer goroutines route inbound messages into named context queues via `ContextQueues.GetQueue(contextName)`.
- **Indexes**: Not applicable (channel-based).

### Send Log Files (`send-log-files`)

| Property | Value |
|----------|-------|
| Type | File (rolling, JSON) |
| Architecture ref | `gaurunAccessLogger` |
| Purpose | Push delivery audit log — successful sends and failures — forwarded to Kafka via Logstash |
| Ownership | Owned (ephemeral, mounted volume) |
| Migrations path | Not applicable |

#### Key Files

| File | Purpose | Key Fields |
|------|---------|-----------|
| `/var/groupon/gaurun/sends/send.log` | Successful push delivery records | Token, platform, status, timing |
| `/var/groupon/gaurun/sends/failed.log` | Failed push delivery records | Token, platform, error, status |
| `/app/log/gaurun_access.log` | HTTP access log (JSON) | Request path, method, response code |
| `/app/log/gaurun_error.log` | Application error log (JSON) | Error messages, stack traces |
| `/app/log/gaurun_accept.log` | Accepted notification log (JSON) | Notification IDs, retry attempts |

#### Access Patterns

- **Read**: Logstash sidecar (`logstash` container) tails `send.log` and `failed.log` via file input plugin; ships to Kafka cluster as `push_service` and `mta_push_bounce` event types.
- **Write**: `lumberjack`-managed rolling logger writes to send/failed log files. `zap` logger writes to access/error/accept log files.
- **Indexes**: Not applicable (flat files).

## Caches

> No caches. Gaurun does not use Redis, Memcached, or in-process LRU caches.

## Data Flows

Inbound notification JSON arrives at the HTTP API, is unmarshalled and validated, then placed on the `AndroidProducerQueueNotification` or `APNSProducerQueueNotification` channel. Kafka producer goroutines read from these channels and publish to `android_gaurun_pn` or `ios_gaurun_pn` Kafka topics. Kafka consumer goroutines read from these same topics and route into per-context in-memory channels. Push worker goroutines consume from the per-context channels, dispatch to APNs or FCM, and write results to `send.log` or `failed.log`. The Logstash sidecar forwards those log files to the central Kafka cluster for downstream analytics. Failed notifications are published to `mta.gaurun.retry`, consumed by the Retry Processor, and re-submitted to `/grpn/retry`.
