---
service: "emailsearch-dataloader"
title: "Metrics Export to Hive"
generated: "2026-03-03"
type: flow
flow_name: "metrics-export-to-hive"
flow_type: scheduled
trigger: "Quartz scheduler fires MetricsExportJob on configured cron schedule"
participants:
  - "continuumEmailSearchDataloaderService"
  - "continuumEmailSearchPostgresDb"
  - "hiveWarehouse"
architecture_ref: "emailsearch_dataloader_components"
---

# Metrics Export to Hive

## Summary

The Metrics Export to Hive flow is a scheduled batch job that incrementally exports campaign statistical significance metrics from the Email Search PostgreSQL database to the Hive analytics warehouse. The export uses an intermediate staging table (text file) before merging into a partitioned, ORC/Snappy-compressed external table. The incremental boundary is determined by querying the latest timestamp already in Hive. This flow makes campaign decision outcome data available to the analytics and data engineering teams for reporting.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler fires `MetricsExportJob` on a configured cron schedule (defined in runtime YAML `quartz` config block)
- **Frequency**: Configured per deployment; typically runs periodically (e.g., hourly or multiple times per day)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Schedulers | Initiates the export job | `continuumEmailSearchDataloaderService` |
| Metrics Export Service | Orchestrates the incremental export logic | `continuumEmailSearchDataloaderService` |
| Hive Query Executor | Executes DDL and DML statements against Hive | `continuumEmailSearchDataloaderService` |
| DAO Layer (StatSigMetricsDao) | Reads stat-sig metrics from PostgreSQL | `continuumEmailSearchDataloaderService` |
| Email Search Postgres | Source of statistical significance metrics data | `continuumEmailSearchPostgresDb` |
| Hive Warehouse | Analytics destination | `hiveWarehouse` |

## Steps

1. **Quartz fires MetricsExportJob**: The Quartz scheduler invokes `MetricsExportJob.run()` with a `MetricsExportConfig` (includes `tableSuffix` for environment-specific table naming).
   - From: `quartzSchedulers`
   - To: `MetricsExportJob`
   - Protocol: in-process (JVM)

2. **Query latest Hive timestamp**: `HiveQueryExecutor` queries the Hive external table (`campaign_stat_sig_metrics<suffix>`) to find the maximum `created_at` timestamp already loaded. This determines the incremental window for the current export.
   - From: `hiveQueryExecutor`
   - To: `hiveWarehouse`
   - Protocol: Hive JDBC

3. **Read incremental metrics from Postgres**: `StatSigMetricsDao.findStatSigMetrics(latestTimestamp)` reads all `campaign_stat_sig_metrics` rows from PostgreSQL with `created_at` newer than the Hive latest timestamp. The count is emitted as a metric.
   - From: `daoLayer_EmaDat` (`StatSigMetricsDao`)
   - To: `continuumEmailSearchPostgresDb`
   - Protocol: JDBC

4. **Create staging table (if not exists)**: `HiveQueryExecutor` runs `CREATE TABLE IF NOT EXISTS` for the temp text file table (`campaign_stat_sig_metrics_temp<suffix>`) with fields delimited by comma, stored as TEXTFILE.
   - From: `hiveQueryExecutor`
   - To: `hiveWarehouse`
   - Protocol: Hive JDBC

5. **Create external table (if not exists)**: `HiveQueryExecutor` runs `CREATE EXTERNAL TABLE IF NOT EXISTS` for the production table (`campaign_stat_sig_metrics<suffix>`) partitioned by `record_date`, bucketed by `campaign_id` (10 buckets), sorted by `created_at DESC`, stored as ORC with SNAPPY compression.
   - From: `hiveQueryExecutor`
   - To: `hiveWarehouse`
   - Protocol: Hive JDBC

6. **Insert metrics into staging table**: The metrics rows are formatted as SQL value tuples via string template and inserted into the temp TEXTFILE table with an `INSERT INTO ... VALUES` statement.
   - From: `hiveQueryExecutor`
   - To: `hiveWarehouse` (staging table)
   - Protocol: Hive JDBC

7. **Insert-select from staging into partitioned ORC table**: An `INSERT INTO ... partition(record_date) SELECT ...` statement reads from the temp table and writes to the external ORC table, setting `record_date = current_timestamp()`. Rows are ordered by `created_at DESC`.
   - From: `hiveQueryExecutor`
   - To: `hiveWarehouse` (external table)
   - Protocol: Hive JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `MetricsExportConfig` is null | `failedJobCount` counter incremented; `JobExecutionException` thrown | Job fails; Quartz logs failure; next scheduled run retries from scratch |
| Hive unavailable (latest timestamp query fails) | Not documented in codebase; HikariCP connection timeout (default 30s) | Job fails; no data is written; next run retries |
| No new records in Postgres | Records count metric emitted as 0; no INSERT executed | Job completes successfully with no-op |
| Hive INSERT fails | Not documented in codebase | Partial data may be written to staging table; next run may re-insert duplicates (no deduplication mechanism observed) |
| Postgres read failure | JDBC exception propagates | Job fails; no data written to Hive |

## Sequence Diagram

```
QuartzScheduler -> MetricsExportJob: fire(MetricsExportConfig)
MetricsExportJob -> HiveQueryExecutor: getLatestTimeStampFromHive(tableSuffix)
HiveQueryExecutor -> HiveWarehouse: SELECT MAX(created_at) FROM campaign_stat_sig_metrics<suffix>
HiveWarehouse --> HiveQueryExecutor: latestTimestamp
MetricsExportJob -> StatSigMetricsDao: findStatSigMetrics(latestTimestamp)
StatSigMetricsDao -> EmailSearchPostgres: SELECT * FROM campaign_stat_sig_metrics WHERE created_at > latestTimestamp
EmailSearchPostgres --> StatSigMetricsDao: List<CampaignStatSigMetrics>
MetricsExportJob -> HiveQueryExecutor: createTempTable(tableSuffix)
HiveQueryExecutor -> HiveWarehouse: CREATE TABLE IF NOT EXISTS campaign_stat_sig_metrics_temp<suffix> (TEXTFILE)
MetricsExportJob -> HiveQueryExecutor: createExternalTable(tableSuffix)
HiveQueryExecutor -> HiveWarehouse: CREATE EXTERNAL TABLE IF NOT EXISTS campaign_stat_sig_metrics<suffix> (ORC/Snappy, partitioned)
MetricsExportJob -> HiveQueryExecutor: insertMetrics(metricsString, tableSuffix)
HiveQueryExecutor -> HiveWarehouse: INSERT INTO campaign_stat_sig_metrics_temp<suffix> VALUES (...)
MetricsExportJob -> HiveQueryExecutor: insertSelectMetrics(tableSuffix)
HiveQueryExecutor -> HiveWarehouse: INSERT INTO campaign_stat_sig_metrics<suffix> partition(record_date) SELECT ... FROM campaign_stat_sig_metrics_temp<suffix>
```

## Related

- Architecture component view: `emailsearch_dataloader_components`
- Related flows: [Campaign Decision Job](campaign-decision-job.md)
