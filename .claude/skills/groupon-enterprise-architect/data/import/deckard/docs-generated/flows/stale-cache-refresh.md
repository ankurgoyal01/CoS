---
service: "deckard"
title: "Stale Cache Background Refresh"
generated: "2026-03-03"
type: flow
flow_name: "stale-cache-refresh"
flow_type: asynchronous
trigger: "API request hits a cache entry older than referenceConsumerCacheStaleAge (PT15M)"
participants:
  - "continuumApiLazloService"
  - "continuumDeckardService"
  - "continuumCacheRedisCluster"
  - "continuumAsyncUpdateRedis"
  - "inventoryServices6c31"
architecture_ref: "dynamic-deckard"
---

# Stale Cache Background Refresh

## Summary

When an API request arrives and the consumer's cache entry exists but is older than the stale age threshold (15 minutes), Deckard serves the existing stale data immediately to the caller (when `servingStaleData: false` is not applicable to stale-but-not-expired entries) while concurrently enqueuing an async background refresh. This pattern ensures low latency for the current request while proactively keeping the cache warm. The refresh happens via the same async queue used by mbus event handlers, processed by `DequeueVerticle`.

## Trigger

- **Type**: api-call (with stale cache side-effect)
- **Source**: `continuumApiLazloService` (API Lazlo)
- **Frequency**: Any request where the cache entry age is between `PT15M` (stale) and `P1D` (expired)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Lazlo | Initiates the API request | `continuumApiLazloService` |
| Deckard Service | Detects stale entry; returns current data; enqueues background refresh | `continuumDeckardService` |
| Redis Cache Cluster | Returns stale but valid cache entry; later receives the refreshed entry | `continuumCacheRedisCluster` |
| Redis Async Update Queue | Holds the pending refresh job | `continuumAsyncUpdateRedis` |
| `DequeueVerticle` | Processes the queued background refresh | `continuumDeckardService` |
| Inventory Services | Provide fresh inventory unit data | `inventoryServices6c31` (stub) |

## Steps

1. **Receive request**: API Lazlo sends `GET /v1/inventory_units?consumer_id=<UUID>&offset=<N>&limit=<N>`
   - From: `continuumApiLazloService`
   - To: `continuumDeckardService`
   - Protocol: REST / HTTP

2. **Check Redis cache**: `BLSInventoryUnitVerticle` reads the consumer's inventory index from `continuumCacheRedisCluster`
   - From: `continuumDeckardService`
   - To: `continuumCacheRedisCluster`
   - Protocol: Redis protocol

3. **Detect stale entry**: Cache returns a valid entry, but its age exceeds `referenceConsumerCacheStaleAge` (PT15M = 15 minutes) and is below `referenceConsumerCacheExpirationAge` (P1D = 24 hours). The entry is stale but not expired.
   - From: `continuumCacheRedisCluster`
   - To: `continuumDeckardService`
   - Protocol: Redis protocol

4. **Serve stale data immediately**: `BLSInventoryUnitVerticle` applies the filter, sort, and pagination operations on the stale cache data and begins constructing the response to return to the caller without waiting for a refresh

5. **Enqueue background refresh (concurrent)**: In parallel with step 4, `BLSInventoryUnitVerticle` calls `QueueVerticle` to schedule an async cache refresh for this consumer
   - From: `BLSInventoryUnitVerticle`
   - To: `QueueVerticle`
   - Protocol: Vert.x event bus (internal)

6. **Write refresh job**: `QueueVerticle` pushes the job to `continuumAsyncUpdateRedis`
   - From: `QueueVerticle`
   - To: `continuumAsyncUpdateRedis`
   - Protocol: Redis protocol

7. **Return response to caller**: The filtered, sorted, paginated response based on stale data is returned to API Lazlo. The response is complete and within the SLA window.
   - From: `continuumDeckardService`
   - To: `continuumApiLazloService`
   - Protocol: REST / HTTP (JSON)

8. **Background dequeue**: `DequeueVerticle` picks up the queued refresh job (within ~1 second) and fetches fresh inventory units from all downstream services
   - From: `DequeueVerticle`
   - To: All inventory services
   - Protocol: REST / HTTP

9. **Update cache**: Freshly fetched and merged inventory units are written back to `continuumCacheRedisCluster`, replacing the stale entry
   - From: `continuumDeckardService`
   - To: `continuumCacheRedisCluster`
   - Protocol: Redis protocol

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Background refresh fails | Stale data served; cache entry remains stale; next request will also trigger a background refresh | Continued stale responses until a successful refresh; no impact on current request's SLA |
| Cache entry transitions from stale to expired between request and next call | Next request treats as cache miss; fetches synchronously | Higher latency on that next request |
| Async queue full | Refresh job dropped; cache remains stale | Cache stays stale until mbus event or next API request triggers another attempt |

## Sequence Diagram

```
API Lazlo          -> Deckard Service       : GET /v1/inventory_units?consumer_id=<UUID>
Deckard Service    -> Redis Cache           : GET consumer_inventory_index[consumer_id]
Redis Cache        --> Deckard Service      : { units: [...] } (stale: age=18min > PT15M threshold)
Deckard Service    -> Deckard Service       : apply filter, sort, paginate on stale data
Deckard Service    -> QueueVerticle         : enqueue background refresh (consumer_id=<UUID>)  [CONCURRENT]
QueueVerticle      -> Redis Async Queue     : RPUSH refresh_queue consumer_id=<UUID>
Deckard Service    --> API Lazlo            : { inventoryUnits: [...stale data...], pagination: {...}, errors: {} }
[~1s later - background]
DequeueVerticle    -> Redis Async Queue     : LPOP refresh_queue
DequeueVerticle    -> Inventory Services    : GET /inventory_units?consumer_id=<UUID> [all services in parallel]
Inventory Services --> DequeueVerticle      : fresh inventory unit data
DequeueVerticle    -> Redis Cache           : SET consumer_inventory_index[consumer_id] = fresh_units
```

## Related

- Architecture dynamic view: `dynamic-deckard`
- Related flows: [Inventory Units Request (Cache Hit)](inventory-units-cache-hit.md), [Inventory Units Request (Cache Miss)](inventory-units-cache-miss.md), [Async Cache Refresh](async-cache-refresh.md)
