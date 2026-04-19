---
service: "afl-rta"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumAflRtaMySql"
    type: "mysql"
    purpose: "Persists click history, attribution tiers, and deduplicated attributed orders"
---

# Data Stores

## Overview

AFL RTA owns a single MySQL database managed via the JTier DaaS (Database-as-a-Service) platform. The database is the authoritative store for click history used in the 7-day attribution window correlation, attribution tier configuration, and deduplicated attributed order records. Schema migrations are managed by `jtier-migrations`. An in-process `cache2k` cache is used to reduce repeated MySQL reads for deal taxonomy and attribution tier data.

## Stores

### AFL RTA MySQL (`continuumAflRtaMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumAflRtaMySql` |
| Purpose | Persists external referrer click history, attribution tiers per channel, and attributed order audit records |
| Ownership | owned |
| Migrations path | `src/main/resources/` (managed by `jtier-migrations`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Clicks | Stores attributed external referrer click events for the 7-day attribution window | bcookie, click timestamp, channel, affiliate ID, click URL, promo code |
| Attribution Tiers | Defines channel-specific attribution priority and eligibility rules | channel, tier rank, enabled flag |
| Attributed Orders | Audit record of successfully attributed deal purchase events | order ID, channel, affiliate ID, attribution timestamp, deal ID, customer status |

#### Access Patterns

- **Read**: `ClicksService` performs click-history lookups by bcookie when processing `dealPurchase` events; attribution tier configuration is read at startup and cached in `cache2k`
- **Write**: `ClicksService` inserts new click records when processing `externalReferrer` events; `OrderService` inserts attributed order records after successful MBus publish or logging fallback
- **Indexes**: Bcookie lookup index on the clicks table is critical for attribution performance (exact index names not visible without schema files; inferred from access patterns)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Attribution tier cache | in-memory (cache2k 2.6.1.Final) | Caches attribution tier configuration read from MySQL to reduce DB reads per event | Not specified in available config |
| Deal taxonomy cache | in-memory (cache2k 2.6.1.Final) | Caches MDS deal taxonomy lookups to reduce outbound HTTP calls to `continuumMarketingDealService` | Not specified in available config |

## Data Flows

1. **Click ingestion**: `externalReferrer` event arrives via Kafka -> `ClickAttributionStrategy` -> `ClicksService` -> INSERT into MySQL clicks table.
2. **Order attribution**: `dealPurchase` event arrives via Kafka -> `OrderAttributionStrategy` -> `ClicksService` reads click history from MySQL by bcookie -> attribution correlation logic runs -> `OrderService` writes attributed order to MySQL.
3. **Enrichment**: During order attribution, `OrderService` calls `continuumOrdersService` (HTTPS) and `continuumMarketingDealService` / MDS (HTTPS) for order and deal metadata; these are not persisted in AFL RTA's own database beyond the attributed order record.
4. **No CDC or replication** patterns are visible in this repository; MySQL is the single source of truth for attribution state.
