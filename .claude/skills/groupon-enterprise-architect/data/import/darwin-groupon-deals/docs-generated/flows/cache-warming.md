---
service: "darwin-groupon-deals"
title: "Cache Warming"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "cache-warming"
flow_type: event-driven
trigger: "Successful completion of an aggregation cycle (REST or async); cacheLayer writes result to Redis"
participants:
  - "cacheLayer"
  - "aggregationEngine"
  - "redisClusterExt_9d0c11"
architecture_ref: "darwinAggregatorServiceComponents"
---

# Cache Warming

## Summary

Cache Warming is the post-aggregation write-back step that populates the Redis cache after every successful deal aggregation. After `aggregationEngine` produces a ranked deal response, the `cacheLayer` component serializes the result using Kryo and stores it in Redis under a cache key derived from the request parameters. Subsequent identical requests (same query, user context, geo) are served directly from cache, short-circuiting the full aggregation fan-out and significantly reducing latency and upstream load. This flow applies to both the [REST Deal Search](rest-deal-search.md) and [Async Batch Aggregation](async-batch-aggregation.md) paths.

## Trigger

- **Type**: event (internal, post-aggregation)
- **Source**: `aggregationEngine` signals completion of a successful aggregation; `cacheLayer` initiates write-back
- **Frequency**: per-request (on every cache miss that results in a successful aggregation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `aggregationEngine` | Produces ranked deal response; triggers cache write-back | `continuumDarwinAggregatorService` |
| `cacheLayer` | Generates cache key; serializes response with Kryo; writes to Redis | `continuumDarwinAggregatorService` |
| Redis Cluster | Stores serialized deal response under cache key with TTL | `redisClusterExt_9d0c11` |

## Steps

1. **Receive Aggregation Result**: `cacheLayer` receives the completed ranked deal response from `aggregationEngine`.
   - From: `aggregationEngine`
   - To: `cacheLayer`
   - Protocol: In-process

2. **Generate Cache Key**: `cacheLayer` computes a deterministic cache key from the request parameters (query, user identity token, geo context, result count, and any filter parameters).
   - From: `cacheLayer`
   - To: In-process
   - Protocol: In-process

3. **Serialize Response**: `cacheLayer` serializes the ranked deal response using Kryo 5.6.2 for compact binary representation.
   - From: `cacheLayer`
   - To: In-process (Kryo serializer)
   - Protocol: In-process

4. **Write to Redis**: `cacheLayer` issues a Redis SET command with the serialized payload and a configured TTL, storing the response under the computed cache key.
   - From: `cacheLayer`
   - To: `redisClusterExt_9d0c11`
   - Protocol: Redis protocol (Jedis 2.9.0)

5. **Acknowledge Write**: Redis confirms the write; `cacheLayer` proceeds without blocking the response path (write-back is typically fire-and-forget or async to avoid adding latency to the caller).
   - From: `redisClusterExt_9d0c11`
   - To: `cacheLayer`
   - Protocol: Redis protocol

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis write failure (connection error) | Error logged; cache write skipped | Response returned to caller; cache not populated; next request will also miss |
| Redis write failure (OOM / eviction) | Redis evicts existing keys per eviction policy | Cache hit rate may decline during memory pressure; service continues normally |
| Kryo serialization failure | Error logged; cache write skipped | Response returned; cache not populated |
| Redis TTL not set | Key persists until eviction | Stale data risk if TTL misconfigured; confirm TTL values with service owner |

## Sequence Diagram

```
aggregationEngine -> cacheLayer:             Ranked deal response (post-aggregation)
cacheLayer        -> cacheLayer:             Compute cache key from request params
cacheLayer        -> cacheLayer:             Serialize response (Kryo)
cacheLayer        -> redisClusterExt_9d0c11: SET <cache_key> <serialized_bytes> EX <ttl>
redisClusterExt   --> cacheLayer:            OK
cacheLayer        --> aggregationEngine:     Write-back complete (non-blocking)
```

## Related

- Architecture dynamic view: `darwinAggregatorServiceComponents`
- Related flows: [REST Deal Search](rest-deal-search.md), [Async Batch Aggregation](async-batch-aggregation.md)
- Data store details: [Data Stores — Redis](../data-stores.md)
