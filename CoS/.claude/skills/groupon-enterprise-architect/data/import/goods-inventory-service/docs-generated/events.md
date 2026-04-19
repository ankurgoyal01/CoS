---
service: "goods-inventory-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["mbus"]
---

# Events

## Overview

Goods Inventory Service uses Groupon MessageBus for asynchronous event-driven communication. The service both publishes inventory lifecycle events for downstream consumers and consumes order status and account merge events to maintain inventory unit state and cache coherence. All messaging flows through the `continuumGoodsInventoryMessageBus` container.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `inventory-products-created` | InventoryProductCreated | New inventory product created in GIS | productId, dealId, sku, quantity, status |
| `inventory-products-updated` | InventoryProductUpdated | Inventory product modified (quantity, status, pricing) | productId, dealId, changedFields, previousValues |
| `inventory-units-events` | InventoryUnitStatusChanged | Inventory unit transitions state (reserved, confirmed, shipped, cancelled) | unitId, productId, previousStatus, newStatus, orderId, reservationId |
| `inventory-units-events` | InventoryUnitCancelled | Inventory unit cancelled via reverse fulfillment | unitId, productId, orderId, cancellationReason |

### InventoryProductCreated Detail

- **Topic**: `inventory-products-created`
- **Trigger**: A new inventory product is created in the system, typically during IMS sync or manual product setup
- **Payload**: Product ID, deal ID, SKU, initial quantity, status, pricing snapshot
- **Consumers**: Downstream analytics, deal catalog sync, inventory dashboards
- **Guarantees**: at-least-once

### InventoryProductUpdated Detail

- **Topic**: `inventory-products-updated`
- **Trigger**: An existing inventory product is modified -- quantity adjustments, status changes, pricing updates
- **Payload**: Product ID, changed field names, previous and current values
- **Consumers**: Downstream analytics, deal catalog sync, pricing services
- **Guarantees**: at-least-once

### InventoryUnitStatusChanged Detail

- **Topic**: `inventory-units-events`
- **Trigger**: An inventory unit transitions between lifecycle states (e.g., available to reserved, reserved to confirmed, confirmed to shipped)
- **Payload**: Unit ID, product ID, reservation ID, order ID, previous and new status
- **Consumers**: Order tracking, fulfillment services, Cronus snapshot processing
- **Guarantees**: at-least-once

### InventoryUnitCancelled Detail

- **Topic**: `inventory-units-events`
- **Trigger**: Reverse fulfillment cancels an exported inventory unit, coordinating with SRS and Goods Stores
- **Payload**: Unit ID, product ID, order ID, cancellation reason, add-back flag
- **Consumers**: Fulfillment tracking, goods stores (add-back logic), analytics
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `inventory-units-status` | InventoryUnitStatusUpdate | InventoryUnitsStatusMessageConsumer | Updates inventory unit status in DB, evicts and refreshes Redis cache |
| `user-account-merged` | UserAccountMerged | UserAccountMergedMessageConsumer | Merges inventory unit ownership when user accounts are consolidated |

### InventoryUnitStatusUpdate Detail

- **Topic**: `inventory-units-status`
- **Handler**: InventoryUnitsStatusMessageConsumer processes inbound status updates from order and payment systems, updating the corresponding inventory unit records and invalidating cached projections
- **Idempotency**: Yes -- status transitions are checked before applying; duplicate messages for the same transition are no-ops
- **Error handling**: Failed messages are retried with backoff; persistent failures are logged for manual investigation
- **Processing order**: unordered (idempotent status checks allow out-of-order processing)

### UserAccountMerged Detail

- **Topic**: `user-account-merged`
- **Handler**: UserAccountMergedMessageConsumer re-associates inventory units and reservations from the source account to the target account after an account merge operation
- **Idempotency**: Yes -- merge operations check current ownership before updating
- **Error handling**: Failed merges are logged with full context for manual remediation
- **Processing order**: unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| `inventory-units-status-dlq` | `inventory-units-status` | 7 days | Warning alert on DLQ depth > 0 |
| `user-account-merged-dlq` | `user-account-merged` | 7 days | Warning alert on DLQ depth > 0 |
