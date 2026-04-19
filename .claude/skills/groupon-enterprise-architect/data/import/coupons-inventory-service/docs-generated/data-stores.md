---
service: "coupons-inventory-service"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumCouponsInventoryDb"
    type: "postgresql"
    purpose: "Primary relational store for inventory products, units, reservations, clicks, localized content, and client records"
  - id: "continuumCouponsInventoryRedis"
    type: "redis"
    purpose: "Cache for inventory products and precomputed deal-id lists"
---

# Data Stores

## Overview

Coupons Inventory Service uses a two-tier data storage strategy: a Postgres database as the primary relational store for all inventory domain entities, and a Redis cache for frequently accessed product data and precomputed deal-id lists. Additionally, an in-memory ConcurrentHashMap cache is used for client configuration records to avoid repeated database lookups during authentication. Schema management is handled via Flyway migrations.

## Stores

### Coupons Inventory DB (`continuumCouponsInventoryDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumCouponsInventoryDb` |
| Purpose | Primary relational store for products, units, reservations, clicks, localized content, clients, and related inventory state |
| Ownership | owned |
| Migrations path | Managed via Flyway (path inferred from JTIER conventions) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `products` | Inventory products representing coupon inventory items | product_id, deal_id, created_date, status |
| `units` | Coupon units associated with inventory products | unit_id, product_id, status |
| `reservations` | Reservations placed against inventory | reservation_id, product_id, status |
| `clicks` | Click events recorded for offers | click_id, offer_id, timestamp |
| `localized_content` | Localized content records associated with products | content_id, product_id, locale, content |
| `clients` | Client records used for authentication and authorization | client_id, client_name, permissions |

#### Access Patterns

- **Read**: Products queried by ID, by deal-id (with Redis caching), and by created date. Units queried by product association with existence checks. Reservations queried by ID and product. Clicks queried by offer. Client records loaded for auth and cached in memory.
- **Write**: Products created and updated with localized content. Units created for products. Reservations created. Click events persisted. Product records updated with deal-ids by the Inventory Product Creation Processor.
- **Indexes**: Expected indexes on product_id, deal_id, unit_id, reservation_id, client_id, and click event timestamp fields (exact index definitions in Flyway migrations).

### Coupons Inventory Cache (`continuumCouponsInventoryRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumCouponsInventoryRedis` |
| Purpose | Redis cache for inventory products and precomputed deal-id lists to reduce database and downstream load |
| Ownership | owned |

#### Key Entities

| Entity / Key Pattern | Purpose | Key Fields |
|---------------------|---------|-----------|
| Product lists by ID | Cached product data to avoid repeated database queries | product_id, product data |
| Deal-id lists by created date | Precomputed deal-id lists cached after resolution from Deal Catalog | created_date, deal_id list |

#### Access Patterns

- **Read**: Product Repository reads cached product lists by ID. Product Domain retrieves cached deal-id lists.
- **Write**: Product Repository caches product lists by ID. Inventory Product Creation Processor caches deal-id lists by created date after resolving from Deal Catalog.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumCouponsInventoryRedis` | Redis | Product data and deal-id list caching | Not specified in architecture DSL |
| `continuumCouponsInventoryService_clientCache` | In-memory (ConcurrentHashMap) | Client configuration and authorization data | Not specified; in-memory for process lifetime |

## Data Flows

1. **Product creation**: Product API receives request -> Product Domain validates and persists to Postgres via Product Repository -> localized content saved via Localized Content Repository -> product creation event published to Message Bus -> Inventory Product Creation Processor consumes event, resolves deal-ids from Deal Catalog, updates product in Postgres, and caches deal-ids in Redis.

2. **Product query by deal-id**: Product API receives request -> Product Domain checks Redis cache for deal-id list -> on cache miss, queries Postgres and populates Redis cache -> returns product data.

3. **Reservation creation**: Reservation API receives request -> Reservation Domain validates via Validation component, loads product from Product Repository, optionally fetches redemption codes from VoucherCloud Client, and persists reservation to Postgres.

4. **Client authentication**: Request arrives -> Auth filter loads client record from Client Repository -> Client Repository checks in-memory Client Cache -> on cache miss, queries Postgres via Jdbi -> caches result and authorizes request.
