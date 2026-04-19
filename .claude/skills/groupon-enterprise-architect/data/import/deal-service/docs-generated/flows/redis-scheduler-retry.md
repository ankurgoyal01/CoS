---
service: "deal-service"
title: "Redis Scheduler Retry"
generated: "2026-03-02"
type: flow
flow_name: "redis-scheduler-retry"
flow_type: event-driven
trigger: "Failed deal added to nodejs_deal_scheduler Redis sorted set; polled on each processing cycle"
participants:
  - "continuumDealService"
  - "continuumDealServiceRedisLocal"
architecture_ref: "dynamic-redis-scheduler-retry"
---

# Redis Scheduler Retry

## Summary

When a deal fails to process (due to an upstream API error or data issue), it is not immediately re-queued into `processing_cloud`. Instead, the `redisScheduler` component writes the deal ID into the `nodejs_deal_scheduler` Redis sorted set with a future timestamp as the score. A background poller scans this sorted set and moves any entries whose score (timestamp) has elapsed back into `processing_cloud` for reprocessing. This provides a lightweight backoff retry mechanism without an external scheduler or DLQ.

## Trigger

- **Type**: event
- **Source**: A deal processing failure causes `redisScheduler` to write to `nodejs_deal_scheduler`; the poller fires on each processing cycle
- **Frequency**: Polled every 5 seconds (same interval as the main processing cycle, `feature_flags.processDeals.intervalInSec`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Service Worker (`redisScheduler`) | Writes failed deals to scheduler; polls scheduler for due entries | `continuumDealService` |
| Deal Service Redis (Local) | Stores `nodejs_deal_scheduler` sorted set and `processing_cloud` sorted set | `continuumDealServiceRedisLocal` |

## Steps

1. **Detects processing failure**: During [Deal State Update and Inventory Publish](deal-state-update-and-inventory-publish.md), `processDeal` catches an error for a specific deal.
   - From: `processDeal` component
   - To: `redisScheduler` component
   - Protocol: in-process

2. **Calculates retry timestamp**: `redisScheduler` determines the future timestamp for the retry attempt (backoff duration).
   - From: `continuumDealService` (in-process)
   - Protocol: in-process

3. **Writes deal to scheduler sorted set**: `redisScheduler` adds the deal ID to `nodejs_deal_scheduler` with the retry timestamp as the score.
   - From: `continuumDealService`
   - To: `continuumDealServiceRedisLocal`
   - Protocol: Redis (ZADD `nodejs_deal_scheduler` <timestamp> <deal_id>)

4. **Poller checks scheduler set**: On each cycle, `redisScheduler` queries `nodejs_deal_scheduler` for entries with score (timestamp) less than or equal to the current time.
   - From: `continuumDealService`
   - To: `continuumDealServiceRedisLocal`
   - Protocol: Redis (ZRANGEBYSCORE `nodejs_deal_scheduler` 0 <now>)

5. **Moves due entries to processing queue**: For each entry whose retry time has elapsed, `redisScheduler` removes it from `nodejs_deal_scheduler` and adds it to `processing_cloud`.
   - From: `continuumDealService`
   - To: `continuumDealServiceRedisLocal`
   - Protocol: Redis (ZREM `nodejs_deal_scheduler` + ZADD `processing_cloud`)

6. **Deal re-enters processing cycle**: The deal ID is now in `processing_cloud` and will be dequeued and processed on the next [Deal Processing Cycle](deal-processing-cycle.md) iteration.
   - From: `continuumDealServiceRedisLocal`
   - To: `continuumDealService` (next polling cycle)
   - Protocol: Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable when writing to `nodejs_deal_scheduler` | Write fails; failure logged | Deal is not scheduled for retry; may be lost from processing until manually re-enqueued |
| Redis unavailable when polling `nodejs_deal_scheduler` | Poll fails; scheduler skips that cycle | Due entries remain in sorted set; picked up on next successful poll |
| Deal fails again after retry | Deal is re-added to `nodejs_deal_scheduler` with another backoff timestamp | Retry loop continues; persistent failures accumulate log entries in Splunk |

## Sequence Diagram

```
processDeal -> redisScheduler: notify failure (deal_id)
redisScheduler -> redisScheduler: calculate retry timestamp
redisScheduler -> RedisLocal: ZADD nodejs_deal_scheduler <timestamp> <deal_id>
--- (next polling cycle) ---
redisScheduler -> RedisLocal: ZRANGEBYSCORE nodejs_deal_scheduler 0 <now>
RedisLocal --> redisScheduler: [due deal IDs]
redisScheduler -> RedisLocal: ZREM nodejs_deal_scheduler <deal_id>
redisScheduler -> RedisLocal: ZADD processing_cloud <now> <deal_id>
--- (next processing cycle) ---
processDeal -> RedisLocal: ZRANGEBYSCORE processing_cloud (dequeue)
RedisLocal --> processDeal: deal_id
processDeal -> processDeal: retry deal processing
```

## Related

- Architecture dynamic view: `dynamic-redis-scheduler-retry`
- Related flows: [Deal Processing Cycle](deal-processing-cycle.md), [Deal State Update and Inventory Publish](deal-state-update-and-inventory-publish.md)
