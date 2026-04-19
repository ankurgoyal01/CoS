---
service: "orders_mbus_client"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Orders Mbus Client is the primary MBus integration worker for the Orders platform. It both consumes and publishes events using the JTier MBus library over STOMP/JMS. Consumed events arrive on durable topic subscriptions and are processed synchronously by a dedicated per-topic processor. Outbound gift-order events are first persisted to MySQL and then published asynchronously by a Quartz job with exponential-backoff retry.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.Order.Gift` | Gift order notification | Pending message row found in MySQL by `MessagePublishingJob` | Message content stored at insert time by Orders Core Service |

### Gift Order Notification Detail

- **Topic**: `jms.topic.Order.Gift`
- **Trigger**: Quartz `MessagePublishingJob` runs every second (`0/1 * * * * ?`) and fetches pending rows from the `messages` table.
- **Payload**: JSON string stored in `messages.content` column — content is inserted externally by Orders Core Service; the OMC service publishes it as-is.
- **Consumers**: Known consumers registered on the MBus topic (not tracked in this repo).
- **Guarantees**: At-least-once — failed publishes are retried with exponential backoff; if `retryCount >= maxRetryCount`, status becomes `abandoned`.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.payments.PaymentUpdate` | `Payment.Updated` / `Businessevent.Billing.Updated` | `PaymentUpdateTopicProcessor` | HTTP POST to Orders `/v2/payment_events/store` |
| `jms.topic.gdpr.account.v1.erased` | Account erased | `AccountEraseTopicProcessor` | HTTP POST to Orders `/v2/account_redaction` |
| `jms.queue.UserRewardToBucksMirrorQueue` | Bucks mirror sync | `BucksMirrorTopicProcessor` | HTTP POST to Orders `/mirrors/bucks/sync` |
| `jms.topic.merchantPayments.inventoryProduct.promotionalAdjustmentsEnabled` | VFM promotional adjustments enabled | `VFMPromotionalAdjustmentsEnabledProcessor` | HTTP PUT to Orders `/v2/merchant_payments/inventory_product_attributes` |
| `jms.topic.BillingRecords.PaypalBillingAgreementEvents` | PayPal billing agreement deletion | `PaypalBillingAgreementDeletionProcessor` | HTTP DELETE to Orders `/tps/v1/paypal_billing_records` |
| `jms.topic.bemod.account.v1.suspiciousBehaviorDetected` | Suspicious behaviour detected | `BeModTopicProcessor` | HTTP PUT to Orders `/tps/v1/users/{consumer_id}/billing_records/deactivate_user` |
| `jms.topic.grouponTestTopic1` | Test message | `TestTopicProcessor` | No-op (enabled only when `testTopicListenerEnabled: true`) |

### Payment Update Detail

- **Topic**: `jms.topic.payments.PaymentUpdate`
- **Handler**: `PaymentUpdateTopicProcessor` — dispatches on `messageType`: `Payment.Updated` (payment event filter) or `Businessevent.Billing.Updated` (billing state filter).
- **Acceptable payment events**: `AUTHORISATION_PROCESSED`, `AUTHORISATION_FAILED`, `AUTHORISATION_ERROR`, `AUTHORISATION_EXPIRED`, `CAPTURE_RECEIVED`, `CAPTURE_PROCESSED`, `CAPTURE_FAILED`, `REFUND_RECEIVED`, `REFUND_PROCESSED`, `REFUND_NOTFOUND`, `REFUND_FAILED`, `CANCEL_RECEIVED`, `CANCEL_FAILED`, `CHARGEBACK_RECEIVED`, `CHARGEBACK_FAILED`.
- **Acceptable billing states**: `2`, `3`, `4`, `5`, `7`, `8`, `9`, `10`, `13`, `15`, `16`, `17`.
- **Idempotency**: Message IDs are normalised to UUID format before forwarding; the Orders service is responsible for idempotency on its side.
- **Error handling**: Exceptions propagate to the base processor; no DLQ is configured at the MBus consumer level.
- **Processing order**: Unordered (each message processed independently).

### Account Erase Detail

- **Topic**: `jms.topic.gdpr.account.v1.erased`
- **Handler**: `AccountEraseTopicProcessor` — extracts `accountId`, `erasedAt`, `publishedAt` from the message and calls Orders `/v2/account_redaction`.
- **Idempotency**: Delegated to the Orders service.
- **Error handling**: `IOException` and `RuntimeException` surface to the base processor.
- **Processing order**: Unordered.

### Bucks Mirror Sync Detail

- **Topic**: `jms.queue.UserRewardToBucksMirrorQueue`
- **Handler**: `BucksMirrorTopicProcessor` — remaps reward and provision-transaction fields using field-name maps and converts epoch timestamps to `yyyy-MM-dd'T'hh:mm:ss.SSS'Z'` format.
- **Idempotency**: Delegated to the Orders service.
- **Error handling**: `ParseException`, `RuntimeException`, `IOException` surface to the base processor.
- **Processing order**: Unordered.

### VFM Promotional Adjustments Detail

- **Topic**: `jms.topic.merchantPayments.inventoryProduct.promotionalAdjustmentsEnabled`
- **Handler**: `VFMPromotionalAdjustmentsEnabledProcessor` — extracts `inventoryProductId` and `enabledAt`, calls Orders `/v2/merchant_payments/inventory_product_attributes` with `attribute_type: promotional_adjustment`.
- **Idempotency**: Delegated to the Orders service.
- **Processing order**: Unordered.

### PayPal Billing Agreement Deletion Detail

- **Topic**: `jms.topic.BillingRecords.PaypalBillingAgreementEvents`
- **Handler**: `PaypalBillingAgreementDeletionProcessor` — calls Orders `/tps/v1/paypal_billing_records` with the tokenized PAN.
- **Idempotency**: Delegated to the Orders service.
- **Processing order**: Unordered.

### Suspicious Behaviour (BeMod) Detail

- **Topic**: `jms.topic.bemod.account.v1.suspiciousBehaviorDetected`
- **Handler**: `BeModTopicProcessor` — extracts `accountId` (UUID), `detectedAt`, `publishedAt` and calls Orders `/tps/v1/users/{consumer_id}/billing_records/deactivate_user` via HTTP PUT.
- **Processing order**: Unordered.

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration is present in any of the MBus destination configs. Failed consumer-side messages are not automatically re-queued; retries are limited to the publish path.
