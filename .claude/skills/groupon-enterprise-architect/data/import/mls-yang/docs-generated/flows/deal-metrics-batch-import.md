---
service: "mls-yang"
title: "Deal Metrics Batch Import"
generated: "2026-03-03"
type: flow
flow_name: "deal-metrics-batch-import"
flow_type: scheduled
trigger: "Quartz cron trigger — every 3 hours and daily retro runs"
participants:
  - "smaBatch_quartzScheduler"
  - "smaBatch_importWorkers"
  - "smaBatch_persistence"
  - "continuumDealCatalogService"
  - "mlsYangDb"
architecture_ref: "dynamic-yang-batch-import-flow"
---

# Deal Metrics Batch Import

## Summary

This flow imports deal engagement metrics from the Janus/Hive data warehouse into the Yang deal metrics store. Six metric types are imported in parallel by separate Quartz jobs: deal shares, email clicks, email impressions, web/mobile clicks, web/mobile impressions, and merchant website referrals. Each job queries the Janus Hive table for a specific event date window, resolves deal permalinks to deal UUIDs via the Deal Catalog API (with in-memory caching), and persists the metric counts to `mlsYangDb`. Each job runs on a 3-hour schedule plus a daily retro run covering the past 3-8 days to capture late-arriving data.

## Trigger

- **Type**: schedule
- **Source**: Quartz clustered scheduler backed by `mlsYangDb` (PostgreSQL JobStore)
- **Frequency**: Every 3 hours per metric type (staggered start times); plus one or two daily retro-scheduled runs per metric type

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler | Fires the import job at the configured cron time | `smaBatch_quartzScheduler` |
| Import Worker (e.g. `JanusDealSharesImportExecutor`) | Executes Hive query, coordinates data enrichment and persistence | `smaBatch_importWorkers` |
| `DealMetricsService` | Resolves deal permalinks to UUIDs and persists metrics | `smaBatch_importWorkers` (service layer) |
| Deal Catalog API | Provides deal UUID for a given permalink | `continuumDealCatalogService` |
| Batch Persistence Layer (`DealMetricsDao`) | Writes metric rows to `mlsYangDb` | `smaBatch_persistence` |
| Yang Primary DB | Stores imported deal metrics | `mlsYangDb` |

## Steps

1. **Fire scheduled trigger**: Quartz scheduler fires the cron trigger for a specific metric import job (e.g. `Every3HoursDealSharesImportTrigger` at `0 0 2/3 ? * * *` UTC). Job data includes `import_strategy` (`SCHEDULED` or `RETRO_SCHEDULED`) and optionally `days_in_past`.
   - From: `smaBatch_quartzScheduler`
   - To: `smaBatch_importWorkers`
   - Protocol: In-process (Quartz job execution)

2. **Determine processing date range**: `ImportStrategyFactory` resolves the import strategy to a date or date range:
   - `SCHEDULED`: current date
   - `RETRO_SCHEDULED`: current date minus `days_in_past` (3 or 8 days)
   - `MANUAL`: operator-specified date
   - From: `smaBatch_importWorkers`
   - To: `smaBatch_importWorkers` (internal strategy resolution)
   - Protocol: In-process

3. **Execute Hive query**: The executor queries the Janus Hive table (`grp_gdoop_pde.junohourly`) via JDBC with the processing date and metric-specific SQL. For deal shares, the query selects `dealPermalink`, `COUNT(1)`, and `platform` for `event='dealSharingClick'` on the target `eventdate`. Batch size is 10,000 rows.
   - From: `smaBatch_importWorkers`
   - To: Janus Hive (external)
   - Protocol: JDBC / Hive2 (HTTPS, HTTP transport mode)

4. **For each row: resolve deal permalink to UUID**: `DealMetricsService.getDealUUIDForPermalink` checks the Guava in-memory cache (`permalinkToDealUUIDCache`, max 500,000 entries, 1-day TTL). On cache miss, calls the Deal Catalog REST API.
   - From: `smaBatch_importWorkers`
   - To: `continuumDealCatalogService` (on cache miss)
   - Protocol: REST (HTTP, Retrofit, RxJava3)

5. **Retry on Deal Catalog 5xx**: If the Deal Catalog returns a server error, `RetryWithDelay` retries up to 6 times with 1,000ms delay. On 4xx, the permalink is silently skipped.
   - From: `smaBatch_importWorkers`
   - To: `continuumDealCatalogService`
   - Protocol: REST (HTTP)

6. **Resolve metric type**: The executor determines the `MetricType` enum value from the row data (e.g. for deal shares: `WEB_DEAL_SHARES` if `platform='web'`, else `MOBILE_DEAL_SHARES`).
   - From: `smaBatch_importWorkers`
   - To: `smaBatch_importWorkers` (internal)
   - Protocol: In-process

7. **Persist metrics**: `DealMetricsService.update` calls `DealMetricsDao.persist` for each `MetricType -> Map<UUID, Long>` entry. Execution is parallelised via RxJava3 `Flowable.subscribeOn(Schedulers.io())`.
   - From: `smaBatch_importWorkers`
   - To: `smaBatch_persistence`
   - Protocol: In-process (JDBI)

8. **Write to yangDb**: `DealMetricsDao` executes bulk SQL upserts into the deal metrics table in `mlsYangDb`.
   - From: `smaBatch_persistence`
   - To: `mlsYangDb`
   - Protocol: JDBC

9. **Log completion**: `DealMetricsService` logs a steno event with `currentlyProcessingDay`, `metricType`, `isSuccessful`, `metricsCount`, and `persistenceTimeInMillis`.
   - From: `smaBatch_importWorkers`
   - To: logging (steno)
   - Protocol: In-process

10. **Publish feedback command**: On job completion, the `smaBatch_feedbackEmitter` publishes a feedback command to `jms.queue.mls.batchCommands` (see [Batch Feedback Publication](batch-feedback-publication.md)).

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hive connection failure | JDBC exception; Quartz job fails for this run | Job is rescheduled by Quartz on next trigger; retro runs fill gap |
| Quartz job misfire | Misfire threshold 300,000ms; Quartz applies misfire instruction | Job fires as soon as scheduler recovers |
| Deal Catalog 5xx | `RetryWithDelay` — up to 6 retries with 1s delay | If all retries fail, RxJava error propagates; deal metric not saved for that permalink |
| Deal Catalog 4xx | `Maybe.empty()` returned; permalink skipped silently | Metric not saved for that deal; no retry |
| Invalid permalink (regex mismatch) | `Maybe.empty()` returned | Permalink skipped; logged at DEBUG level |
| Metrics persist failure | `DealMetricsDao.persist` returns `false`; logged | Partial import; retro run covers the gap |

## Sequence Diagram

```
QuartzScheduler -> JanusDealSharesImportExecutor: execute(jobContext)
JanusDealSharesImportExecutor -> ImportStrategyFactory: resolveStrategy(import_strategy, days_in_past)
ImportStrategyFactory --> JanusDealSharesImportExecutor: processingDate
JanusDealSharesImportExecutor -> JanusHive: JDBC query(DEAL_SHARES_SQL, eventdate=processingDate)
JanusHive --> JanusDealSharesImportExecutor: rows[dealPermalink, count, platform]
JanusDealSharesImportExecutor -> DealMetricsService: getDealUUIDForPermalink(permalink)
DealMetricsService -> permalinkCache: get(permalink)
permalinkCache --> DealMetricsService: null (miss)
DealMetricsService -> DealCatalogAPI: GET /deals?permalink=...
DealCatalogAPI --> DealMetricsService: {deal: {id: uuid}}
DealMetricsService -> permalinkCache: put(permalink, uuid)
DealMetricsService -> DealMetricsDao: persist(date, metricType, {uuid->count})
DealMetricsDao -> mlsYangDb: SQL UPSERT deal_metrics
mlsYangDb --> DealMetricsDao: OK
```

## Related

- Architecture dynamic view: `dynamic-yang-batch-import-flow`
- Related flows: [Batch Feedback Publication](batch-feedback-publication.md)
- Configuration: `janusImportsConfiguration`, `dealCatalogLocalConfig`, `dealCatalogClientConfig`, `hiveDataSource`
- Data Stores: [Data Stores](../data-stores.md)
