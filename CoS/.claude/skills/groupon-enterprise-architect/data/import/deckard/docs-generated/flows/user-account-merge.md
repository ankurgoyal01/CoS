---
service: "deckard"
title: "User Account Merge"
generated: "2026-03-03"
type: flow
flow_name: "user-account-merge"
flow_type: event-driven
trigger: "users.account.v1.merged mbus event"
participants:
  - "continuumDeckardService"
  - "continuumAsyncUpdateRedis"
  - "continuumCacheRedisCluster"
  - "inventoryServices6c31"
architecture_ref: "dynamic-deckard"
---

# User Account Merge

## Summary

When two Groupon user accounts are merged (e.g., a consumer links accounts or a duplicate account is resolved), the Users service publishes a `users.account.v1.merged` event to the Groupon Message Bus. Deckard's `UsersMsgHandlerVerticle` receives this event and orchestrates a cache refresh that combines the inventory indexes of both consumer identities into the surviving consumer's entry. This ensures the My Groupons page shows a complete view of the merged consumer's purchase history after an account merge.

## Trigger

- **Type**: event
- **Source**: Groupon Message Bus (mbus) — `users.account.v1.merged` topic, published by the Users service
- **Frequency**: Low frequency (account merges are rare operations)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Users Service | Publishes account merge event | `continuumUsersService` (stub) |
| Groupon Message Bus | Delivers event to Deckard subscription | `mbusMessageBus7e8c` (stub) |
| Deckard Service (`UsersMsgHandlerVerticle`) | Processes the merge event and coordinates cache update | `continuumDeckardService` |
| `QueueVerticle` | Enqueues the refresh job for the merged consumer | `continuumDeckardService` |
| Redis Async Update Queue | Persists the pending merge/refresh job | `continuumAsyncUpdateRedis` |
| `DequeueVerticle` | Processes the queued merge job | `continuumDeckardService` |
| Inventory Services | Provide inventory units for the surviving consumer identity | `inventoryServices6c31` (stub) |
| Redis Cache Cluster | Stores the merged consumer's updated inventory index | `continuumCacheRedisCluster` |

## Steps

1. **Merge event delivered**: The Users service publishes `users.account.v1.merged` to mbus; Deckard receives it via subscription `com.groupon.api.deckard.bls.users_{env}`
   - From: `mbusMessageBus7e8c` (Users service via mbus)
   - To: `LazloMessageBusClientVerticle` within `continuumDeckardService`
   - Protocol: STOMP / mbus

2. **Route to UsersMsgHandlerVerticle**: `LazloMessageBusClientVerticle` dispatches the event to `UsersMsgHandlerVerticle` per the `lazloMbusClientBlsMap` configuration
   - From: `LazloMessageBusClientVerticle`
   - To: `UsersMsgHandlerVerticle`
   - Protocol: Vert.x event bus (internal)

3. **Validate message age**: Handler discards the event if it is older than 15 minutes (`messageMaxAgeInMillis`)

4. **Deserialize event**: `UsersMsgHandlerVerticle` deserializes the `UsersAccountMergedTopicMsg` to extract the source consumer ID (account being merged away) and the target consumer ID (surviving account)

5. **Enqueue merge/refresh job**: `UsersMsgHandlerVerticle` calls `QueueVerticle` to schedule a cache refresh for the surviving (target) consumer ID
   - From: `UsersMsgHandlerVerticle`
   - To: `QueueVerticle`
   - Protocol: Vert.x event bus (internal)

6. **Write refresh job to queue**: `QueueVerticle` writes the job to `continuumAsyncUpdateRedis`
   - From: `QueueVerticle`
   - To: `continuumAsyncUpdateRedis`
   - Protocol: Redis protocol

7. **Dequeue and process**: `DequeueVerticle` picks up the job and triggers a full inventory fetch for the surviving consumer ID from all inventory services (same parallel fetch as cache-miss flow)
   - From: `DequeueVerticle`
   - To: All configured inventory services
   - Protocol: REST / HTTP

8. **Write merged cache entry**: The freshly fetched inventory units (which the inventory services should already reflect post-merge) are written to `continuumCacheRedisCluster` under the surviving consumer ID
   - From: `continuumDeckardService`
   - To: `continuumCacheRedisCluster`
   - Protocol: Redis protocol

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Event older than 15 minutes | Discarded by `UsersMsgHandlerVerticle` | Cache not updated; will self-correct on next API request or subsequent event |
| Inventory services return incomplete data | Partial data cached; error metadata recorded | Merged consumer may see incomplete history temporarily |
| mbus event arrives before inventory systems complete merge | Inventory services may return pre-merge data for the surviving consumer | Cache contains pre-merge state; a subsequent event or API cache-miss will correct this |

## Sequence Diagram

```
Users Service      -> mbus                         : PUBLISH users.account.v1.merged { source_consumer_id, target_consumer_id }
mbus               -> Deckard (LazloMbusClient)    : STOMP DELIVER users.account.v1.merged
Deckard (UsersMsgHandler) -> Deckard (QueueVerticle) : enqueue(consumer_id=target_consumer_id)
Deckard (QueueVerticle) -> Redis Async Queue        : RPUSH refresh_queue target_consumer_id
[1000ms polling]
Deckard (DequeueVerticle) -> Redis Async Queue      : LPOP refresh_queue
Deckard (DequeueVerticle) -> Getaways Service       : GET /inventory_units?consumer_id=target_consumer_id
Deckard (DequeueVerticle) -> Goods Service          : GET /inventory_units?consumer_id=target_consumer_id
[... other services ...]
Deckard (DequeueVerticle) -> Redis Cache Cluster    : SET consumer_inventory_index[target_consumer_id] = merged_units
Redis Cache Cluster --> Deckard (DequeueVerticle)   : OK
```

## Related

- Architecture dynamic view: `dynamic-deckard`
- Related flows: [Async Cache Refresh](async-cache-refresh.md), [Inventory Units Request (Cache Miss)](inventory-units-cache-miss.md)
