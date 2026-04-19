---
service: "push-infrastructure"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [kafka, rabbitmq, mbus]
---

# Events

## Overview

Push Infrastructure participates in three async messaging systems. It consumes seven named Kafka topics that carry event-triggered message requests from upstream platform services. It publishes delivery status events to a RabbitMQ exchange. It also communicates with the Continuum internal MBus broker for platform-level events. Kafka consumption drives the bulk of high-volume, event-triggered email and push delivery.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `status-exchange` (RabbitMQ) | DeliveryStatus | Message delivery attempt completes | messageId, userId, channel, status, timestamp |

### DeliveryStatus Detail

- **Topic**: `status-exchange` (RabbitMQ exchange)
- **Trigger**: Completion (success or failure) of a message delivery attempt via SMTP, SMS Gateway, FCM, or APNs
- **Payload**: messageId, userId, channel (push/email/sms), deliveryStatus, errorCode (if failed), timestamp
- **Consumers**: Upstream campaign tracking and reporting services within Continuum
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `rm_daf` | DAF message event | Kafka consumer | Enqueues message for delivery processing |
| `rm_preflight` | Preflight check event | Kafka consumer | Validates and queues message for send |
| `rm_coupon` | Coupon notification event | Kafka consumer | Enqueues coupon push/email for delivery |
| `rm_user_queue_default` | Default user queue event | Kafka consumer | Enqueues general user message for delivery |
| `rm_rapi` | RAPI-triggered message event | Kafka consumer | Enqueues RAPI-sourced message for delivery |
| `rm_mds` | MDS message event | Kafka consumer | Enqueues MDS-sourced message for delivery |
| `rm_feynman` | Feynman message event | Kafka consumer | Enqueues Feynman-sourced message for delivery |

### rm_daf Detail

- **Topic**: `rm_daf`
- **Handler**: Kafka consumer reads event, extracts user/channel/template identifiers, enqueues message for rendering and delivery
- **Idempotency**: Delivery deduplication enforced via message state tracked in PostgreSQL
- **Error handling**: Failed processing logged to error store; retry via `/errors/retry` endpoint
- **Processing order**: unordered (partition-level ordering within Kafka, no global ordering guarantee)

### rm_preflight Detail

- **Topic**: `rm_preflight`
- **Handler**: Kafka consumer validates eligibility (user preferences, rate limits) before enqueuing
- **Idempotency**: State checked in PostgreSQL before enqueue
- **Error handling**: Validation failures logged; message not queued
- **Processing order**: unordered

### rm_coupon Detail

- **Topic**: `rm_coupon`
- **Handler**: Kafka consumer maps coupon event to push/email message and enqueues for delivery
- **Idempotency**: State checked in PostgreSQL
- **Error handling**: Failed messages recorded in error store
- **Processing order**: unordered

### rm_user_queue_default Detail

- **Topic**: `rm_user_queue_default`
- **Handler**: Default-priority Kafka consumer; general-purpose user message enqueue
- **Idempotency**: State tracked in PostgreSQL
- **Error handling**: Failed messages recorded in error store; retried via error management API
- **Processing order**: unordered

### rm_rapi Detail

- **Topic**: `rm_rapi`
- **Handler**: Kafka consumer for RAPI-originated message events
- **Idempotency**: State checked in PostgreSQL
- **Error handling**: Errors logged and available for retry
- **Processing order**: unordered

### rm_mds Detail

- **Topic**: `rm_mds`
- **Handler**: Kafka consumer for MDS (Merchant Data Service) triggered messages
- **Idempotency**: State checked in PostgreSQL
- **Error handling**: Errors logged and available for retry
- **Processing order**: unordered

### rm_feynman Detail

- **Topic**: `rm_feynman`
- **Handler**: Kafka consumer for Feynman (A/B testing / personalization) triggered messages
- **Idempotency**: State checked in PostgreSQL
- **Error handling**: Errors logged and available for retry
- **Processing order**: unordered

## Dead Letter Queues

> No evidence of dedicated dead-letter queues (DLQs) found in the inventory. Failed messages are recorded in the PostgreSQL error store and are retrievable via the `/errors/retry` and `/errors/clear` API endpoints, which serve as the effective error recovery mechanism.
