---
service: "deckard"
title: "Inventory Units Request (Cache Hit)"
generated: "2026-03-03"
type: flow
flow_name: "inventory-units-cache-hit"
flow_type: synchronous
trigger: "API Lazlo HTTP GET /v1/inventory_units with valid cached data"
participants:
  - "continuumApiLazloService"
  - "continuumDeckardService"
  - "continuumCacheRedisCluster"
architecture_ref: "dynamic-deckard"
---

# Inventory Units Request (Cache Hit)

## Summary

This is the primary happy-path flow for Deckard. When API Lazlo requests a consumer's inventory units and the Redis cache contains a valid (non-stale, non-expired) entry for that consumer, Deckard fulfills the request entirely from cache without calling any downstream inventory services. The service applies filtering, sorting, and pagination on the in-memory representation of the cached data and returns the result set to the caller within the 6-second SLA window.

## Trigger

- **Type**: api-call
- **Source**: `continuumApiLazloService` (API Lazlo)
- **Frequency**: On-demand, at peak up to 250 requests per second

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Lazlo | Initiates request; sole caller of Deckard | `continuumApiLazloService` |
| Deckard Service | Receives request; checks cache; applies filter/sort/paginate; returns response | `continuumDeckardService` |
| Redis Cache Cluster | Stores and returns cached consumer inventory index | `continuumCacheRedisCluster` |

## Steps

1. **Receive request**: API Lazlo sends `GET /v1/inventory_units?consumer_id=<UUID>&offset=<N>&limit=<N>[&filter=...][&sort=...]`
   - From: `continuumApiLazloService`
   - To: `continuumDeckardService`
   - Protocol: REST / HTTP

2. **Route to BLS handler**: `LazloControllerVerticle` receives the HTTP request and dispatches to `BLSInventoryUnitVerticle`
   - From: Controller layer
   - To: `BLSInventoryUnitVerticle`
   - Protocol: Vert.x event bus (internal)

3. **Check Redis cache**: `BLSInventoryUnitVerticle` looks up the consumer's inventory index by `consumer_id`
   - From: `continuumDeckardService`
   - To: `continuumCacheRedisCluster`
   - Protocol: Redis protocol

4. **Cache returns valid entry**: Redis returns the cached consumer inventory index with all unit metadata (unit IDs, service IDs, `expiresAt`, `purchasedAt`, status flags)
   - From: `continuumCacheRedisCluster`
   - To: `continuumDeckardService`
   - Protocol: Redis protocol

5. **Parse filter expression** (if `filter` param provided): The ANTLR4-generated `Filter` parser evaluates the filter expression against the cached unit metadata
   - From: `BLSInventoryUnitVerticle`
   - To: Filter grammar engine (internal)
   - Protocol: In-process

6. **Apply filter**: Units not matching the filter expression are excluded from the result set

7. **Apply sort** (if `sort` param provided): `InventoryUnitSortingComparator` sorts the filtered units by the requested fields (`inventory_service_id`, `expires_at`, or `purchased_at`) in the specified direction

8. **Apply pagination**: The sorted list is sliced using `offset` and `limit` parameters; total `count` is computed over the filtered (pre-slice) set

9. **Return response**: Deckard returns the paginated `inventoryUnits` array, `pagination` metadata, and an empty `errors` object
   - From: `continuumDeckardService`
   - To: `continuumApiLazloService`
   - Protocol: REST / HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis read timeout | Falls through to cache-miss flow; fetches from downstream services | Elevated latency; no data loss |
| Invalid `filter` expression | ANTLR4 parse error returned as 4xx bad request | Request rejected; error message returned |
| `limit` exceeds 100 | Request rejected by parameter validation | 4xx error returned to caller |
| Cache entry expired (age > P1D) | Treats as cache miss; proceeds to cache-miss flow | Transparent to caller; elevated latency |

## Sequence Diagram

```
API Lazlo          -> Deckard Service   : GET /v1/inventory_units?consumer_id=<UUID>&offset=0&limit=25&filter=available
Deckard Service    -> Redis Cache       : GET consumer_inventory_index[consumer_id]
Redis Cache        --> Deckard Service  : { units: [...], metadata: {...} } (valid, non-stale entry)
Deckard Service    -> Deckard Service   : parse filter expression "available"
Deckard Service    -> Deckard Service   : apply filter (exclude redeemed/expired units)
Deckard Service    -> Deckard Service   : apply sort (default: purchased_at:desc)
Deckard Service    -> Deckard Service   : paginate (offset=0, limit=25)
Deckard Service    --> API Lazlo        : { inventoryUnits: [...], pagination: { count: 42, offset: 0 }, errors: {} }
```

## Related

- Architecture dynamic view: `dynamic-deckard`
- Related flows: [Inventory Units Request (Cache Miss)](inventory-units-cache-miss.md), [Stale Cache Background Refresh](stale-cache-refresh.md)
