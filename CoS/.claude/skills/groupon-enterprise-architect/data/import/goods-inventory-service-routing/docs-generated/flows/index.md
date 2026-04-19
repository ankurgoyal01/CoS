---
service: "goods-inventory-service-routing"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Goods Inventory Service Routing.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Get Inventory Products (Read Routing)](get-inventory-products.md) | synchronous | HTTP GET from upstream caller | Resolves regional GIS for requested product UUIDs and proxies the read request |
| [Upsert Inventory Products (Write Routing)](upsert-inventory-products.md) | synchronous | HTTP POST from upstream caller | Routes a create/upsert request to the correct regional GIS and persists shipping-region mapping on success |
| [Update Inventory Product (Update Routing)](update-inventory-product.md) | synchronous | HTTP PUT from upstream caller | Routes an update request for a single product UUID to the correct regional GIS and updates shipping-region mapping on success |
| [Shipping Region Persistence](shipping-region-persistence.md) | synchronous | Triggered internally after successful GIS write (POST or PUT) | Inserts or updates the inventory-product-to-shipping-region mapping in PostgreSQL |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in this service are cross-service by nature — each flow terminates at the regional `continuumGoodsInventoryService`. The routing service acts as an intelligent proxy layer. There are no dynamic views defined yet in the Structurizr DSL (`architecture/views/dynamics.dsl` is empty).

- See [Get Inventory Products](get-inventory-products.md) — spans `continuumGoodsInventoryServiceRouting` and `continuumGoodsInventoryService`
- See [Upsert Inventory Products](upsert-inventory-products.md) — spans `continuumGoodsInventoryServiceRouting`, `continuumGoodsInventoryService`, and `continuumGoodsInventoryServiceRoutingDb`
- See [Update Inventory Product](update-inventory-product.md) — spans `continuumGoodsInventoryServiceRouting`, `continuumGoodsInventoryService`, and `continuumGoodsInventoryServiceRoutingDb`
- See [Shipping Region Persistence](shipping-region-persistence.md) — internal to `continuumGoodsInventoryServiceRouting`, writes to `continuumGoodsInventoryServiceRoutingDb`
