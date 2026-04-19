---
service: "identity-service"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

identity-service participates extensively in the Groupon Message Bus (Thrift g-bus). The HTTP API container (`continuumIdentityServiceApp`) publishes identity lifecycle events when identities are created, updated, or erased. The Mbus consumer container (`continuumIdentityServiceMbusConsumer`) consumes GDPR erasure requests and dog-food audit events. Erasure completion is confirmed via a dedicated GDPR event published after successful data removal.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `identity.v1.event` | `created` | New identity created via `POST /v1/identities` | uuid, created_at, identity attributes |
| `identity.v1.event` | `updated` | Identity updated via `PUT /v1/identities/{uuid}` | uuid, updated_at, changed fields |
| `identity.v1.event` | `erased` | Erasure request processed | uuid, erased_at |
| `identity.v1.c2.event` | `created` | New identity created (C2 channel) | uuid, created_at, identity attributes |
| `identity.v1.c2.event` | `updated` | Identity updated (C2 channel) | uuid, updated_at, changed fields |
| `identity.v1.c2.event` | `erased` | Erasure processed (C2 channel) | uuid, erased_at |
| `gdpr.account.v1.erased.complete` | `erased.complete` | GDPR erasure fully completed | uuid, erased_at, confirmation reference |

### `identity.v1.event` Detail

- **Topic**: `identity.v1.event`
- **Trigger**: Identity created, updated, or erased via the HTTP API
- **Payload**: Identity UUID, timestamp, and relevant changed fields; exact schema defined by Thrift IDL
- **Consumers**: Downstream Groupon services tracking identity state (platform-wide)
- **Guarantees**: at-least-once (Message Bus Thrift delivery semantics)

### `identity.v1.c2.event` Detail

- **Topic**: `identity.v1.c2.event`
- **Trigger**: Same lifecycle events as `identity.v1.event` — published in parallel on the C2 channel
- **Payload**: Same structure as `identity.v1.event`
- **Consumers**: C2-channel consumers; exact consumers tracked in the central architecture model
- **Guarantees**: at-least-once

### `gdpr.account.v1.erased.complete` Detail

- **Topic**: `gdpr.account.v1.erased.complete`
- **Trigger**: GDPR erasure of an identity record is fully completed by the Mbus consumer worker
- **Payload**: Identity UUID, erasure timestamp, completion reference; exact schema defined by GDPR platform contract
- **Consumers**: GDPR Platform (for compliance confirmation tracking)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| GDPR erasure request topic | GDPR erasure request | `continuumIdentityServiceMbusConsumer` | Removes identity data from PostgreSQL; publishes `gdpr.account.v1.erased.complete` |
| Dog-food audit event topic | Audit event | `continuumIdentityServiceMbusConsumer` | Writes audit record to internal audit trail |

### GDPR Erasure Request Detail

- **Topic**: GDPR erasure request topic (exact topic name managed by the GDPR Platform; to be confirmed)
- **Handler**: `continuumIdentityServiceMbusConsumer` — Resque-backed worker dispatched via g-bus consumer
- **Idempotency**: Erasure is idempotent — re-processing an already-erased identity is a no-op
- **Error handling**: Failed erasure jobs are retried via Resque retry mechanism; dead-lettering strategy to be confirmed with the service owner
- **Processing order**: unordered

### Dog-food Audit Event Detail

- **Topic**: Dog-food audit event topic (exact topic name to be confirmed)
- **Handler**: `continuumIdentityServiceMbusConsumer` — writes audit entries to the internal audit store
- **Idempotency**: To be confirmed by service owner
- **Error handling**: Resque retry on failure
- **Processing order**: unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| Resque failed queue | GDPR erasure request topic | To be confirmed | To be configured by service owner |
| Resque failed queue | Dog-food audit event topic | To be confirmed | To be configured by service owner |
