---
service: "killbill-subscription-programs-plugin"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus, killbill-internal-event-bus]
---

# Events

## Overview

The plugin participates in two async event streams. It consumes in-process Kill Bill billing lifecycle events (delivered by Kill Bill's internal OSGI event dispatcher) and external Groupon MBus JMS/STOMP events from the Orders system. The plugin does not publish events to any external topic; its outputs are synchronous HTTP calls to GAPI and Orders, and writes to the Kill Bill invoice custom fields.

## Published Events

> No evidence found in codebase. The plugin does not publish events to any external topic or queue. Order creation and invoice state updates are communicated via synchronous HTTP calls and Kill Bill custom field writes.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Kill Bill internal event bus (in-process) | `INVOICE_CREATION` | `SPListener.handleKillbillEvent()` | Triggers order creation via GAPI; writes `ORDER_ID` or `ORDER_FAILED` custom field on the invoice |
| `jms.topic.Orders.TransactionalLedgerEvents` | `TransactionalLedgerEvent` | `MBusListener` | Identifies affected invoices; schedules retry reconciliation via `MBusRetries`; calls Orders service to update invoice payment status |

### `INVOICE_CREATION` Detail

- **Topic**: Kill Bill internal OSGI event dispatcher (in-process, not a named queue)
- **Handler**: `SPListener.handleKillbillEvent()` dispatches on `INVOICE_CREATION` event type; calls `createOrderForInvoice(invoiceId, context)`
- **Idempotency**: The handler skips invoices with a `$0` balance and accounts without the `MANUAL_PAY` tag. Order creation uses a per-account `GlobalLock` to prevent concurrent processing.
- **Error handling**: On failure, wraps the exception in `NotificationPluginApiRetryException` to signal Kill Bill to schedule a retry (requires non-null `accountId` for retry scheduling against `sp_notifications`)
- **Processing order**: Ordered per-account via `GlobalLock`

### `TransactionalLedgerEvent` Detail

- **Topic**: `jms.topic.Orders.TransactionalLedgerEvents`
- **Subscription ID**: `jms.topic.Orders.TransactionalLedgerEvents_killbill-sp-plugin.killbill-sp-plugin`
- **Handler**: `MBusListener` (one or more threads per tenant, configured via `com.groupon.volume2.sp.plugin.mbus.nbThreadsPerTenant`); dispatches to a pool of `mbusWorkers` per tenant
- **Idempotency**: The listener identifies relevant invoices by matching ledger event fields; reconciliation calls to the Orders service are idempotent
- **Error handling**: Retries scheduled via `MBusRetries` using the Kill Bill notification queue (`sp_notifications` table)
- **Processing order**: Unordered (parallel per-tenant worker pool)

## Dead Letter Queues

> No evidence found in codebase for explicit DLQ configuration. Failed MBus event processing is handled via the Kill Bill notification queue retry mechanism (`sp_notifications` / `sp_notifications_history` tables).
