---
service: "mailman"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Mailman participates in async messaging through MBus (JMS-based). It consumes transactional email requests arriving on `MailmanQueue`, processes them through the workflow engine (including domain context enrichment), and publishes enriched `TransactionalEmailRequest` payloads back onto MBus for Rocketman to deliver. A Dead Letter Queue (DLQ) handles messages that fail processing. The `continuumMailmanMessageBusIntegration` component manages both consumption and publication.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `messageBus` (MBus) | `TransactionalEmailRequest` | Workflow engine completes context enrichment for an inbound request | Notification type, recipient, enriched order/user/deal/merchant context |

### TransactionalEmailRequest Detail

- **Topic**: `messageBus` (MBus/JMS)
- **Trigger**: Workflow engine successfully aggregates all required domain context for an inbound mail request (submitted via API or consumed from queue)
- **Payload**: Enriched notification payload containing recipient details, notification type, and domain-specific context (order, user, deal, merchant, inventory data as applicable)
- **Consumers**: Rocketman — consumes this event to render and deliver the transactional email
- **Guarantees**: at-least-once (MBus/JMS with deduplication guard in `mailmanPostgres`)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `MailmanQueue` (MBus) | Transactional email request | `continuumMailmanMessageBusIntegration` | Dispatches to workflow engine; writes request state to `mailmanPostgres`; triggers domain context enrichment |
| DLQ (MBus) | Failed transactional email request | `continuumMailmanMessageBusIntegration` | Logs failure; persists retry state to `mailmanPostgres` for scheduled retry |

### MailmanQueue Detail

- **Topic**: `MailmanQueue`
- **Handler**: `continuumMailmanMessageBusIntegration` listens on the queue and dispatches each message to `continuumMailmanWorkflowEngine` via an in-process call
- **Idempotency**: Yes — duplicate detection performed via `mailmanPostgres` deduplication state before processing
- **Error handling**: Failed messages are routed to DLQ; DLQ messages are persisted to `mailmanPostgres` and eligible for scheduled or manual retry
- **Processing order**: Unordered (standard JMS queue semantics)

### DLQ Detail

- **Topic**: DLQ (MBus)
- **Handler**: `continuumMailmanMessageBusIntegration` consumes DLQ messages and persists them to `mailmanPostgres` for retry
- **Idempotency**: Yes — retry state tracks prior attempts
- **Error handling**: Retry attempts managed by Quartz scheduler; manual retry available via `POST /mailman/retry`
- **Processing order**: Unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| DLQ (MBus) | `MailmanQueue` | No evidence found | No evidence found |
