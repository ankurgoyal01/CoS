---
service: "voucher-inventory-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for Voucher Inventory Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Inventory Reservation](inventory-reservation.md) | synchronous | API call from checkout | Reserve inventory during checkout with pricing and policy validation |
| [Voucher Redemption](voucher-redemption.md) | synchronous | API call from consumer/merchant | Redeem a voucher unit at a merchant location |
| [Order Status Sync](order-status-sync.md) | event-driven | Order status change event | Update voucher unit status based on order lifecycle events |
| [Inventory Product Update](inventory-product-update.md) | synchronous | API call from deal management | Update inventory product configuration and publish change events |
| [Reconciliation](reconciliation.md) | batch | Scheduled / manual | Reconcile unit status against Orders service to correct drift |
| [GDPR Right-To-Forget](gdpr-right-to-forget.md) | event-driven | GDPR event from GDPR Service | Anonymize PII in voucher and order data |
| [EDW Daily Export](edw-daily-export.md) | batch | Scheduled (daily) | Build and upload analytical snapshots to the Enterprise Data Warehouse |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Checkout Reservation Flow**: Spans Orders Service -> Voucher Inventory Service (reservation) -> Pricing Service (validation). Referenced in central architecture dynamic views.
- **Order Lifecycle Sync**: Spans Orders Service -> Message Bus -> VIS Workers (unit status updates). Events originate from Orders and are consumed by VIS.
- **GDPR Anonymization**: Spans GDPR Service -> Message Bus -> VIS Workers (PII anonymization across VIS databases).
- **Physical Goods Fulfillment**: Spans Goods Central / Shipping Service -> Message Bus -> VIS Workers (tracking updates for physical voucher units).
