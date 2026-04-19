---
service: "badges-trending-calculator"
title: "Trending and Top Seller Ranking Computation"
generated: "2026-03-03"
type: flow
flow_name: "trending-ranking-computation"
flow_type: event-driven
trigger: "Per Spark partition invocation during BadgeCalculatorProcessor.processRows"
participants:
  - "continuumBadgesTrendingCalculator"
  - "continuumBadgesRedisStore"
architecture_ref: "dynamic-deal-purchase-badge-computation"
---

# Trending and Top Seller Ranking Computation

## Summary

This flow describes the core badge ranking algorithm executed by `ProcessorTask.calculatorTask` for each Spark partition during a micro-batch. It reads 7 days of historical deal-count hashes from Redis, merges in the current batch's purchase counts, applies an exponential decay curve to compute Trending rank (more-recent purchases weighted higher), computes raw weekly totals for Top Seller rank, and writes both the updated daily hashes and the final Top-500 ranked lists back to Redis.

## Trigger

- **Type**: event
- **Source**: `BadgeCalculatorProcessor.processRows` invoked by Spark `foreachPartition` on each partition of the enriched micro-batch DataFrame
- **Frequency**: Once per Spark partition per micro-batch (every 600 seconds in production)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Badge Calculator Processor (`badgeCalculatorProcessor`) | Invokes ranking computation per partition | `continuumBadgesTrendingCalculator` |
| Trending Computation Engine (`trendingComputationEngine`) | Executes the 7-day rolling window ranking algorithm | `continuumBadgesTrendingCalculator` |
| Redis Persistence Adapter (`redisPersistenceAdapter`) | Reads existing hashes and writes updated state | `continuumBadgesTrendingCalculator` |
| Badges Redis Store | Persists all intermediate and final badge state | `continuumBadgesRedisStore` |

## Steps

1. **Build batch base map**: `BadgeCalculatorProcessor.processRows` iterates over the partition rows and builds a `HashMap[String, TrendingList]` keyed by the composite base key (`{prefix}|date={today}|type={channel}|div={division}`). Each `TrendingList` accumulates purchase counts by `{dealUUID}|{dealPermalink}`.
   - From: `badgeCalculatorProcessor`
   - To: `trendingComputationEngine` (via `ProcessorTask.calculatorTask`)
   - Protocol: in-process

2. **Iterate over 7-day window**: For each base key (division + channel), the engine iterates days 0 through 6 (today minus N days). For each day it constructs the dated key and reads the existing hash from Redis.
   - From: `trendingComputationEngine`
   - To: `continuumBadgesRedisStore` (`HGETALL {prefix}|date={date-N}|type={channel}|div={division}`)
   - Protocol: Redis (with 5-attempt retry / 50ms interval)

3. **Merge persisted counts into local TrendingList**: If the Redis hash is non-empty, the persisted counts are merged into the local `TrendingList` via `TrendingList.updateFromMap`. This combines already-accumulated historical counts with the current batch counts.
   - From: `trendingComputationEngine`
   - To: in-memory `TrendingList`
   - Protocol: in-process

4. **Accumulate weekly Top Seller list**: The unmodified (non-decayed) local `TrendingList` for each day is merged into `weeklyTrendingList` (used for Top Seller) — a simple sum of all purchase counts over 7 days.
   - From: `trendingComputationEngine`
   - To: `weeklyTrendingList` (in-memory)
   - Protocol: in-process

5. **Apply daily decay for Trending list**: A decay factor of `0.9^day` is applied to each deal's count for day N (day 0 = today, day 6 = oldest). The formula is `floor(count ^ (0.9^day))`. Decayed counts are merged into `weeklyDecayedTrendingList`.
   - From: `trendingComputationEngine`
   - To: `weeklyDecayedTrendingList` (in-memory)
   - Protocol: in-process

6. **Persist updated daily deal-count hash**: The merged daily `TrendingList` for today's key is written back to Redis. If the local map has entries, the existing hash is deleted and replaced with `HSET` + `EXPIRE` (8-day TTL / 691200 seconds).
   - From: `redisPersistenceAdapter`
   - To: `continuumBadgesRedisStore` (HSET + EXPIRE / UNLINK + HSET + EXPIRE)
   - Protocol: Redis

7. **Select Top-500 from weekly lists**: After the 7-day loop, `TrendingList.getTopN(500, enableRankAndCount=true)` is called on both `weeklyDecayedTrendingList` (Trending) and `weeklyTrendingList` (Top Seller). This returns an `ImmutableMap` sorted by descending count, capped at 500 entries, with value format `count={N}|Rank={R}`.
   - From: `trendingComputationEngine`
   - To: in-memory ranked map
   - Protocol: in-process

8. **Write final weekly summarized rankings**: `updateFinalSummarizedResults2` atomically replaces the `wfinal|{prefix}|{calcType}|{baseKey}` hash in Redis for both Trending (`trending`) and Top Seller (`top_seller`) calc types with the new Top-500 ranked maps. TTL = 691200 seconds.
   - From: `redisPersistenceAdapter`
   - To: `continuumBadgesRedisStore` (UNLINK + HSET + EXPIRE)
   - Protocol: Redis

9. **Write per-deal rank-and-count strings**: `updateFinalIndividualDealsResult2` writes a `SETEX` entry for each of the 500 ranked deals. In cluster mode, a CRC16 hash tag based on `dealUUID` is prepended to ensure slot affinity. Key format: `{hashTag}|{prefix}|wfinal|{calcType}_deal|{dealUUID}`. TTL = 86400 seconds (1 day).
   - From: `redisPersistenceAdapter`
   - To: `continuumBadgesRedisStore` (SETEX)
   - Protocol: Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis HGETALL fails (all 5 retries) | Exception propagates out of retry block | Rankings for that base key are skipped in this batch; stale Redis values remain |
| JedisConnectionException during write | Caught at base-key loop level; error logged | Writes for that base key skipped; rankings not updated |
| Lettuce connection pool exhaustion | Exception caught in `setWithExpiration` / `deleteAndUpdateFromMap`; error logged; returns empty string | Write skipped; stale ranking retained until next batch |
| Empty ranked map (no purchases) | `TrendingList.getTopN` returns empty map; `deleteAndUpdateFromMap` skips write if map is empty | Final ranking key not overwritten; existing ranking preserved |

## Sequence Diagram

```
ProcessorTask    Redis (7 days)    weeklyLists    Redis (final)
      |                |                |               |
      |  for day 0..6  |                |               |
      |--HGETALL day-N->|               |               |
      |<--hash counts---|               |               |
      |  merge+decay    |               |               |
      |--append to weeklyTopSeller---->|               |
      |--append decayed to weeklyTrending->|           |
      |--HSET+EXPIRE day-0 hash-------->|               |
      |  end loop       |                |               |
      |  getTopN(500) Trending          |               |
      |  getTopN(500) TopSeller         |               |
      |--UNLINK+HSET wfinal trending key--------------->|
      |--UNLINK+HSET wfinal top_seller key------------->|
      |--SETEX per-deal trending keys (x500)----------->|
      |--SETEX per-deal top_seller keys (x500)--------->|
```

## Related

- Architecture dynamic view: `dynamic-deal-purchase-badge-computation`
- Related flows: [Deal Purchase Badge Computation](deal-purchase-badge-computation.md)
