---
service: "cs-groupon"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

cyclops participates in asynchronous messaging via the `messageBus` (MBus) integration, using the `messagebus` gem (v0.5.2). The `continuumCsBackgroundJobs` container is the sole async messaging participant — it consumes user update and erasure request events, and publishes a GDPR erasure completion confirmation event upon successful processing.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `gdpr.account.v1.erased.complete` | GDPR account erasure completion | Successful processing of a user erasure request | user_id, erased_at, status |

### gdpr.account.v1.erased.complete Detail

- **Topic**: `gdpr.account.v1.erased.complete`
- **Trigger**: Background job completes processing of a GDPR user erasure request received from the message bus
- **Payload**: user_id (identifier of the erased account), erased_at (timestamp of erasure), status (completion indicator)
- **Consumers**: Data privacy platform, regulatory compliance systems
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| user updates topic | User profile update | `csJobWorkers` (Resque background job) | Updates local CS data cache for affected user |
| user erasure request topic | GDPR erasure request | `csJobWorkers` (Resque background job) | Erases user PII from CS application data store; publishes `gdpr.account.v1.erased.complete` |

### User Profile Update Detail

- **Topic**: user updates topic (central MBus topic; exact topic name tracked in central architecture model)
- **Handler**: Resque worker within `continuumCsBackgroundJobs` picks up user update messages and refreshes the CS-local representation of the affected user
- **Idempotency**: Messages with the same user_id should produce equivalent state; repeat processing is safe
- **Error handling**: Resque retry with exponential backoff; failed jobs remain in the Resque failed queue for manual inspection
- **Processing order**: unordered

### GDPR Erasure Request Detail

- **Topic**: user erasure request topic (central MBus topic; exact topic name tracked in central architecture model)
- **Handler**: Resque worker within `continuumCsBackgroundJobs` performs PII erasure from `continuumCsAppDb` and then publishes the `gdpr.account.v1.erased.complete` confirmation
- **Idempotency**: Erasure operations are designed to be safe to re-run; subsequent processing of an already-erased user produces no change
- **Error handling**: Resque retry; failures are captured in the Resque failed queue and must be manually resolved before GDPR SLA deadline
- **Processing order**: unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| Resque `:failed` queue | All MBus-backed job queues | Until manually resolved | Operational procedures to be defined by service owner |

> The Resque `:failed` queue serves as a dead letter store for all failed async jobs, including MBus consumers. Messages that fail after retry exhaustion are held there for manual inspection and replay.
