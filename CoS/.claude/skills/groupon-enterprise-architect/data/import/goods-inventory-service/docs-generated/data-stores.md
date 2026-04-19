---
service: "goods-inventory-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumGoodsInventoryDb"
    type: "postgresql"
    purpose: "Primary relational store for inventory products, units, reservations, vendor tax, and message rules"
  - id: "continuumGoodsInventoryRedis"
    type: "redis"
    purpose: "Cache for inventory product views, pricing, and inventory-unit projections"
---

# Data Stores

## Overview

Goods Inventory Service uses a dual-store data strategy: PostgreSQL as the primary relational database for all transactional inventory data, and Redis (GCP Memorystore) as a caching layer for frequently-accessed product views, pricing information, and inventory projections. Additionally, the Cronus Publisher Worker writes snapshot rows to the PostgreSQL database for downstream asynchronous processing.

## Stores

### Goods Inventory DB (`continuumGoodsInventoryDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumGoodsInventoryDb` |
| Purpose | Primary relational store for inventory products, units, reservations, vendor tax, and operational data |
| Ownership | owned |
| Access | JDBI via `db.default` and `db.default_readonly` connection pools |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `inventory_products` | Stores inventory product definitions including deal associations, SKU, quantity, and status | product_id, deal_id, sku, status, available_quantity |
| `inventory_units` | Individual inventory unit records with full lifecycle state tracking | unit_id, product_id, status, reservation_id, order_id |
| `reservations` | Checkout reservations that temporarily hold inventory units | reservation_id, product_id, unit_ids, status, created_at, expires_at |
| `vendor_tax` | Vendor tax configuration and rate data | vendor_tax_id, vendor_id, tax_rate, region |
| `message_rules` | Localized message rules for consumer-facing inventory messaging | rule_id, locale, message_key, message_template |
| `shipping_options` | Shipping option configurations per product and region | option_id, product_id, carrier, delivery_window |
| `postal_codes` | Supported postal codes for shipping eligibility | postal_code, region, active |
| `product_locations` | Product-to-location mapping for geographic inventory routing | product_id, location_id, quantity |
| `cronus_snapshots` | Inventory unit snapshot rows written by CronusPublisherWorker for downstream processing | snapshot_id, unit_id, snapshot_data, created_at |

#### Access Patterns

- **Read**: High-frequency reads for availability checks (product + unit status queries), reservation lookups during checkout, and product detail queries. Read-heavy workload uses `db.default_readonly` connection pool for read replicas.
- **Write**: Transactional writes for reservation creation/confirmation/cancellation, inventory unit status transitions, product updates during IMS sync, and Cronus snapshot inserts.
- **Indexes**: Expected on product_id, unit_id, reservation_id, status, deal_id, and composite indexes on (product_id, status) for availability queries.

### Goods Inventory Redis Cache (`continuumGoodsInventoryRedis`)

| Property | Value |
|----------|-------|
| Type | Redis (GCP Memorystore) |
| Architecture ref | `continuumGoodsInventoryRedis` |
| Purpose | Cache layer for inventory product views, pricing data, and unit-level projections |
| Ownership | owned |

#### Key Entities

| Cache Key Pattern | Purpose | Key Fields |
|-------------------|---------|-----------|
| `inv-product:{productId}` | Cached inventory product view with availability snapshot | productId, availableQuantity, status, pricing |
| `pricing:{productId}` | Cached pricing data for inventory products | productId, price, currency, lastUpdated |
| `inv-projection:{productId}` | Inventory-unit level projection for fast availability checks | productId, projectedAvailable, reservedCount |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Inventory product views | Redis (GCP Memorystore) | Caches assembled product views to reduce DB read load on availability queries | Varies by product type; invalidated on write |
| Pricing cache | Redis (GCP Memorystore) | Caches current pricing data retrieved from Pricing Service | Short TTL; refreshed on pricing updates |
| Inventory projections | Redis (GCP Memorystore) | Caches unit-level projections for fast availability responses | Invalidated on reservation/order/cancellation events |

## Data Flows

- **IMS Sync to DB**: Product & Inventory Services synchronize inventory data from the upstream Inventory Management Service into `inventory_products` and `inventory_units` tables.
- **Reservation to Cache Invalidation**: When a reservation is created or cancelled, the Reservation & Order Services invalidate corresponding Redis cache entries so subsequent availability queries reflect current state.
- **Message Consumer to Cache**: Inventory Messaging Consumers process inbound status events and evict/refresh Redis cache entries to maintain cache coherence.
- **Cronus Snapshots**: CronusPublisherWorker writes inventory unit snapshot rows to PostgreSQL for asynchronous downstream processing by the Cronus system.
- **Read Replica Offload**: Read-only queries (availability, product lookups) are routed to the `db.default_readonly` connection pool targeting read replicas.
