---
service: "consumer-data"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Consumer Data Service participates in the Continuum MessageBus (JMS-style topics and queues) for both publishing and consuming. Outbound events notify downstream services of changes to consumer profiles and locations. Inbound events drive two critical lifecycle operations: GDPR account erasure and new-account provisioning. The async worker container `continuumConsumerDataMessagebusConsumer` handles all inbound event processing.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.consumer.v2.consumers` | ConsumerUpdated | Consumer profile created or updated via API | consumer_id, profile fields |
| `jms.topic.consumer.v2.locations` | LocationChanged | Location created, updated, or deleted via API | consumer_id, location_id, location fields |
| `jms.topic.consumer.v3.consumers` | ConsumerUpdated (v3) | Consumer profile created or updated via API (v3 schema) | consumer_id, profile fields (v3 schema) |
| `jms.queue.gdpr.account.v1.erased.complete` | GdprErasureComplete | GDPR erasure processing successfully completed | account_id, erased_at |

### ConsumerUpdated (v2) Detail

- **Topic**: `jms.topic.consumer.v2.consumers`
- **Trigger**: Consumer profile write via `PUT /v1/consumers/:id` or account-creation event processing
- **Payload**: consumer_id and consumer profile fields
- **Consumers**: Downstream Continuum services requiring consumer data (checkout, order management)
- **Guarantees**: at-least-once

### LocationChanged Detail

- **Topic**: `jms.topic.consumer.v2.locations`
- **Trigger**: Location create, update, or delete via `/v1/locations`
- **Payload**: consumer_id, location_id, and location fields
- **Consumers**: Services depending on consumer location data
- **Guarantees**: at-least-once

### ConsumerUpdated (v3) Detail

- **Topic**: `jms.topic.consumer.v3.consumers`
- **Trigger**: Consumer profile write (v3 schema variant)
- **Payload**: consumer_id and profile fields using v3 schema
- **Consumers**: Services migrated to the v3 consumer event schema
- **Guarantees**: at-least-once

### GdprErasureComplete Detail

- **Topic**: `jms.queue.gdpr.account.v1.erased.complete`
- **Trigger**: Successful completion of GDPR account erasure processing
- **Payload**: account_id, erased_at timestamp
- **Consumers**: GDPR orchestration / compliance tracking service
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.gdpr.account.v1.erased` | GdprErasureRequested | `continuumConsumerDataMessagebusConsumer` GDPR handler | Anonymises/deletes consumer record; publishes erasure complete event |
| `jms.topic.users.account.v1.created` | AccountCreated | `continuumConsumerDataMessagebusConsumer` account creation handler | Provisions initial consumer profile record in MySQL |

### GdprErasureRequested Detail

- **Topic**: `jms.topic.gdpr.account.v1.erased`
- **Handler**: GDPR erasure handler in `continuumConsumerDataMessagebusConsumer` — soft-deletes or anonymises consumer record, then publishes `jms.queue.gdpr.account.v1.erased.complete`
- **Idempotency**: Consumer record deletion is idempotent if already deleted
- **Error handling**: No evidence found in codebase for explicit DLQ configuration; retry behaviour governed by MessageBus client defaults
- **Processing order**: unordered

### AccountCreated Detail

- **Topic**: `jms.topic.users.account.v1.created`
- **Handler**: Account creation handler in `continuumConsumerDataMessagebusConsumer` — inserts a new consumer row keyed to the new user account
- **Idempotency**: Insert may be guarded by unique constraint on account identifier
- **Error handling**: No evidence found in codebase for explicit DLQ configuration
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase for explicit DLQ topic configuration.
