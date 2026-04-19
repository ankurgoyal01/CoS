---
service: "alligator"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumAlligatorRedis"
    type: "redis"
    purpose: "Cache for card, deck, template, client, geo polygon, and permalink data assembled from the Cardatron Campaign Service"
---

# Data Stores

## Overview

Alligator owns one data store: a Redis cache (`continuumAlligatorRedis`) that holds assembled card catalog data fetched from the Cardatron Campaign Service. The cache eliminates per-request fan-out to upstream services. It is populated by the `cacheReloadWorker` scheduled background worker and read at request time by the `cacheAndCatalogAccess` component. Alligator is otherwise stateless — it owns no relational database.

## Stores

### Alligator Redis Cache (`continuumAlligatorRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumAlligatorRedis` |
| Purpose | Stores card, deck, template, client, geo polygon, and permalink lookup data for request-time card assembly without hitting upstream services |
| Ownership | owned |
| Migrations path | Not applicable — cache only; no schema migrations |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Decks | Deck definitions keyed by UUID | `deck_id`, `client_id`, `forced_experiments` |
| Cards | Card definitions keyed by UUID; includes child card references | `card_uuid`, `type`, child card UUIDs |
| Templates | Card template definitions keyed by UUID | `template_uuid` |
| Clients | Client definitions keyed by UUID and by platform name | `client_uuid`, `platform` |
| Geo Polygons | Geographic polygon definitions for division and geo-location lookup | polygon geometry, division identifier |
| Permalinks | Card permalink DTOs keyed by permalink string | `permalink`, `deck_id`, `card_uuid`, `brand`, `client_id` |

#### Access Patterns

- **Read**: At request time, `cacheAndCatalogAccess` reads deck, card, template, client, geo polygon, and permalink entries by UUID or lookup key to assemble card responses. Examples: `getDeckByUuid`, `getCardByUuid`, `getClientByPlatform`, `getAllGeoPolygons`, `findPermalinkDto`, `findDeckIdBypermalinkDtoClientIdAndBrand`.
- **Write**: `cacheReloadWorker` refreshes all cache entries on a scheduled basis by fetching the latest data from the Cardatron Campaign Service via `sourceClientExecutors` and overwriting Redis keys. `continuumAlligatorService` also performs health-check reads/writes to Redis.
- **Indexes**: Keys are string-serialized UUIDs and lookup identifiers (`StringRedisSerializer`). Values are JSON-serialized using `Jackson2JsonRedisSerializer` with full field visibility enabled.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumAlligatorRedis` | Redis (Lettuce async + Jedis sync clients) | Primary card catalog cache: decks, cards, templates, clients, geo polygons, permalinks | Managed by `cacheReloadWorker` reload schedule; no static TTL discovered in codebase |

## Data Flows

The `cacheReloadWorker` component periodically fetches fresh catalog data from the Cardatron Campaign Service using the `sourceClientExecutors` HTTP client layer (paginated bulk fetch) and overwrites the corresponding Redis keys in `continuumAlligatorRedis`. At request time, `cacheAndCatalogAccess` reads from Redis; cache misses result in degraded responses or empty card sets until the next reload cycle. No CDC pipeline, ETL process, or replication to secondary stores was found.
