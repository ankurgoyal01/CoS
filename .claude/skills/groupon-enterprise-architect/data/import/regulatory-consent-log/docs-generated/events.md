---
service: "regulatory-consent-log"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus, redis-pubsub]
---

# Events

## Overview

The Regulatory Consent Log uses two async messaging systems. The Message Bus (MBus / ActiveMQ Artemis) carries user erasure events, erasure completion notifications, consent log messages, and user reactivation events. Redis (RaaS) is used as an intermediate work queue and pub/sub channel within the cookie erasure pipeline. The Utility Worker container handles all event consumption and publishing; the API container writes to the Cronus transactional outbox, which the worker then flushes to MBus.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| MBus consent log topic | `ErasureMessage` (Cronus outbox) | Consent written via `POST /v1/consents` | `identifier`, `containerVersion`, `messageVersion`, `payloadType`, `creationTime`, `messageType`, `payload` |
| MBus erasure-complete topic | Erasure complete notification | User erasure pipeline finishes writing erased b-cookie mappings to Postgres | User ID, erasure status |
| Redis pub/sub channel | User erasure work item | MBus user erasure event received by listener | Erased user UUID |

### Consent Log Message (Cronus Outbox) Detail

- **Topic**: MBus consent log topic (Cronus destination configured per environment)
- **Trigger**: `POST /v1/consents` — the Create Consent Transaction Adapter writes both the consent DB row and a `mbus_messages` outbox row atomically; the Cronus Publisher Quartz job picks these up periodically and publishes to MBus.
- **Payload**: `MessageBusPayload` containing `identifier` (UUID), `containerVersion`, `messageVersion` (`1.0`), `payloadType` (`JSON`), `creationTime` (epoch ms), `messageType` (`ErasureMessage`), and a `payload` map with consent details.
- **Consumers**: Downstream regulatory analytics and audit consumers (tracked in central architecture model).
- **Guarantees**: At-least-once (Cronus outbox pattern with retry tracking via `processing_status` and `attempts` columns).

### Erasure Complete Notification Detail

- **Topic**: MBus erasure-complete topic
- **Trigger**: `User Erased Redis Pub/Sub Worker` completes writing erased b-cookie mappings to Postgres and calls `Cronus Publisher`.
- **Payload**: Contains user ID and erasure completion status.
- **Consumers**: Downstream services awaiting erasure completion confirmation.
- **Guarantees**: At-least-once.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| MBus user erasure topic | User erased event | `User Erasure MBus Listener` | Enqueues user UUID into Redis work queue; ACKs message |
| MBus erasure-complete topic | Erasure complete message | `Erasure Complete Message Reader` | Updates erasure completion status in Postgres via `Erasure Complete Processor` |
| MBus user reactivation topic | User reactivation event | `User Reactivation Consumer` | Updates erasure state records in Postgres via `User Reactivation Processor` |
| Redis pub/sub channel | User erasure work item | `User Erased Redis Pub/Sub Worker` | Calls Janus Aggregator for b-cookie list; writes cookies to Postgres; publishes erasure-complete event |

### User Erased Event Detail

- **Topic**: MBus user erasure topic (subscription ID: `rfs_gapi`; durable in production, non-durable in staging)
- **Handler**: `continuumRegulatoryConsentLogWorker_userErasureMessageListener` — receives message, persists user UUID to Redis queue, ACKs immediately to MBus.
- **Idempotency**: Duplicate erasure requests are detected and excluded from retry (recorded as non-retryable in Redis error queue).
- **Error handling**: On exception, failure is recorded in Redis (RaaS) error queue. Retryable errors (e.g. DB unreachable) are retried up to 10 times by default; duplicate/non-retryable errors are removed from the queue.
- **Processing order**: Unordered (each user UUID processed independently via Redis queue).

### Erasure Complete Message Detail

- **Topic**: MBus erasure-complete topic
- **Handler**: `continuumRegulatoryConsentLogWorker_erasureCompleteMessageReader` routes to `continuumRegulatoryConsentLogWorker_erasureCompleteProcessor`.
- **Idempotency**: Status update is idempotent on the Postgres record.
- **Error handling**: Standard MBus retry semantics.
- **Processing order**: Unordered.

### User Reactivation Event Detail

- **Topic**: MBus user reactivation topic
- **Handler**: `continuumRegulatoryConsentLogWorker_managedReactivationConsumer` routes to `continuumRegulatoryConsentLogWorker_userReactivationProcessor`.
- **Idempotency**: Erasure state update is idempotent.
- **Error handling**: Standard MBus retry semantics.
- **Processing order**: Unordered.

## Dead Letter Queues

> No evidence found in codebase for named DLQ topics. Failed Redis erasure work items are recorded in the RaaS error queue; MBus delivery failures are tracked via the MBus dashboard and retried by the broker.
