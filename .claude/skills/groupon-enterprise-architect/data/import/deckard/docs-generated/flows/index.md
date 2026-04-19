---
service: "deckard"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Deckard.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Inventory Units Request (Cache Hit)](inventory-units-cache-hit.md) | synchronous | API Lazlo HTTP GET `/v1/inventory_units` | Returns filtered, sorted, paginated inventory unit identifiers from Redis cache without calling downstream services |
| [Inventory Units Request (Cache Miss)](inventory-units-cache-miss.md) | synchronous | API Lazlo HTTP GET `/v1/inventory_units` with no cached data | Fetches inventory units from all downstream services, merges, applies filter/sort/pagination, caches result, returns response |
| [Async Cache Refresh](async-cache-refresh.md) | asynchronous | mbus event received on any `InventoryUnits.Updated.*` or `Orders.InventoryUnits.StatusChanged` topic | Enqueues and processes a background cache refresh for the affected consumer without blocking any API request |
| [User Account Merge](user-account-merge.md) | event-driven | `users.account.v1.merged` mbus event | Merges and refreshes the Redis cache entries for two consumer identities being consolidated |
| [Stale Cache Background Refresh](stale-cache-refresh.md) | asynchronous | API request hits a stale (but not expired) cache entry | Returns stale data immediately to the caller while enqueuing an async refresh to update the cache in the background |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Background / triggered-async | 1 |

## Cross-Service Flows

Deckard's inventory aggregation is part of a broader My Groupons page rendering flow:

1. Front-end (iTier / Mobile) calls API Lazlo for My Groupons data
2. API Lazlo calls Deckard (`GET /v1/inventory_units`) to obtain the sorted/filtered/paginated list of unit identifier pairs
3. API Lazlo decorates those identifiers by calling decoration services (Mentos, M3) and returns enriched display data to the front-end

The cache keep-alive flow is cross-service: inventory services, the Orders service, and the Users service all publish to the Groupon Message Bus, which Deckard consumes to maintain cache freshness without requiring API Lazlo to trigger a full re-fetch.

See [Architecture Context](../architecture-context.md) for the full relationship map.
