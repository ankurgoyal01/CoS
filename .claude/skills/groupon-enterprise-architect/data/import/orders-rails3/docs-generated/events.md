---
service: "orders-rails3"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

orders-rails3 uses the Groupon Message Bus (via the `messagebus` 0.2.2 gem) for asynchronous event publishing. The Orders Service publishes five distinct event types covering the full order, payment, and inventory lifecycle. The service also consumes events from the Deal Catalog and Voucher Inventory domains to synchronize deal state and voucher availability. Published events flow through `continuumOrdersApi_messageBusPublishers`, which persists messages to `continuumOrdersMsgDb` before dispatching to the Message Bus.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `OrderSnapshots` | Order Snapshot | Order state change (creation, completion, cancellation) | order_id, status, line_items, totals, timestamps |
| `Transactions` | Transaction Record | Payment collection or refund processed | transaction_id, order_id, amount, currency, gateway, status |
| `InventoryUnits.StatusChanged` | Inventory Unit Status Change | Inventory unit reserved, redeemed, or voided | unit_id, order_id, status, deal_id, timestamps |
| `TransactionalLedgerEvents` | Ledger Event | Financial event requiring accounting record | ledger_entry_id, order_id, amount, event_type, timestamps |
| `BillingRecordUpdate` | Billing Record Update | Billing record created, updated, or deactivated | billing_record_id, order_id, payment_method, status |

### OrderSnapshots Detail

- **Topic**: `OrderSnapshots`
- **Trigger**: Order state transitions — creation via `POST /orders/v1/orders`, order completion by `continuumOrdersWorkers_paymentProcessingWorkers`, and cancellation via refund/cancellation workers
- **Payload**: order_id, status, line_items array, financial totals, created_at, updated_at
- **Consumers**: Analytics, Notification services, downstream fulfillment systems
- **Guarantees**: at-least-once

### Transactions Detail

- **Topic**: `Transactions`
- **Trigger**: Successful payment capture or refund processed by `continuumOrdersWorkers_paymentProcessingWorkers`
- **Payload**: transaction_id, order_id, amount, currency, gateway_name, gateway_response_code, status
- **Consumers**: Finance/accounting reconciliation, Analytics Warehouse
- **Guarantees**: at-least-once

### InventoryUnits.StatusChanged Detail

- **Topic**: `InventoryUnits.StatusChanged`
- **Trigger**: Inventory unit status changes processed by `continuumOrdersWorkers_inventoryWorkers`
- **Payload**: unit_id, order_id, deal_id, previous_status, new_status, changed_at
- **Consumers**: Voucher Inventory Service, reporting systems
- **Guarantees**: at-least-once

### TransactionalLedgerEvents Detail

- **Topic**: `TransactionalLedgerEvents`
- **Trigger**: Any financial event (payment capture, refund, chargeback resolution) requiring a ledger entry; persisted via `continuumOrdersMsgDb`
- **Payload**: ledger_entry_id, order_id, event_type, amount, currency, created_at
- **Consumers**: Finance ledger systems (SOX-relevant)
- **Guarantees**: at-least-once

### BillingRecordUpdate Detail

- **Topic**: `BillingRecordUpdate`
- **Trigger**: Billing record lifecycle events — creation at order placement, deactivation by `continuumOrdersWorkers_cancellationWorkers` or `continuumOrdersWorkers_accountRedactionWorkers`
- **Payload**: billing_record_id, order_id, payment_method_type, status, updated_at
- **Consumers**: Payments Service, PCI compliance systems
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `DealCatalog.Deal.Events` | Deal state change | `continuumOrdersApi_serviceClientsGateway` / internal handlers | Refreshes deal data used in order validation |
| `Inventory.Voucher` | Voucher availability update | `continuumOrdersWorkers_inventoryWorkers` | Adjusts local inventory unit state |

### DealCatalog.Deal.Events Detail

- **Topic**: `DealCatalog.Deal.Events`
- **Handler**: Internal consumer within `continuumOrdersService` that refreshes cached deal data sourced from `continuumDealCatalogService`
- **Idempotency**: Yes — deal data updates are overwrite-safe
- **Error handling**: Retry via `continuumOrdersDaemons_retrySchedulers`
- **Processing order**: unordered

### Inventory.Voucher Detail

- **Topic**: `Inventory.Voucher`
- **Handler**: `continuumOrdersWorkers_inventoryWorkers` processes voucher state updates and reconciles local inventory unit records in `continuumOrdersDb`
- **Idempotency**: Yes — status updates are idempotent by unit_id
- **Error handling**: Retry via `continuumOrdersDaemons_retrySchedulers` and `continuumOrdersWorkers_inventoryWorkers` guard/retry workers
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found of explicitly named DLQs in the architecture model. Failed messages are retried via Resque retry workers and daemon retry schedulers. See [Flows — Daemon Retry and Maintenance](flows/daemon-retry-maintenance.md) for retry details.
