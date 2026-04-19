---
service: "deal-performance-bucketing-and-export-pipelines"
title: "Deal Performance DB Cleanup"
generated: "2026-03-03"
type: flow
flow_name: "deal-performance-db-cleanup"
flow_type: scheduled
trigger: "Airflow DAG task DpsDbCleanerTask (scheduled, runs periodically after export tasks)"
participants:
  - "continuumDealPerformanceDataPipelines"
  - "continuumDealPerformancePostgres"
  - "influxDb"
architecture_ref: "dynamic-continuumDealPerformanceDataPipelines"
---

# Deal Performance DB Cleanup

## Summary

The Deal Performance DB Cleanup flow removes stale rows from the `deal_performance_hourly` and `deal_performance_daily` PostgreSQL tables, as well as their corresponding batch tracking tables, based on a specified retention date. Deletions are performed in small batches with a sleep interval to avoid overwhelming the database. The cleaner runs as a standalone Java application (no Apache Beam pipeline) and publishes deletion metrics to Wavefront. This ensures the database does not grow unboundedly while the service operates idempotently on historical data.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow DAG task `DpsDbCleanerTask` on `relevance-airflow`
- **Frequency**: Scheduled periodically (typically daily); triggered with `--date=<cutoff_date>` and `--minDaysToKeep=<N>` arguments

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DealPerformanceDBCleaner | Orchestrates deletion logic; entry point (`main` method) | `continuumDealPerformanceDataPipelines` |
| HourlyBatchDAO / DailyBatchDAO | Deletes stale batch tracking rows created on or before the cutoff date | `continuumDealPerformanceDataPipelines` / `continuumDealPerformancePostgres` |
| DealPerformanceHourlyDAO / DealPerformanceDailyDAO | Deletes stale deal performance rows in batches | `continuumDealPerformanceDataPipelines` / `continuumDealPerformancePostgres` |
| MetricsPublisher | Publishes deletion count metrics and timing to Wavefront | `continuumDealPerformanceDataPipelines` / `influxDb` |

## Steps

1. **Validate cutoff date**: Checks that the requested `--date` is not more recent than `(today - minDaysToKeep)`. Throws `IllegalArgumentException` if the date would delete data within the minimum retention window.
   - From: `DealPerformanceDBCleaner`
   - To: `DealPerformanceDBCleaner`
   - Protocol: direct (validation logic)

2. **Initialize JDBC connection**: `JDBIFactory` creates a JDBI/JDBC connection to PostgreSQL using credentials from the config file (overridable via `--dbPassword`).
   - From: `DealPerformanceDBCleaner`
   - To: `continuumDealPerformancePostgres`
   - Protocol: JDBC (PostgreSQL port 5432)

3. **Delete stale deal performance rows (batched)**: `dealPerformanceDAO.deleteRowsCreatedOnOrBefore(date, DELETE_LIMIT=3)` is called in a loop. Each iteration deletes up to 3 rows created on or before the cutoff date. After each batch, a 5-second sleep is applied to reduce DB load. Continues until no rows remain.
   - From: `DealPerformanceDBCleaner`
   - To: `continuumDealPerformancePostgres`
   - Protocol: JDBC

4. **Publish deletion progress metrics**: After each delete batch, `metricsPublisher.counter("dealPerformanceDelete.{granularity}", numDeleted)` and `metricsPublisher.timer("deleteLimit.{granularity}", timeTaken)` are emitted.
   - From: `DealPerformanceDBCleaner`
   - To: Wavefront (`influxDb`)
   - Protocol: HTTP (Telegraf)

5. **Delete stale batch tracking rows**: Once all deal performance rows are deleted, `batchDAO.deleteRowsCreatedOnOrBefore(date)` removes the corresponding batch ID tracking records.
   - From: `DealPerformanceDBCleaner`
   - To: `continuumDealPerformancePostgres`
   - Protocol: JDBC

6. **Publish final metrics**: Total deleted deal performance row count and batch row count are logged. `metricsPublisher.counter("BatchDelete.{granularity}", numDeletedBatch)` is emitted.
   - From: `DealPerformanceDBCleaner`
   - To: Wavefront (`influxDb`)
   - Protocol: HTTP (Telegraf)

7. **Exit**: On success, `System.exit(0)`. On exception, error is logged and `System.exit(1)` is called, causing Airflow to mark the task failed.
   - From: `DealPerformanceDBCleaner`
   - Protocol: OS process exit code

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Date within minimum retention window | `IllegalArgumentException` thrown at startup | Process exits with code 1; Airflow marks task failed |
| JDBC connection failure | Exception caught in `main`; error logged | Process exits with code 1; Airflow retry triggered; PagerDuty alert via `darwin-offline` |
| PostgreSQL delete timeout / deadlock | Exception caught and logged | Process exits with code 1; manual re-run required |
| No rows to delete | Loop exits immediately; zero metrics published | Success; no alert |

## Sequence Diagram

```
Airflow -> DealPerformanceDBCleaner: invoke with --date=<cutoff> --minDaysToKeep=<N> --config=<file>
DealPerformanceDBCleaner -> DealPerformanceDBCleaner: Validate date <= (today - minDaysToKeep)
DealPerformanceDBCleaner -> continuumDealPerformancePostgres: JDBC connect
DealPerformanceDBCleaner -> continuumDealPerformancePostgres: DELETE deal_performance_hourly/daily WHERE created_at <= cutoff LIMIT 3 (loop)
continuumDealPerformancePostgres --> DealPerformanceDBCleaner: numDeleted (per batch)
DealPerformanceDBCleaner -> Wavefront (influxDb): Publish counter + timer metrics
DealPerformanceDBCleaner -> DealPerformanceDBCleaner: sleep 5s between batches
DealPerformanceDBCleaner -> continuumDealPerformancePostgres: DELETE deal_performance_hourly/daily_batch WHERE created_at <= cutoff
continuumDealPerformancePostgres --> DealPerformanceDBCleaner: numDeletedBatch
DealPerformanceDBCleaner -> Wavefront (influxDb): Publish BatchDelete counter
```

## Related

- Architecture dynamic view: `dynamic-continuumDealPerformanceDataPipelines`
- Related flows: [Deal Performance DB Export](deal-performance-db-export.md)
- Data stores: [Data Stores](../data-stores.md)
