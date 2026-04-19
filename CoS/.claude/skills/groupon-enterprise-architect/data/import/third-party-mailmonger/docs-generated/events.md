---
service: "third-party-mailmonger"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Third Party Mailmonger uses Groupon's internal MessageBus (ActiveMQ Artemis via JTier MessageBus) for asynchronous email processing. When SparkPost delivers an inbound relay email via webhook, the service logs the raw email to PostgreSQL and publishes a `MailmongerEmailMessage` event to the MessageBus queue. A pool of MessageBus consumer threads picks up the event, runs the filter pipeline, and sends the outbound email. This decouples inbound receipt from outbound delivery and enables retry logic.

The service also listens for user email-update events from the MessageBus (produced by users-service when a consumer changes their email address) so that cached consumer-to-partner email mappings can be invalidated or updated.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.queue.3pip.mailmonger` | `MailmongerEmailMessage` | SparkPost relay webhook delivers an inbound email | `uuid` (email content ID, UUID) |

### MailmongerEmailMessage Detail

- **Topic**: `jms.queue.3pip.mailmonger`
- **Trigger**: SparkPost delivers an inbound relay email via `POST /mailmonger/v1/sparkpost-callback`; after the raw email is saved to the `email_content` table, a message containing the `uuid` (emailContentId) is published
- **Payload**: `{ "uuid": "<UUID of stored email content>" }` — minimal pointer message; the full email content is retrieved from the database by the consumer
- **Consumers**: The `MessageBus Consumer` component within the same service instance (self-consumption pattern for async processing)
- **Guarantees**: At-least-once (Mbus STOMP with `nack` on parse failure triggers redelivery; `ack` on successful processing or terminal failure)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.queue.3pip.mailmonger` | `MailmongerEmailMessage` | `EmailProcessor` (messagebus package) | Runs filter pipeline; sends email via SparkPost or MTA; updates email status in PostgreSQL |
| MessageBus (users-service topic) | User email update | `UsersServicePollingTask` | Refreshes internal user/partner data cache to reflect new consumer email address |

### MailmongerEmailMessage Consumer Detail

- **Topic**: `jms.queue.3pip.mailmonger`
- **Handler**: `EmailProcessor` — resolves email content from PostgreSQL by UUID, applies filter rules (SpamFilter, DailyEmailCountByPartnerFilter, RfcBase64Filter, WhiteListUrlFilter, UnauthorizedPartnerEmailFilter, optionally BlackHoleRule), transforms headers and addresses, sends via SparkPost or MTA, updates delivery status
- **Idempotency**: Guarded by `sentCount` and `MAX_SEND_LIMIT` (3 attempts); `NonRetriable` status prevents reprocessing
- **Error handling**: Parse errors result in `nack` and `NonRetriable` status; SparkPost/MTA send errors result in `SparkpostFailure`/`MtaFailure` status; filter failures result in `FilterFailure` status; messages are retried up to 3 times before marking as terminal
- **Processing order**: Unordered (concurrent worker pool via `MessageWorkerPool`)

### User Email Update Consumer Detail

- **Topic**: MessageBus topic published by users-service (exact topic name defined by users-service; consumed via polling task)
- **Handler**: `UsersServicePollingTask` / `UserServiceClientWrapper` — updates internal mapping of consumer email addresses when users-service notifies of a change
- **Idempotency**: Cache refresh is idempotent
- **Error handling**: Polling continues on failure; stale cache is tolerated until next poll cycle
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase of an explicitly configured DLQ. Failed messages that exceed MAX_SEND_LIMIT are marked with terminal statuses (`NonRetriable`, `FilterFailure`, `SparkpostFailure`, `MtaFailure`) in the database and acknowledged from the queue. Operational retry can be triggered via `POST /v1/email/{emailContentId}/retry`.
