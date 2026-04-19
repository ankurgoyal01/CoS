---
service: "voucher-inventory-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["activemq", "jms"]
---

# Events

## Overview

The Voucher Inventory Service uses Apache ActiveMQ with JMS as its message bus (`continuumVoucherInventoryMessageBus`). The service both publishes and consumes domain events. Published events cover inventory product updates, unit status changes, and redemption lifecycle transitions. Consumed events include order status changes, shipping tracking updates, internal VIS propagation events, and GDPR right-to-forget requests. Background workers (`continuumVoucherInventoryWorkers`) handle all event consumption, while both the API and Workers containers publish events.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `voucher_inventory.inventory_product.updated` | Inventory Product Updated | Inventory product configuration changes via API | Product ID, attributes, pricing data, timestamps |
| `voucher_inventory.*` (domain events) | VIS Domain Events | Unit status changes, redemptions, code pool updates | Unit ID, status, product ID, order ID |

### Inventory Product Updated Detail

- **Topic**: `voucher_inventory.inventory_product.updated`
- **Trigger**: Changes to inventory product configuration via the Inventory Products API, including attribute updates, pricing integration sync, and deal catalog synchronization
- **Payload**: Inventory product ID, updated attributes, pricing information, timestamps
- **Consumers**: Deal Catalog, Lazlo, analytics pipelines, and other downstream services
- **Guarantees**: at-least-once
- **Publisher component**: `continuumVoucherInventoryApi_inventoryProductsMessageProducer`

### VIS Async Domain Events Detail

- **Topic**: Various `voucher_inventory.*` topics
- **Trigger**: Unit status transitions, redemption completions, and other lifecycle events processed asynchronously
- **Payload**: Event-specific payloads including unit IDs, product IDs, status transitions, order mappings
- **Consumers**: Internal VIS workers (for sold count updates, cache invalidation), external analytics
- **Guarantees**: at-least-once
- **Publisher component**: `continuumVoucherInventoryWorkers_asyncPublishers`

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `Orders.*.vis_inventory_units.status_changed` | Order Unit Status Changed | `continuumVoucherInventoryWorkers_ordersEventsListener` | Updates voucher unit status in Units DB, handles promise refunds, reconciles payments |
| `voucher_inventory.*` | VIS Internal Events | `continuumVoucherInventoryWorkers_voucherInventoryEventsListener` | Updates sold counts, caches quantity summaries in Redis, propagates unit changes |
| Shipping tracking topics | Goods Shipping Events | `continuumVoucherInventoryWorkers_goodsShippingListener` | Updates shipment tracking information for physical voucher units |
| GDPR right-to-forget topics | GDPR Right-To-Forget | `continuumVoucherInventoryWorkers_gdprListener` | Anonymizes PII in voucher and order data |

### Order Unit Status Changed Detail

- **Topic**: `Orders.*.vis_inventory_units.status_changed`
- **Handler**: Orders Events Listener (`continuumVoucherInventoryWorkers_ordersEventsListener`) -- Ruby workers such as `Orders::UnitsStatusUpdateListener` and `Orders::TradeinStatusListener`
- **Idempotency**: Expected via unit status state machine (same transition applied multiple times is safe)
- **Error handling**: Failed messages routed to DLQ, processed by `continuumVoucherInventoryWorkers_dlqProcessor`
- **Processing order**: unordered (individual unit updates are independent)

### VIS Internal Events Detail

- **Topic**: `voucher_inventory.*`
- **Handler**: Voucher Inventory Events Listener (`continuumVoucherInventoryWorkers_voucherInventoryEventsListener`) -- Ruby workers such as `VoucherInventory::SoldCountListener`, `VoucherInventory::BarcodeCountListener`
- **Idempotency**: Sold count recalculations are idempotent (recomputed from source data)
- **Error handling**: Failed messages routed to DLQ
- **Processing order**: unordered

### Goods Shipping Events Detail

- **Topic**: Shipping tracking event topics from Shipping Service
- **Handler**: Goods Shipping Listener (`continuumVoucherInventoryWorkers_goodsShippingListener`) -- Ruby worker `Goods::ShippingDetailsUpdateListener`
- **Idempotency**: Tracking updates are upserted by shipment ID
- **Error handling**: Failed messages routed to DLQ
- **Processing order**: unordered

### GDPR Right-To-Forget Detail

- **Topic**: GDPR right-to-forget event topics from GDPR Service
- **Handler**: GDPR & Right-To-Forget Listener (`continuumVoucherInventoryWorkers_gdprListener`) -- Ruby workers `RightToForgetListener`, `RightToForgetWorkerJob`
- **Idempotency**: Anonymization is idempotent (re-anonymizing already-anonymized data is a no-op)
- **Error handling**: Failed messages routed to DLQ with alerting
- **Processing order**: unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| VIS DLQ | All consumed topics | Configurable | DLQ Processor (`continuumVoucherInventoryWorkers_dlqProcessor`) reads and requeues messages with retry, archive, and manual review strategies |

> The Dead Letter Queue Processor component applies retry logic, archives unrecoverable messages, and flags messages requiring manual review.
