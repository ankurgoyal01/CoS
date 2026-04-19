---
service: "deckard"
title: "Async Cache Refresh (Inventory Update Event)"
generated: "2026-03-03"
type: flow
flow_name: "async-cache-refresh"
flow_type: event-driven
trigger: "mbus event on InventoryUnits.Updated.* or Orders.InventoryUnits.StatusChanged topic"
participants:
  - "continuumDeckardService"
  - "continuumAsyncUpdateRedis"
  - "continuumCacheRedisCluster"
  - "inventoryServices6c31"
architecture_ref: "dynamic-deckard"
---

# Async Cache Refresh (Inventory Update Event)

## Summary

When an inventory service or the Orders service publishes an event to the Groupon Message Bus indicating that a consumer's inventory unit has changed status, Deckard receives the event and schedules a background cache refresh for the affected consumer. The refresh is queued in a standalone Redis instance and dequeued by a pool of `DequeueVerticle` workers that re-fetch inventory units from downstream services and write the updated data to the application cache cluster. This flow keeps the cache current without requiring a new API request from API Lazlo.

## Trigger

- **Type**: event
- **Source**: Groupon Message Bus (mbus) — `InventoryUnits.Updated.{service}` or `Orders.InventoryUnits.StatusChanged` topic
- **Frequency**: Per inventory unit state change; high frequency during bulk order processing

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Groupon Message Bus | Delivers event to Deckard subscription | `mbusMessageBus7e8c` (stub) |
| Deckard Service (`LazloMessageBusClientVerticle`) | Receives mbus event and dispatches to appropriate handler | `continuumDeckardService` |
| `InventoryServiceMsgHandlerVerticle` or `OrdersMsgHandlerVerticle` | Processes the event and enqueues a cache refresh job | `continuumDeckardService` |
| `QueueVerticle` | Accepts and stores the refresh job | `continuumDeckardService` |
| Redis Async Update Queue | Persists pending refresh jobs | `continuumAsyncUpdateRedis` |
| `DequeueVerticle` | Polls and processes pending refresh jobs | `continuumDeckardService` |
| Inventory Services | Provide fresh inventory unit data for the consumer | `inventoryServices6c31` (stub) |
| Redis Cache Cluster | Receives updated consumer inventory index | `continuumCacheRedisCluster` |

## Steps

1. **Event delivered**: The Groupon Message Bus delivers an inventory update event to Deckard's STOMP subscription (e.g., `InventoryUnits.Updated.Goods` with subscription ID `com.groupon.api.deckard.bls.goods_{env}`)
   - From: `mbusMessageBus7e8c`
   - To: `LazloMessageBusClientVerticle` within `continuumDeckardService`
   - Protocol: STOMP / mbus

2. **Dispatch to handler**: `LazloMessageBusClientVerticle` routes the event to the appropriate handler based on `lazloMbusClientBlsMap` configuration:
   - `InventoryUnits.Updated.*` → `InventoryServiceMsgHandlerVerticle`
   - `Orders.InventoryUnits.StatusChanged` → `OrdersMsgHandlerVerticle`
   - From: `LazloMessageBusClientVerticle`
   - To: handler verticle
   - Protocol: Vert.x event bus (internal)

3. **Validate message age**: Handler checks message timestamp; discards messages older than `messageMaxAgeInMillis` (900,000 ms / 15 minutes) to avoid processing stale events after a Deckard outage

4. **Deserialize event**: Handler deserializes the event using the configured topic bean (`InventoryUnitsUpdatedTopicMsg` or `InventoryUnitsStatusChangedTopicMsg`) to extract the affected `consumer_id`

5. **Enqueue refresh job**: Handler calls `QueueVerticle` with the `consumer_id` to schedule an async cache refresh
   - From: Handler verticle
   - To: `QueueVerticle`
   - Protocol: Vert.x event bus (internal)

6. **Write to async queue**: `QueueVerticle` writes the refresh job to `continuumAsyncUpdateRedis`
   - From: `QueueVerticle`
   - To: `continuumAsyncUpdateRedis`
   - Protocol: Redis protocol

7. **Dequeue job**: `DequeueVerticle` polls `continuumAsyncUpdateRedis` every 1,000 ms and dequeues up to 100 jobs per cycle
   - From: `DequeueVerticle`
   - To: `continuumAsyncUpdateRedis`
   - Protocol: Redis protocol

8. **Fetch fresh inventory data**: `DequeueVerticle` calls `BLSInventoryUnitVerticle` which dispatches parallel requests to all inventory services for the `consumer_id` (same fetch pattern as cache-miss flow)
   - From: `continuumDeckardService`
   - To: All configured inventory services
   - Protocol: REST / HTTP

9. **Write updated cache**: Merged inventory units are written to `continuumCacheRedisCluster`, replacing the previous entry
   - From: `continuumDeckardService`
   - To: `continuumCacheRedisCluster`
   - Protocol: Redis protocol

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Message older than 15 minutes | Message discarded; no refresh enqueued | Cache not updated from this event; next API request will trigger a fresh fetch if stale |
| Queue full / Redis async write failure | Refresh job lost; cache not refreshed by this event | Stale cache until next API call or next mbus event |
| Inventory service timeout during dequeue refresh | Partial data written to cache; failed services recorded | Partial cache entry; will be corrected on next event or API cache-miss |
| `DequeueVerticle` backlog | Jobs processed in batch (100 per cycle, every 1 s); older jobs may wait | Short delay in cache freshness; SLA for async refresh is best-effort |

## Sequence Diagram

```
mbus               -> Deckard (LazloMbusClient)   : STOMP DELIVER InventoryUnits.Updated.Goods { consumer_id: <UUID> }
Deckard (MsgHandler) -> Deckard (QueueVerticle)   : enqueue(consumer_id=<UUID>)
Deckard (QueueVerticle) -> Redis Async Queue       : RPUSH refresh_queue consumer_id=<UUID>
Redis Async Queue  --> Deckard (QueueVerticle)     : OK
[1000ms polling interval]
Deckard (DequeueVerticle) -> Redis Async Queue     : LPOP refresh_queue [up to 100]
Redis Async Queue  --> Deckard (DequeueVerticle)   : [consumer_id=<UUID>, ...]
Deckard (DequeueVerticle) -> Goods Service         : GET /inventory_units?consumer_id=<UUID>
Deckard (DequeueVerticle) -> VIS Service           : GET /inventory_units?consumer_id=<UUID>
[... other services ...]
Deckard (DequeueVerticle) -> Redis Cache Cluster   : SET consumer_inventory_index[<UUID>] = merged_units
Redis Cache Cluster --> Deckard (DequeueVerticle)  : OK
```

## Related

- Architecture dynamic view: `dynamic-deckard`
- Related flows: [User Account Merge](user-account-merge.md), [Stale Cache Background Refresh](stale-cache-refresh.md), [Inventory Units Request (Cache Miss)](inventory-units-cache-miss.md)
