---
service: "goods-inventory-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Goods Inventory Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Product Availability Check](product-availability-check.md) | synchronous | API request | Real-time product availability query combining DB state, Redis cache, and pricing enrichment |
| [Reservation Creation](reservation-creation.md) | synchronous | API request | Creates a checkout reservation that temporarily holds inventory units for a buyer |
| [Order Fulfillment](order-fulfillment.md) | synchronous | API request | Confirms a reservation into a committed order and coordinates fulfillment with ORC |
| [Reverse Fulfillment](reverse-fulfillment.md) | synchronous | API request | Cancels exported inventory units, coordinates with SRS and Goods Stores, publishes cancellation events |
| [Inventory Sync with IMS](inventory-sync-ims.md) | scheduled | Cron schedule | Synchronizes inventory products and units from upstream Inventory Management Service |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- **Checkout pipeline**: The reservation creation and order fulfillment flows are part of the broader universal checkout pipeline that spans consumer-facing APIs, GIS, ORC, SRS, and payment services.
- **Reverse fulfillment pipeline**: The reverse fulfillment flow spans GIS, SRS Outbound Controller, and Goods Stores Service to coordinate unit cancellation and inventory add-back.
- **Inventory sync pipeline**: The IMS sync flow connects the upstream Goods Inventory Management Service with GIS to maintain consistent inventory state.
