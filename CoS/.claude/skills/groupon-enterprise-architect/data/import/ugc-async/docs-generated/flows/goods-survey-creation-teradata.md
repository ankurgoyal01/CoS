---
service: "ugc-async"
title: "Goods Survey Creation from Teradata"
generated: "2026-03-03"
type: flow
flow_name: "goods-survey-creation-teradata"
flow_type: scheduled
trigger: "Quartz scheduler fires GoodsSurveyCreationJob or GoodsInstantSurveyCreationJob"
participants:
  - "continuumUgcAsyncService"
  - "ugcTeradataWarehouse_6b9d"
  - "continuumUgcRedisCache"
  - "continuumUgcPostgresDb"
  - "continuumGoodsInventoryService"
architecture_ref: "dynamic-ugc-async-goods-survey-creation"
---

# Goods Survey Creation from Teradata

## Summary

For Goods-type deals (physical product purchases), order redemption data is not available in real time through MBus but is instead batch-exported to a Teradata data warehouse. ugc-async runs `GoodsSurveyCreationJob` on a Quartz schedule to read new Goods redemption records from Teradata within a time window, evaluate eligibility, and create surveys for eligible orders. A Redis checkpoint tracks the last-processed timestamp to avoid reprocessing. An "instant" variant (`GoodsInstantSurveyCreationJob`) handles near-real-time Goods survey creation for specific sub-categories.

## Trigger

- **Type**: schedule (Quartz job)
- **Source**: Quartz Job Scheduler fires `GoodsSurveyCreationJob` (standard) and `GoodsInstantSurveyCreationJob` (instant) on configured cron intervals
- **Frequency**: Periodic (interval defined in application YAML Quartz config); time window = from Redis checkpoint to (now minus 36 hours) for standard job

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| UGC Async Service — Quartz Scheduler | Fires batch job on schedule | `continuumUgcAsyncService` |
| UGC Async Service — GoodsSurveyCreationJob | Orchestrates Teradata query, survey creation, and checkpoint update | `continuumUgcAsyncService` |
| UGC Async Service — GoodsTeradataSurveyCreationFactory | Builds and executes Teradata queries via `GoodsSurveyQuery` | `continuumUgcAsyncService` |
| UGC Redis Cache | Stores and retrieves the `berlinGoodsRedemptionImport` job checkpoint | `continuumUgcRedisCache` |
| UGC Teradata Warehouse | Source of Goods redemption records | `ugcTeradataWarehouse_6b9d` |
| Goods Inventory Service | Validates goods inventory state for survey eligibility | `continuumGoodsInventoryService` |
| UGC Postgres | Persists new survey records | `continuumUgcPostgresDb` |

## Steps

1. **Quartz fires GoodsSurveyCreationJob**: Job is triggered by Quartz scheduler; `@DisallowConcurrentExecution` prevents overlapping runs
   - From: Quartz Scheduler
   - To: `GoodsSurveyCreationJob`
   - Protocol: direct (in-process)

2. **Reads last-processed timestamp from Redis**: `getStartTime("berlinGoodsRedemptionImport")` fetches the checkpoint epoch milliseconds from Redis cache
   - From: `continuumUgcAsyncService`
   - To: `continuumUgcRedisCache`
   - Protocol: Redis (Jedis)

3. **Computes query time window**: End time = current time minus 36 hours (`AsyncConstants.HALF_DAY * 3`); start time = Redis checkpoint value
   - From: `GoodsSurveyCreationJob`
   - To: `GoodsTeradataSurveyCreationFactory`
   - Protocol: direct (in-process)

4. **Builds Teradata query**: `GoodsTeradataSurveyProcessor` / `GoodsSurveyQuery` constructs the Goods redemption SELECT query using `AppDomainIdConfig` (domain-to-app-ID mappings) and the time window. If `updatedGoodsSurveyCreationQuery` flag is true, uses the updated query variant
   - From: `GoodsSurveyCreationJob`
   - To: `ugcTeradataWarehouse_6b9d`
   - Protocol: JDBC (Teradata)

5. **Executes Teradata query and processes results**: `getResults()` in `AbstractTeraDataSurveyCreationJob` iterates over the result set; each row represents a Goods redemption eligible for survey creation
   - From: `continuumUgcAsyncService`
   - To: `ugcTeradataWarehouse_6b9d`
   - Protocol: JDBC (Teradata)

6. **Validates goods inventory state**: For each candidate, calls Goods Inventory Service to confirm inventory status is eligible
   - From: `continuumUgcAsyncService`
   - To: `continuumGoodsInventoryService`
   - Protocol: REST (Retrofit)

7. **Creates survey records**: `SurveyService.createSurvey()` persists each eligible Goods survey to `continuumUgcPostgresDb`
   - From: `continuumUgcAsyncService`
   - To: `continuumUgcPostgresDb`
   - Protocol: JDBI / SQL

8. **Advances Redis checkpoint**: After successful batch processing, updates `berlinGoodsRedemptionImport` in Redis to the end-of-window timestamp so the next job run starts from where this run ended
   - From: `continuumUgcAsyncService`
   - To: `continuumUgcRedisCache`
   - Protocol: Redis (Jedis)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Teradata connection failure | Exception propagates from JDBC; job execution halts | Redis checkpoint not advanced; next run will retry the same window |
| Goods Inventory Service unavailable | Exception caught per row; survey not created for that row | Affected orders are not surveyed; no automatic retry per row |
| Postgres write failure | Exception caught; survey not persisted | Row skipped; next batch run may or may not re-encounter the same record (depends on Teradata query window) |
| Redis checkpoint read failure | `getStartTime` returns fallback value or throws | Job may reprocess previously processed records; `SurveyExistsChecker` prevents actual duplicate surveys |
| Concurrent job execution | `@DisallowConcurrentExecution` Quartz annotation | Second trigger is skipped; no overlapping Teradata reads |

## Sequence Diagram

```
Quartz Scheduler -> GoodsSurveyCreationJob: Fire job (scheduled)
GoodsSurveyCreationJob -> Redis Cache: GET berlinGoodsRedemptionImport (checkpoint)
Redis Cache --> GoodsSurveyCreationJob: startTime epoch millis
GoodsSurveyCreationJob -> Teradata Warehouse: JDBC SELECT Goods redemptions (startTime to now-36h)
Teradata Warehouse --> GoodsSurveyCreationJob: Redemption result set rows
loop for each eligible row
  GoodsSurveyCreationJob -> Goods Inventory Service: Validate inventory state (REST)
  Goods Inventory Service --> GoodsSurveyCreationJob: Inventory status
  GoodsSurveyCreationJob -> UGC Postgres: INSERT survey record (JDBI)
end
GoodsSurveyCreationJob -> Redis Cache: SET berlinGoodsRedemptionImport endTime
```

## Related

- Architecture dynamic view: `dynamic-ugc-async-goods-survey-creation`
- Related flows: [Survey Creation from MBus Event](survey-creation-mbus.md), [Survey Sending — Notification Dispatch](survey-sending-notification.md)
