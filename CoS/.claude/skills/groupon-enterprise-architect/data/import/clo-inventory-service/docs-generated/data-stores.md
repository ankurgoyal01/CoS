---
service: "clo-inventory-service"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumCloInventoryDb"
    type: "postgresql"
    purpose: "Primary relational store for inventory, consent, and related data"
  - id: "continuumCloInventoryRedisCache"
    type: "redis"
    purpose: "Caching layer for product and inventory data"
---

# Data Stores

## Overview

CLO Inventory Service uses a two-tier data storage strategy: PostgreSQL as the authoritative relational data store for all inventory, consent, merchant, unit, reservation, and user data, and Redis as a caching layer to improve read performance for frequently accessed product data. An additional in-memory cache layer (MemoryProductDao, MemoryCacheConfig) sits in front of Redis to provide the fastest possible reads for hot product data within each service instance.

## Stores

### CLO Inventory Database (`continuumCloInventoryDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumCloInventoryDb` |
| Purpose | PostgreSQL schema used by CLO Inventory Service and clo-consent module for inventory, consent, and related data |
| Ownership | owned |
| Migrations path | Managed via JTIER DaaS Postgres conventions |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `clo_products` | CLO inventory products with pricing and contract terms | product_id, deal_id, merchant_id, status, pricing fields |
| `clo_units` | Inventory units allocated against products | unit_id, product_id, status, allocation fields |
| `clo_unit_redemptions` | Redemption records for inventory units | redemption_id, unit_id, user_id, redeemed_at |
| `clo_reservations` | Reservations against inventory units for purchase control | reservation_id, unit_id, user_id, status, expires_at |
| `clo_users` | User reward and CLO inventory interaction records | user_id, reward fields, interaction state |
| `clo_merchants` | Merchant CLO feature configuration and inventory settings | merchant_id, feature flags, configuration |
| `consent_records` | User consent records for card-linked offers | consent_id, user_id, consent_status, granted_at |
| `consent_history` | Audit trail of consent changes | history_id, consent_id, action, changed_at |
| `billing_records` | Billing records associated with consent and card enrollments | billing_id, user_id, card details, status |
| `card_enrollments` | Card enrollment state for CLO | enrollment_id, user_id, card_id, network, status |

#### Access Patterns

- **Read**: Product lookups by ID and by deal/merchant filters (high frequency, cache-backed); user reward queries; merchant feature queries; consent record lookups by user; reservation and unit status queries
- **Write**: Product creation and updates (via CreateOrUpdateProductAggregator); unit creation and redemption recording; reservation creation and expiration; consent record creation, update, and revocation; card enrollment state changes
- **Indexes**: Expected indexes on product_id, deal_id, merchant_id, user_id, unit_id, consent user lookups, and reservation expiration timestamps

### CLO Inventory Redis Cache (`continuumCloInventoryRedisCache`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumCloInventoryRedisCache` |
| Purpose | Redis cache used for product data and other cached lookups |
| Ownership | owned |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Redis product cache | Redis (JTIER Cache Redis) | Caches product data to avoid repeated PostgreSQL reads on hot paths | Configured per JTIER cache conventions |
| In-memory product cache | In-memory (MemoryProductDao) | JVM-level cache for the hottest product data, sits in front of Redis | Short TTL, per-instance |

## Data Flows

- **Write path**: API requests flow through Domain Facades to Domain Services to Domain Repositories, which persist data via Postgres Data Access (JDBI DAOs) to `continuumCloInventoryDb`. Cache invalidation or update occurs as needed.
- **Read path**: Domain Repositories first check the Cache Data Access layer (in-memory cache, then Redis cache). On cache miss, the request falls through to Postgres Data Access (JDBI DAOs) reading from `continuumCloInventoryDb`. Cache is populated on read-through.
- **Cache hierarchy**: MemoryProductDao (JVM-local) -> RedisProductDao (shared Redis) -> PostgresProductDao (authoritative PostgreSQL). This three-tier approach minimizes database load for high-frequency product reads.
