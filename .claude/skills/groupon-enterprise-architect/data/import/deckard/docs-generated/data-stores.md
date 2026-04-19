---
service: "deckard"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumCacheRedisCluster"
    type: "redis"
    purpose: "Consumer inventory unit application cache"
  - id: "continuumAsyncUpdateRedis"
    type: "redis"
    purpose: "Async update queue backing store"
---

# Data Stores

## Overview

Deckard owns two Redis data stores: an application cache cluster that holds pre-built consumer inventory indexes, and a standalone Redis instance that backs the async update queue. Deckard does not use any relational database. All persistent state is stored in Redis; there are no schema migrations. Data freshness is maintained through a combination of TTL-based expiration, mbus event-triggered refreshes, and periodic async re-fetches.

## Stores

### Redis Application Cache Cluster (`continuumCacheRedisCluster`)

| Property | Value |
|----------|-------|
| Type | redis (cluster mode) |
| Architecture ref | `continuumCacheRedisCluster` |
| Purpose | Caches per-consumer inventory unit lists and associated metadata needed for sorting, filtering, and pagination |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Consumer inventory index | Cached list of all inventory unit identifiers and metadata for a consumer | `consumer_id` (cache key), `inventoryServiceId`, `unitId`, `expiresAt`, `purchasedAt`, status flags |

#### Access Patterns

- **Read**: `BLSInventoryUnitVerticle` reads the consumer's cached inventory index on every inbound API request. On cache hit, Deckard applies filtering, sorting, and pagination locally without calling downstream inventory services.
- **Write**: `DequeueVerticle` writes refreshed consumer inventory data to the cache after fetching from downstream services. `OrdersMsgHandlerVerticle`, `InventoryServiceMsgHandlerVerticle`, and `UsersMsgHandlerVerticle` trigger writes via the async queue.
- **Indexes**: Keyed by `consumer_id` (UUID). No secondary indexes.

#### Cache TTL Configuration (`config/cache.json`)

| Setting | Value | Description |
|---------|-------|-------------|
| `referenceConsumerCacheStaleAge` | `PT15M` (15 minutes) | Age at which a cache entry is considered stale and triggers an async background refresh |
| `referenceConsumerCacheExpirationAge` | `P1D` (24 hours) | Age at which a cache entry expires and must be fully rebuilt on the next request |
| `servingStaleData` | `false` | When `false`, Deckard does not serve expired data; it waits for a fresh fetch |

### Redis Async Update Queue (`continuumAsyncUpdateRedis`)

| Property | Value |
|----------|-------|
| Type | redis (standalone) |
| Architecture ref | `continuumAsyncUpdateRedis` |
| Purpose | Backs the async update queue; stores pending cache refresh requests triggered by mbus events or stale cache hits |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Async update queue entries | Pending consumer cache refresh jobs | `consumer_id`, inventory service scope |

#### Access Patterns

- **Read**: `DequeueVerticle` dequeues pending refresh jobs at a configured interval (every 1000 ms), processing up to 100 items per dequeue cycle.
- **Write**: `QueueVerticle` enqueues refresh requests; called by all three message handler verticles when events arrive.
- **Indexes**: Queue-based access; no secondary indexes.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumCacheRedisCluster` | redis cluster | Per-consumer inventory unit index with sorting/filtering metadata | Stale: 15 min, Expiry: 24 hours |
| `continuumAsyncUpdateRedis` | redis standalone | Async update queue for background cache refresh jobs | Queue-based (no TTL on entries) |

## Data Flows

On a cache miss or stale cache hit, `BLSInventoryUnitVerticle` fetches inventory units from all configured downstream inventory services in parallel, merges the results, and writes the merged set to `continuumCacheRedisCluster`. In parallel, mbus events flow into handler verticles, which place refresh requests onto `continuumAsyncUpdateRedis`; `DequeueVerticle` dequeues these requests, calls downstream inventory services, and writes updated data back to `continuumCacheRedisCluster`. This dual-path mechanism keeps the cache warm between direct API calls.
