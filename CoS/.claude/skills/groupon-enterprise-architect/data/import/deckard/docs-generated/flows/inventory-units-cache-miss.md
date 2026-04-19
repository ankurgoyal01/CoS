---
service: "deckard"
title: "Inventory Units Request (Cache Miss)"
generated: "2026-03-03"
type: flow
flow_name: "inventory-units-cache-miss"
flow_type: synchronous
trigger: "API Lazlo HTTP GET /v1/inventory_units with no valid cached data"
participants:
  - "continuumApiLazloService"
  - "continuumDeckardService"
  - "continuumCacheRedisCluster"
  - "inventoryServices6c31"
architecture_ref: "dynamic-deckard"
---

# Inventory Units Request (Cache Miss)

## Summary

When API Lazlo requests a consumer's inventory units and the Redis cache has no entry for that consumer (or the entry has expired past the 24-hour limit), Deckard fetches inventory units directly from all configured downstream inventory services in parallel. It merges the results, applies filter, sort, and pagination, writes the merged set to Redis, and returns the paginated response. This is the cold-start or cache-expired path, which incurs significantly higher latency than the cache-hit path.

## Trigger

- **Type**: api-call
- **Source**: `continuumApiLazloService` (API Lazlo)
- **Frequency**: On-demand; less frequent than cache-hit under normal conditions; elevated during cold-start or cache flush

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Lazlo | Initiates request | `continuumApiLazloService` |
| Deckard Service | Receives request; orchestrates parallel inventory fetches; merges, filters, sorts, caches, returns | `continuumDeckardService` |
| Redis Cache Cluster | Returns cache-miss signal; receives the freshly merged inventory index | `continuumCacheRedisCluster` |
| Inventory Services (getaways, mrgetaways, glive, goods, clo, vis, tpis) | Return inventory units for the consumer | `inventoryServices6c31` (stub) |

## Steps

1. **Receive request**: API Lazlo sends `GET /v1/inventory_units?consumer_id=<UUID>&offset=<N>&limit=<N>[&filter=...][&sort=...]`
   - From: `continuumApiLazloService`
   - To: `continuumDeckardService`
   - Protocol: REST / HTTP

2. **Route to BLS handler**: `LazloControllerVerticle` dispatches to `BLSInventoryUnitVerticle`
   - From: Controller layer
   - To: `BLSInventoryUnitVerticle`
   - Protocol: Vert.x event bus (internal)

3. **Check Redis cache**: `BLSInventoryUnitVerticle` looks up the consumer's inventory index
   - From: `continuumDeckardService`
   - To: `continuumCacheRedisCluster`
   - Protocol: Redis protocol

4. **Cache miss returned**: Redis returns null or expired entry for this `consumer_id`
   - From: `continuumCacheRedisCluster`
   - To: `continuumDeckardService`
   - Protocol: Redis protocol

5. **Parallel inventory fetches**: `BLSInventoryUnitVerticle` dispatches concurrent HTTP requests to all enabled inventory service clients (up to 7 services simultaneously):
   - `getawaysInventoryClient` → `getaways-inventory.{env}.service`
   - `marketRateGetawaysInventoryClient` → `getaways-maris.{env}.service`
   - `gliveInventoryClient` → `grouponlive-inventory-service.{env}.service`
   - `goodsInventoryClient` → `goods-inventory-service.{env}.service`
   - `cloInventoryClient` → `clo-inventory-service.{env}.service`
   - `voucherV2Inventory` → `voucher-inventory.{env}.service`
   - `tpisInventoryClient` → `tpis-third-party-inventory-service.{env}.service`
   - From: `continuumDeckardService`
   - To: Each inventory service
   - Protocol: REST / HTTP

6. **Collect responses**: Deckard collects all responses. Failed services are recorded in `errors.inventoryServices`; the flow continues with partial data if `fail: false` (default)

7. **Merge inventory units**: All returned unit lists are merged into a single collection keyed by `inventoryServiceId` + `unitId`. Each unit carries metadata: `expiresAt`, `purchasedAt`, redemption status flags, gift flags, retained value flag

8. **Write to Redis cache**: The merged consumer inventory index is written to `continuumCacheRedisCluster` with the configured TTL (stale after 15 minutes, expired after 24 hours)
   - From: `continuumDeckardService`
   - To: `continuumCacheRedisCluster`
   - Protocol: Redis protocol

9. **Apply filter, sort, paginate**: Same as cache-hit path — filter expression parsed and applied, sort comparator applied, offset/limit slicing applied

10. **Return response**: Deckard returns the paginated result with any partial-failure error metadata
    - From: `continuumDeckardService`
    - To: `continuumApiLazloService`
    - Protocol: REST / HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Single inventory service timeout/error | Service listed in `errors.inventoryServices`; other services' units returned | Partial result; no failure by default (`fail: false`) |
| All inventory services fail | Empty `inventoryUnits` returned; all services listed in errors | Empty response; no 5xx unless `fail: true` |
| Redis write failure after fetch | Data returned to caller; cache not updated; next request will also miss | Elevated latency on subsequent requests; data still returned |
| Gift unit retrieval failure | `errors.giftedUnits.failureType` set; `failOnGift: false` by default | Response returned without gifted units |

## Sequence Diagram

```
API Lazlo          -> Deckard Service      : GET /v1/inventory_units?consumer_id=<UUID>&offset=0&limit=25
Deckard Service    -> Redis Cache          : GET consumer_inventory_index[consumer_id]
Redis Cache        --> Deckard Service     : null (cache miss)
Deckard Service    -> Getaways Service     : GET /inventory_units?consumer_id=<UUID>&clientId=deckard
Deckard Service    -> Goods Service        : GET /inventory_units?consumer_id=<UUID>&clientId=...
Deckard Service    -> VIS Service          : GET /inventory_units?consumer_id=<UUID>&clientId=...
Deckard Service    -> Glive Service        : GET /inventory_units?consumer_id=<UUID>&clientId=...
Deckard Service    -> TPIS Service         : GET /inventory_units?consumer_id=<UUID>&clientId=...
Deckard Service    -> CLO Service          : GET /inventory_units?consumer_id=<UUID>&clientId=...
Deckard Service    -> MR Getaways Service  : GET /inventory_units?consumer_id=<UUID>&clientId=...
[All services respond concurrently]
Deckard Service    -> Redis Cache          : SET consumer_inventory_index[consumer_id] = merged_units (TTL: 24h)
Redis Cache        --> Deckard Service     : OK
Deckard Service    -> Deckard Service      : filter, sort, paginate merged units
Deckard Service    --> API Lazlo           : { inventoryUnits: [...], pagination: {...}, errors: {...} }
```

## Related

- Architecture dynamic view: `dynamic-deckard`
- Related flows: [Inventory Units Request (Cache Hit)](inventory-units-cache-hit.md), [Stale Cache Background Refresh](stale-cache-refresh.md), [Async Cache Refresh](async-cache-refresh.md)
