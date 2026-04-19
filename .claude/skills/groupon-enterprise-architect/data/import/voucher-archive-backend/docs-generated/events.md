---
service: "voucher-archive-backend"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [jms, messagebus]
---

# Events

## Overview

The voucher-archive-backend participates in the Continuum JMS-based message bus for a single cross-service workflow: GDPR right-to-be-forgotten. It consumes an account erasure event, processes the erasure via the Retcon service, and publishes a completion event. Background job processing uses Redis/Resque for internal task queuing but this is not exposed as external events.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.queue.gdpr.account.v1.erased.complete` | GDPR erasure completion | RightToBeForgottenWorker finishes erasure | account_id, status, erased_at |

### GDPR Erasure Completion Detail

- **Topic**: `jms.queue.gdpr.account.v1.erased.complete`
- **Trigger**: `RightToBeForgottenWorker` successfully completes data erasure for a LivingSocial account via the Retcon Service
- **Payload**: account identifier, erasure status, completion timestamp
- **Consumers**: Upstream GDPR compliance orchestrator (tracked in central architecture model)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.gdpr.account.v1.erased` | GDPR account erasure request | `RightToBeForgottenWorker` (messageBusWorker) | Triggers PII erasure across voucher archive records via Retcon Service; publishes completion event |

### GDPR Account Erasure Detail

- **Topic**: `jms.topic.gdpr.account.v1.erased`
- **Handler**: `RightToBeForgottenWorker` — a background worker within `messageBusWorker` that receives the event and orchestrates erasure of personal data from LivingSocial voucher archive records
- **Idempotency**: No evidence found in codebase.
- **Error handling**: No evidence found in codebase. Expected to follow standard Resque retry behavior.
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase.
