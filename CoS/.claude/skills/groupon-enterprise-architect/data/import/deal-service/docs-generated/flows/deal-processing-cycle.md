---
service: "deal-service"
title: "Deal Processing Cycle"
generated: "2026-03-02"
type: flow
flow_name: "deal-processing-cycle"
flow_type: batch
trigger: "Continuous timer — polls every 5 seconds (feature_flags.processDeals.intervalInSec)"
participants:
  - "continuumDealService"
  - "continuumDealServiceRedisLocal"
  - "continuumDealServiceMongo"
architecture_ref: "dynamic-deal-processing-cycle"
---

# Deal Processing Cycle

## Summary

The Deal Processing Cycle is the core operational loop of deal-service. A master process forks a worker process, which continuously polls the `processing_cloud` Redis sorted set for deal processing jobs. When the queue is low, the worker fills it by querying MongoDB for deals whose metadata is stale (based on configurable age thresholds). The worker then dequeues and processes deals in batches of up to 400 per cycle. This flow repeats indefinitely while the service is running and the `feature_flags.processDeals.active` flag is enabled.

## Trigger

- **Type**: schedule
- **Source**: Internal timer loop within the worker process
- **Frequency**: Every 5 seconds (default; configured via `feature_flags.processDeals.intervalInSec` in keldor-config)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Service Worker (master) | Forks and monitors the worker process | `continuumDealService` |
| Deal Service Worker (worker) | Runs the polling loop and processes deals | `continuumDealService` |
| Deal Service Redis (Local) | Holds the `processing_cloud` sorted set job queue | `continuumDealServiceRedisLocal` |
| Deal Service MongoDB | Source of deals eligible for processing (by staleness) | `continuumDealServiceMongo` |

## Steps

1. **Master forks worker**: On service startup the master process (`app.coffee`) forks a child worker process using Node.js `child_process`.
   - From: `continuumDealService` (master)
   - To: `continuumDealService` (worker)
   - Protocol: Node.js process fork

2. **Worker initializes**: Worker loads keldor-config via `configLoader_Dea`, establishes connections to Redis, MongoDB, and PostgreSQL, then enters the polling loop.
   - From: `continuumDealService` (worker)
   - To: `continuumDealServiceRedisLocal`, `continuumDealServiceMongo`, `continuumDealServicePostgres`
   - Protocol: Redis / MongoDB / Sequelize

3. **Checks feature flag**: Worker reads `feature_flags.processDeals.active` from `gConfig`. If `false`, the cycle is skipped and the timer resets.
   - From: `continuumDealService`
   - To: `gConfig` (in-process shared config)
   - Protocol: in-process

4. **Checks queue depth**: Worker queries the length of `processing_cloud` sorted set in Redis.
   - From: `continuumDealService`
   - To: `continuumDealServiceRedisLocal`
   - Protocol: Redis (ZCARD)

5. **Fills queue from MongoDB (when low)**: If `processing_cloud` length is below the configured limit (`feature_flags.processDeals.limit`, default 400), the worker queries MongoDB for deals with `ts_updated` older than `updateActiveInHours` (active deals, default 2h) or `updateInactiveInHours` (inactive deals, default 24h), and pushes their IDs into `processing_cloud` as scored entries.
   - From: `continuumDealService`
   - To: `continuumDealServiceMongo`
   - Protocol: MongoDB driver query

6. **Enqueues deals to Redis**: Pushes deal IDs returned by MongoDB into `processing_cloud` sorted set with current timestamp as score.
   - From: `continuumDealService`
   - To: `continuumDealServiceRedisLocal`
   - Protocol: Redis (ZADD)

7. **Dequeues batch**: Pops up to `feature_flags.processDeals.limit` deal entries from `processing_cloud` sorted set.
   - From: `continuumDealService`
   - To: `continuumDealServiceRedisLocal`
   - Protocol: Redis (ZRANGEBYSCORE + ZREM)

8. **Processes each deal**: For each dequeued deal ID, invokes the per-deal enrichment and persistence flow. See [Deal State Update and Inventory Publish](deal-state-update-and-inventory-publish.md).
   - From: `continuumDealService` (`processDeal` component)
   - To: upstream APIs, `continuumDealServicePostgres`, `continuumDealServiceMongo`, `messageBus`
   - Protocol: REST / Sequelize / MongoDB / nbus-client

9. **Timer resets**: After the batch completes, the worker waits for `feature_flags.processDeals.intervalInSec` seconds then returns to step 3.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `processing_cloud` Redis unavailable | Worker cannot dequeue; logs error | Polling resumes on next cycle; no deals processed |
| MongoDB unavailable during queue fill | Queue not filled; existing entries in `processing_cloud` are still processed | Deals in queue processed; new deals not added until MongoDB recovers |
| Individual deal processing failure | Failed deal is rescheduled into `nodejs_deal_scheduler` with backoff | Deal retried later; other deals in batch continue processing |
| `feature_flags.processDeals.active` = false | Processing loop skips execution | No deals processed until flag re-enabled |

## Sequence Diagram

```
Master -> Worker: fork()
Worker -> gConfig: load keldor-config
Worker -> RedisLocal: ZCARD processing_cloud
RedisLocal --> Worker: queue length
Worker -> MongoDB: query stale deals (if queue low)
MongoDB --> Worker: deal IDs
Worker -> RedisLocal: ZADD processing_cloud (deal IDs)
Worker -> RedisLocal: ZRANGEBYSCORE + ZREM (dequeue batch)
RedisLocal --> Worker: deal ID batch
Worker -> processDeal: process each deal (see deal-state-update flow)
Worker -> Worker: wait intervalInSec
Worker -> Worker: repeat loop
```

## Related

- Architecture dynamic view: `dynamic-deal-processing-cycle`
- Related flows: [Deal State Update and Inventory Publish](deal-state-update-and-inventory-publish.md), [Redis Scheduler Retry](redis-scheduler-retry.md), [Worker Process Restart](worker-process-restart.md), [Dynamic Configuration Reload](dynamic-configuration-reload.md)
