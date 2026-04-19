---
service: "deletion_service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The Deletion Service is heavily event-driven. It consumes GDPR account erase events from MBUS topics and publishes per-service and per-request erase completion events to an MBUS queue. Two separate MBUS consumers are configured: one for default account erasures and one for SMS consent (Attentive) erasures. The JTier `jtier-messagebus-client` library provides the consumer and writer abstractions.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.queue.gdpr.account.v1.erased.complete` | Erase Completion | Erasure of a customer record in a downstream service is confirmed | `accountId`, `serviceId`, `erasedAt`, `publishedAt` |

### Erase Completion Event Detail

- **Topic**: `jms.queue.gdpr.account.v1.erased.complete` (configured in application as `EraseCompletedTopic`)
- **Trigger**: Published once per downstream service successfully erased AND once for the overall request on full completion. Published by `MessagePublisher.publishCompleteMessage()`.
- **Payload**: `PublishMessage` with fields:
  - `accountId` (string) — customer UUID
  - `serviceId` (string) — the service portal ID of the service that completed erasure (e.g. `goods:orders`, `sms-consent-service`, `deletion_service` for the overall completion)
  - `erasedAt` (timestamp) — time the erasure was executed
  - `publishedAt` (timestamp) — time the message was published
- **Consumers**: Downstream GDPR reporting and audit pipelines (not owned by this service)
- **Guarantees**: at-least-once (MBUS JMS queue semantics; the publisher retries on error are logged but not guaranteed)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.gdpr.account.v1.erased` | Account Erase | `EraseProcessor` (Erase Message Worker) | Creates erase request and per-service records in Deletion Service DB |
| `jms.topic.scs.subscription.erasure` | SMS Consent Erasure | `EraseProcessor` (SMS consent variant) with `EraseOption.ATTENTIVE` | Creates erase request scoped to `SMS_CONSENT_SERVICE` in Deletion Service DB |

### Account Erase Event Detail

- **Topic**: `jms.topic.gdpr.account.v1.erased`
- **Handler**: `EraseProcessor` — implements JTier `MessageProcessor<EraseMessage>`
- **Payload**: `EraseMessage` with fields:
  - `accountId` (string) — customer UUID
  - `erasedAt` (timestamp) — time the erasure was requested
  - `publishedAt` (timestamp) — time the source published the event
  - `serviceId` (string) — originating service identifier
- **Idempotency**: Partial — if `force=false` on manual requests, duplicate customer IDs are skipped at the API layer. The MBUS consumer does not de-duplicate; re-delivery of the same event creates a new erase request record.
- **Error handling**: On `null` payload, the message is NACKed. On processing exception, the message is NACKed and an error metric is emitted. The MBUS broker handles redelivery.
- **Processing order**: Unordered

### SMS Consent Erasure Event Detail

- **Topic**: `jms.topic.scs.subscription.erasure` (configured as `smsConsentMessageBus.eraseTopic`)
- **Handler**: `EraseProcessor` instantiated with `EraseOption.ATTENTIVE` and `isEmea` region flag
- **Idempotency**: Same as the account erase event above
- **Error handling**: Same NACk-on-error strategy
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase of explicit dead letter queue configuration. MBUS broker-level DLQ behaviour applies by default.
