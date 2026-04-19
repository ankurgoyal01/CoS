---
service: "coupons-revproc"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

coupons-revproc uses the Groupon internal message bus (Mbus, JMS-based) to publish processed coupon transaction data downstream. For every qualifying core-coupon transaction that has a deal UUID and a bcookie, the service publishes two paired messages: a `click` message and a `redemption` message. These messages are consumed by attribution and reporting systems (referred to as "Janus" in the codebase). No events are consumed from Mbus — ingestion is pull-based (AffJet API polling) rather than event-driven. The message bus client (`revproc_messageBusClient`) wraps the JTier `jtier-messagebus-client` library and the destination topic IDs are configured via the `messagebus` config block.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Mbus destination (click type) | Click message (`ClickMbusPayload`) | Transaction finalization for a core coupon with deal UUID and bcookie | uuid, country, clickId, attributionId, bcookie, dealId, source, eventId |
| Mbus destination (redemption type) | Redemption message (`RedemptionMbusPayload`) | Transaction finalization — paired with click message | uuid, attributionId, bcookie, country, transactionId, network, clickId, redeemedAt, source, commission (amount + currency + country), totalSale, clickPayloadId, dealId, eventId |

### Click Message Detail

- **Topic**: Mbus destination identified by `messageType` = `"click"` (lower-cased); destination configured in `messagebus` config block
- **Trigger**: `ProcessedTransactionFinalizer.sendMessages` after a core coupon transaction with a deal UUID and bcookie is persisted to MySQL
- **Payload**: JSON-serialized `ClickMbusPayload` containing a `JanusClick` record with: `uuid` (new UUID or existing `clickMessageUuid`), `country`, `clickId`, `attributionId`, `bcookie`, `dealId`, `source`, and optional `eventId`
- **Consumers**: Downstream Janus attribution service
- **Guarantees**: At-least-once (JMS; errors are logged but the transaction is already persisted)

### Redemption Message Detail

- **Topic**: Mbus destination identified by `messageType` = `"redemption"` (lower-cased); destination configured in `messagebus` config block
- **Trigger**: Immediately after click message is sent, within the same `sendMessages` call
- **Payload**: JSON-serialized `RedemptionMbusPayload` containing a `Redemption` record with: `uuid` (new random UUID), `attributionId`, `bcookie`, `country`, `transactionId`, `network`, `clickId`, `redeemedAt`, `source`, `commission` (as `Money` with `roundedAmount`, `currencyCode`, `countryCode`), `totalSale` (as `Money`), `clickPayloadId` (UUID of the paired click message), `dealId`, and optional `eventId`
- **Consumers**: Downstream Janus attribution and revenue reporting services
- **Guarantees**: At-least-once (JMS; both messages are sent in the same try block; a `MessageException` is caught and logged without re-throw)

## Consumed Events

> No evidence found in codebase. This service does not consume any async events from Mbus or any other messaging system. Ingestion is driven by scheduled Quartz jobs that poll the AffJet API directly.

## Dead Letter Queues

> No evidence found in codebase for explicit dead letter queue configuration. Error handling for failed message sends relies on structured logging (`ProcessedTransactionFinalizer.sendMessages.error` event) for alerting.
