---
service: "deal-performance-bucketing-and-export-pipelines"
title: "Deal Performance DB Export"
generated: "2026-03-03"
type: flow
flow_name: "deal-performance-db-export"
flow_type: batch
trigger: "Airflow DAG task DpsDbExportTask (runs after DpsUserDealBucketingTask completes)"
participants:
  - "continuumDealPerformanceDataPipelines"
  - "hdfsCluster"
  - "continuumDealPerformancePostgres"
architecture_ref: "dynamic-continuumDealPerformanceDataPipelines"
---

# Deal Performance DB Export

## Summary

The Deal Performance DB Export flow reads the bucketed `AvroDealPerformance` Avro files produced by the [Deal Event Bucketing](deal-event-bucketing.md) pipeline from GCS, filters out impression events, aggregates counts by time granularity (hourly or daily), and writes the aggregated records to the GDS-managed PostgreSQL database. It also tracks batch IDs for idempotency and removes stale rows from previous batches. This enables the `deal-performance-api-v2` REST API to serve low-latency deal performance queries.

## Trigger

- **Type**: schedule (depends on Airflow DAG ordering)
- **Source**: Apache Airflow DAG task `DpsDbExportTask` — runs after `DpsUserDealBucketingTask` completes successfully
- **Frequency**: Hourly (for hourly granularity); daily (for daily granularity); triggered per event_source and date-hour combination

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DealPerformanceExportPipeline | Orchestrates read, aggregate, and write steps; entry point (`main` method) | `continuumDealPerformanceDataPipelines` |
| DealPerformanceHDFSReadTransform | Reads bucketed AvroDealPerformance Avro files from GCS | `continuumDealPerformanceDataPipelines` / `hdfsCluster` |
| TimeBasedDealPerformanceGrouping | Keys records by time granularity (hourly or daily time bucket) | `continuumDealPerformanceDataPipelines` |
| DealPerformanceTimeBasedAggregationDoFn | Aggregates counts across bucket dimensions per time granularity | `continuumDealPerformanceDataPipelines` |
| DealOptionIdGrouping | Extracts deal option ID grouping key for deal option performance | `continuumDealPerformanceDataPipelines` |
| DealOptionPerformanceGrouping | Aggregates purchase and activation counts per deal option | `continuumDealPerformanceDataPipelines` |
| DealPerformanceJDBCWriteTransform | Writes aggregated deal performance rows to PostgreSQL via JDBC | `continuumDealPerformanceDataPipelines` / `continuumDealPerformancePostgres` |
| DealOptionPerformanceJDBCWriteTransform | Writes aggregated deal option performance rows to PostgreSQL via JDBC | `continuumDealPerformanceDataPipelines` / `continuumDealPerformancePostgres` |
| HourlyBatchDAO / DailyBatchDAO | Upserts batch ID record to track the current export run | `continuumDealPerformanceDataPipelines` / `continuumDealPerformancePostgres` |
| DealPerformanceHourlyDAO / DealPerformanceDailyDAO | Deletes rows from older batches for the same date-hour-event_source | `continuumDealPerformanceDataPipelines` / `continuumDealPerformancePostgres` |

## Steps

1. **Resolve input GCS path**: Based on `--timeGranularity`, `--eventSource`, `--date`, and `--hour` arguments, constructs the GCS input path: `{inputPathFormat}/{event_source}/date={date}/hour={hour}` (hourly) or `{inputPathFormat}/{event_source}/date={date}` (daily).
   - From: `DealPerformanceExportPipeline`
   - To: `DealPerformanceExportPipeline`
   - Protocol: direct (string computation)

2. **Read bucketed Avro data**: `DealPerformanceHDFSReadTransform` reads all `AvroDealPerformance` Avro records from the computed GCS path.
   - From: GCS (`hdfsCluster`)
   - To: `DealPerformanceExportPipeline`
   - Protocol: GCS Hadoop FileSystem API (Avro)

3. **Filter impression events**: `Filter.by(input -> input.getEventType() != EventType.dealImpression)` removes impression records to reduce DB write volume (only dealView, dealPurchase, cloClaims are exported to PostgreSQL).
   - From/To: `DealPerformanceExportPipeline`
   - Protocol: direct (in-process Beam)

4. **Aggregate deal performance by time granularity**: `TimeBasedDealPerformanceGrouping` keys records by time bucket (hourly or daily). `DealPerformanceTimeBasedAggregationDoFn` sums counts across bucket combinations for each time bucket.
   - From/To: `DealPerformanceExportPipeline`
   - Protocol: direct (in-process Beam `GroupByKey`)

5. **Write deal performance rows to PostgreSQL**: `DealPerformanceJDBCWriteTransform` calls `insert_or_ignore_deal_performance_hourly` / `insert_or_ignore_deal_performance_daily` stored procedure. Deduplication is enforced by unique constraint on `(deal_id, time_bucket, dedup_hash)`.
   - From: `DealPerformanceExportPipeline`
   - To: `continuumDealPerformancePostgres`
   - Protocol: JDBC (PostgreSQL port 5432)

6. **Aggregate deal option performance**: Separately, `DealOptionPerformanceFilter.isAllowed()` filters to purchase events only, `DealOptionIdGrouping` keys by `deal_id + deal_option_id`, and `DealOptionPerformanceGrouping` sums purchase and activation counts per deal option per brand (groupon, livingsocial).
   - From/To: `DealPerformanceExportPipeline`
   - Protocol: direct (in-process Beam)

7. **Write deal option performance rows to PostgreSQL**: `DealOptionPerformanceJDBCWriteTransform` inserts aggregated `AvroDealOptionPerformance` records (dealId, dealOptionId, purchasesCount, activationsCount, brand).
   - From: `DealPerformanceExportPipeline`
   - To: `continuumDealPerformancePostgres`
   - Protocol: JDBC (PostgreSQL port 5432)

8. **Upsert batch ID**: `batchDAO.upsertHourlyBatch()` / `upsertDailyBatch()` records the current `batchId` (UUID) for the event_source + date + hour combination in the batch tracking table.
   - From: `DealPerformanceExportPipeline`
   - To: `continuumDealPerformancePostgres`
   - Protocol: JDBC

9. **Delete stale rows from previous batches**: `dealPerformanceDAO.deleteRowsNotMatchingBatchId()` iterates in batches (`DELETE_LIMIT: 3`) deleting rows for the same event_source/date/hour that do not match the current batch ID. Same operation is applied to deal option rows.
   - From: `DealPerformanceExportPipeline`
   - To: `continuumDealPerformancePostgres`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GCS path not found | `DealPerformanceHDFSReadTransform` fails; Beam pipeline fails | Airflow marks DpsDbExportTask failed; retry triggered |
| JDBC write fails (PostgreSQL down) | Beam pipeline fails with exception; logged with event source, date, hour, batch ID context | Airflow retry; alert via `darwin-offline` |
| Unique constraint violation on insert | `insert_or_ignore` stored procedure catches `unique_violation` and returns `false`; no error raised | Duplicate row silently skipped (idempotent) |
| No records in GCS path | Pipeline runs successfully with zero inserts | No error; batch ID still upserted |

## Sequence Diagram

```
Airflow -> DealPerformanceExportPipeline: spark-submit with --date --hour --eventSource --timeGranularity --config
DealPerformanceExportPipeline -> GCS (hdfsCluster): Read AvroDealPerformance Avro files from partitioned path
GCS (hdfsCluster) --> DealPerformanceExportPipeline: AvroDealPerformance PCollection
DealPerformanceExportPipeline -> DealPerformanceExportPipeline: Filter out dealImpression events
DealPerformanceExportPipeline -> DealPerformanceExportPipeline: Group by time bucket + aggregate counts
DealPerformanceExportPipeline -> continuumDealPerformancePostgres: INSERT deal_performance_hourly rows (insert_or_ignore)
DealPerformanceExportPipeline -> DealPerformanceExportPipeline: Filter purchases + group by deal_id+deal_option_id
DealPerformanceExportPipeline -> continuumDealPerformancePostgres: INSERT deal_option_performance rows
DealPerformanceExportPipeline -> continuumDealPerformancePostgres: UPSERT batch_id for event_source/date/hour
DealPerformanceExportPipeline -> continuumDealPerformancePostgres: DELETE stale rows not matching current batch_id
continuumDealPerformancePostgres --> DealPerformanceExportPipeline: Delete complete
```

## Related

- Architecture dynamic view: `dynamic-continuumDealPerformanceDataPipelines`
- Related flows: [Deal Event Bucketing](deal-event-bucketing.md), [Deal Performance DB Cleanup](deal-performance-db-cleanup.md)
- Downstream consumer: `deal-performance-api-v2` reads from `continuumDealPerformancePostgres`
