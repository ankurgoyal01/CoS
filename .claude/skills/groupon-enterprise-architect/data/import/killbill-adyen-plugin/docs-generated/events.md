---
service: "killbill-adyen-plugin"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kill-bill-notification-queue, adyen-soap-webhook]
---

# Events

## Overview

The plugin does not publish or consume events via a message broker such as Kafka or RabbitMQ. Async communication occurs in two forms: (1) Adyen pushes SOAP notification webhooks to the plugin's `/1.0/kb/paymentGateways/notification/killbill-adyen` endpoint; (2) the plugin internally uses Kill Bill's `NotificationQueueService` (backed by a database-persisted queue) to schedule delayed follow-up actions for 3D Secure v2 challenge flows.

## Published Events

> No evidence found of events published to an external message broker. The plugin notifies Kill Bill of state changes by calling Kill Bill's internal `PaymentApi` directly via OSGi service.

## Consumed Events

### Adyen SOAP Notification Webhook

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Adyen SOAP POST to `/1.0/kb/paymentGateways/notification/killbill-adyen` | `AUTHORISATION` | `KillbillAdyenNotificationHandler` | Transitions Kill Bill payment from PENDING to SUCCESS or FAILURE |
| Adyen SOAP POST to `/1.0/kb/paymentGateways/notification/killbill-adyen` | `CAPTURE` | `KillbillAdyenNotificationHandler` | Records capture result; updates Kill Bill payment state |
| Adyen SOAP POST to `/1.0/kb/paymentGateways/notification/killbill-adyen` | `REFUND` | `KillbillAdyenNotificationHandler` | Records refund result; updates Kill Bill payment state |
| Adyen SOAP POST to `/1.0/kb/paymentGateways/notification/killbill-adyen` | `CANCELLATION` | `KillbillAdyenNotificationHandler` | Records void result; updates Kill Bill payment state |
| Adyen SOAP POST to `/1.0/kb/paymentGateways/notification/killbill-adyen` | `CHARGEBACK` | `KillbillAdyenNotificationHandler` | Persists chargeback notification; optionally marks as failure |
| Adyen SOAP POST to `/1.0/kb/paymentGateways/notification/killbill-adyen` | `REPORT_AVAILABLE` | `KillbillAdyenNotificationHandler` | Persists notification record |

### Adyen Notification Detail

- **Protocol**: SOAP over HTTPS, namespace `http://notification.services.adyen.com`
- **Handler**: `AdyenNotificationService` parses SOAP envelope; dispatches items to registered `AdyenNotificationHandler` implementations; `KillbillAdyenNotificationHandler` performs Kill Bill state reconciliation
- **Idempotency**: Notifications may be retried by Adyen. The plugin persists each notification in `adyen_notifications` (not unique-constrained on `psp_reference`) to allow retries
- **Error handling**: Parse failures return `"error"` response; handler exceptions are logged with `eventCode`, `pspReference`, `merchantReference`, duration, and error flag. Adyen expects `[accepted]` on success.
- **Processing order**: Unordered per-notification item; Adyen may deliver items in any sequence

## Internal Delayed Action Queue

### 3DSv2 Delayed Follow-up

| Queue | Action Type | Trigger | Side Effects |
|-------|------------|---------|-------------|
| Kill Bill `NotificationQueueService` (table-backed) | `CheckForChallengeShopperCompleted` | Scheduled after a 3DSv2 challenge is initiated | Polls for challenge completion; invokes `paymentApiAdapter` to finalise transaction |
| Kill Bill `NotificationQueueService` (table-backed) | `CheckForIdentifyShopperCompleted` | Scheduled after a 3DSv2 identify-shopper step | Polls for identify-shopper completion; invokes `paymentApiAdapter` |

- **Queue name**: `adyen` (instance name used in `NotificationQueueConfig`)
- **Backend**: Database table (same dataSource as plugin DB)
- **Failure handling**: Retried by `DelayedActionScheduler` via Kill Bill notification queue retry semantics

## Dead Letter Queues

> No evidence found of a dedicated dead-letter queue. Failed Adyen notification processing is logged; failed 3DSv2 delayed actions rely on Kill Bill notification queue retry policy.
