---
service: "goods-inventory-service-routing"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumGoodsInventoryServiceRoutingDb"
    type: "postgresql"
    purpose: "Stores inventory product shipping regions for routing decisions"
---

# Data Stores

## Overview

The service owns a single PostgreSQL database that serves as a local shipping-region index. When an inventory product is successfully created or updated via GIS, this service persists (or updates) the product UUID-to-shipping-regions mapping. On subsequent GET or write requests, the routing service queries this store to determine which regional GIS endpoint owns the product — avoiding a remote GIS call solely for routing purposes.

## Stores

### Goods Inventory Service Routing DB (`continuumGoodsInventoryServiceRoutingDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumGoodsInventoryServiceRoutingDb` |
| Purpose | Stores the mapping from inventory product UUID to shipping region codes, used to resolve the correct regional GIS endpoint |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `inventory_product_shipping_regions` | Maps each inventory product UUID to its set of shipping region country codes | `inventory_product_uuid` (UUID, PK), `shipping_regions` (VARCHAR(6)[], NOT NULL), `created_at` (TIMESTAMP), `updated_at` (TIMESTAMP, auto-managed by trigger) |

#### Access Patterns

- **Read**: Fetch one or more rows by `inventory_product_uuid` using `WHERE inventory_product_uuid = ANY(:inventory_product_uuids)`. Called on every inbound GET, POST, and PUT to resolve the owning GIS region before forwarding the request.
- **Write**: Insert a new row when a product's shipping regions are first recorded (after a successful GIS upsert/update). Update an existing row when the shipping regions change. Both operations are wrapped in a JDBI transaction.
- **Indexes**: Primary key on `inventory_product_uuid` (implicit B-tree index). No additional indexes defined in the migration.

#### Connection configuration (per environment)

| Environment | Host | Database |
|-------------|------|----------|
| Development | `localhost` (port 15432 / 6432) | `test_dev` |
| Staging | `goods-inventory-service-routing-rw-na-staging-db.gds.stable.gcp.groupondev.com` | `gis_routing_stg` |
| Production | `goods-inventory-service-routing-rw-na-production-db.gds.prod.gcp.groupondev.com` | `goods_inv_serv_routing_prod` |

Connection credentials are supplied at runtime via the `DAAS_APP_USERNAME` and `DAAS_APP_PASSWORD` environment variables (DaaS-managed PostgreSQL).

## Caches

> No evidence found in codebase. No cache layer (Redis, Memcached, or in-memory) is used. The PostgreSQL store acts as the single source of truth for routing lookups.

## Data Flows

On every successful `POST /inventory/v1/products` or `PUT /inventory/v1/products/{uuid}` that receives an HTTP 200 or 201 from GIS, the routing service opens a JDBI transaction and either inserts or updates the `inventory_product_shipping_regions` rows for the affected products. No ETL, CDC, or replication pipelines are present. Data in this store is derived entirely from successful write responses from GIS.
