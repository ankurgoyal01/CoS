---
service: "goods-inventory-service-routing"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumGoodsInventoryServiceRouting", "continuumGoodsInventoryServiceRoutingDb"]
---

# Architecture Context

## System Context

Goods Inventory Service Routing sits within the **Continuum Platform** (`continuumSystem`). It acts as a smart routing proxy between internal Groupon services that manage inventory products and the multi-regional `continuumGoodsInventoryService`. Because GIS is deployed per geographic region (NA, EMEA), callers do not need to know which regional instance owns a given product — GISR resolves that mapping and forwards the request transparently. The service owns one PostgreSQL database that stores the product-to-shipping-region index used to make routing decisions.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Goods Inventory Service Routing | `continuumGoodsInventoryServiceRouting` | Service | Java, Dropwizard (JTier) | 2.x | Routes inventory product requests to regional GIS endpoints and stores shipping regions |
| Goods Inventory Service Routing DB | `continuumGoodsInventoryServiceRoutingDb` | Database | PostgreSQL | — | Stores inventory product shipping regions used for routing lookups |

## Components by Container

### Goods Inventory Service Routing (`continuumGoodsInventoryServiceRouting`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `routingResource` — Routing API Resource | JAX-RS resource that exposes `GET`, `POST`, and `PUT /inventory/v1/products` endpoints; validates input and delegates to routing service and GIS client | Dropwizard/Jersey |
| `routingService` — Routing Service | Determines the correct GIS region for a set of inventory product UUIDs or shipping regions; validates mixed-region constraints; persists updated shipping-region mappings after successful GIS writes | Java |
| `gisClient` — GIS Client | Constructs and executes outbound HTTP requests to the resolved regional GIS endpoint; injects `X-HB-Region` header; propagates response status and body back to the caller | OkHttp (jtier-okhttp) |
| `inventoryProductShippingRegionsDao` — Inventory Product Shipping Regions DAO | JDBI 3 SQL object interface for reading, inserting, and updating rows in `inventory_product_shipping_regions` | JDBI 3 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGoodsInventoryServiceRouting` | `continuumGoodsInventoryServiceRoutingDb` | Reads/writes shipping regions | JDBC (PostgreSQL) |
| `continuumGoodsInventoryServiceRouting` | `continuumGoodsInventoryService` | Routes inventory product requests to the resolved regional endpoint | HTTP |
| `routingResource` | `routingService` | Validates input and determines GIS region | Direct (in-process) |
| `routingResource` | `gisClient` | Routes inventory product requests | Direct (in-process) |
| `routingService` | `inventoryProductShippingRegionsDao` | Reads/writes shipping regions | Direct (in-process) |

## Architecture Diagram References

- System context: `contexts-continuumGoodsInventoryServiceRouting`
- Container: `containers-continuumGoodsInventoryServiceRouting`
- Component: `components-continuumGoodsInventoryServiceRouting`
