---
service: "logs-extractor-job"
title: "Hourly Log Extraction and Load"
generated: "2026-03-03"
type: flow
flow_name: "hourly-log-extraction"
flow_type: scheduled
trigger: "Kubernetes CronJob schedule: 1 * * * *"
participants:
  - "continuumLogExtractorJob"
  - "continuumLogExtractorElasticsearch"
  - "continuumLogExtractorBigQuery"
  - "continuumLogExtractorMySQL"
architecture_ref: "dynamic-hourly-log-extraction"
---

# Hourly Log Extraction and Load

## Summary

Every hour at minute 1, the Kubernetes CronJob launches a short-lived pod that runs `node src/index.js`. The job computes a one-hour time window (defaulting to the previous complete hour), fetches all log types from Elasticsearch via the `@groupon/logs-processor` SDK, then uploads transformed records to BigQuery and optionally MySQL. The pod exits with code 0 on success or code 1 on any unhandled error.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob (`cron-job` or `cron-job2`) with schedule `1 * * * *`
- **Frequency**: Hourly (at minute 1 of each hour)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLI Job Runner | Entry point — parses args, builds time range, orchestrates all steps | `continuumLogExtractorJob_cliRunner` |
| Config Loader | Merges environment config files with env vars and CLI args | `continuumLogExtractorJob_configLoader` |
| Log Extractor | Calls logs-processor SDK to fetch logs from Elasticsearch | `continuumLogExtractorJob_logExtractor` |
| Logs Processor Adapter | CommonJS bridge to `@groupon/logs-processor` module | `continuumLogExtractorJob_logsProcessorAdapter` |
| BigQuery Service | Ensures tables, transforms records, uploads batches | `continuumLogExtractorJob_bigQueryService` |
| MySQL Service | Ensures tables, transforms records, inserts batches | `continuumLogExtractorJob_mySQLService` |
| Elasticsearch Cluster | Provides raw log documents for the requested time range and region | `continuumLogExtractorElasticsearch` |
| BigQuery Dataset | Receives transformed and partitioned log tables | `continuumLogExtractorBigQuery` |
| MySQL Database | Receives transformed log tables (when enabled) | `continuumLogExtractorMySQL` |

## Steps

1. **CronJob triggers pod**: Kubernetes creates a pod from the `log-extractor-job` image at minute 1 of each UTC hour.
   - From: Kubernetes scheduler
   - To: `continuumLogExtractorJob`
   - Protocol: Kubernetes CronJob

2. **Load configuration**: CLI Job Runner invokes Config Loader; `config` package merges `default.js` with the environment-specific overlay; env vars and CLI args are applied on top.
   - From: `continuumLogExtractorJob_cliRunner`
   - To: `continuumLogExtractorJob_configLoader`
   - Protocol: in-process

3. **Resolve time range**: If `--start_time` / `--end_time` CLI args are provided and valid, they are used; otherwise the previous complete hour is calculated from UTC wall clock.
   - From: `continuumLogExtractorJob_cliRunner`
   - To: `continuumLogExtractorJob_configLoader` (extraction.getTimeRange)
   - Protocol: in-process

4. **Extract logs from Elasticsearch**: Log Extractor calls `logExtraction.extractLogsForTimeRangeExact({ startTime, endTime, region, debug })` via the Logs Processor Adapter. The SDK returns an object containing `pwa_logs`, `proxy_logs`, `lazlo_logs`, `orders_logs`, and `unique_bcookies` arrays.
   - From: `continuumLogExtractorJob_logExtractor`
   - To: `continuumLogExtractorElasticsearch`
   - Protocol: HTTPS, Elasticsearch REST API

5. **Log extraction summary**: Counts for each log type and unique bCookies are logged to stdout.
   - From: `continuumLogExtractorJob_cliRunner`
   - To: `continuumLogExtractorJob_logging`
   - Protocol: in-process

6. **Upload to BigQuery** (if `ENABLE_BIGQUERY=true`): BigQuery Service ensures all tables exist, then transforms and uploads each non-empty log type. See [BigQuery Table Initialization](bigquery-table-init.md) and [Log Transformation and BigQuery Upload](log-transform-bigquery-upload.md) for details.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: `continuumLogExtractorBigQuery`
   - Protocol: BigQuery API

7. **Upload to MySQL** (if `ENABLE_MYSQL=true`): MySQL Service connects, ensures tables, transforms, and inserts records in transactional batches. See [Log Transformation and BigQuery Upload](log-transform-bigquery-upload.md) for transformation logic.
   - From: `continuumLogExtractorJob_mySQLService`
   - To: `continuumLogExtractorMySQL`
   - Protocol: MySQL protocol

8. **Job completion**: Total execution time is logged; MySQL connection pool is closed; process exits with code 0.
   - From: `continuumLogExtractorJob_cliRunner`
   - To: OS / Kubernetes
   - Protocol: process exit

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid `--start_time` / `--end_time` format | Throws error with descriptive message | Job exits with code 1 before extraction |
| `start_time` not before `end_time` | Throws error | Job exits with code 1 before extraction |
| Invalid `--bq_dataset` or `--mysql_database` name | Throws validation error | Job exits with code 1 before extraction |
| Elasticsearch extraction failure | Caught in `main()` catch block; error and stack trace logged | Job exits with code 1 |
| BigQuery table creation failure | Throws from `ensureTableExists`; caught in `main()` | Job exits with code 1 |
| BigQuery `PartialFailureError` on insert | Failed rows logged as warnings; batch continues | Job continues; some rows skipped |
| MySQL connection failure | Throws from `connect()`; caught in `main()` | Job exits with code 1; no MySQL data written |
| MySQL insert failure | Transaction rolled back; throws; caught in `main()` | Job exits with code 1 |
| Any unhandled error | Caught in `main()` catch; error + stack logged | Job exits with code 1 |

## Sequence Diagram

```
KubernetesCronJob -> LogExtractorJob: Spawn pod (node src/index.js)
LogExtractorJob -> ConfigLoader: Load and merge config
LogExtractorJob -> LogExtractorJob: Resolve time range (previous hour)
LogExtractorJob -> LogsProcessorAdapter: extractLogsForTimeRangeExact(options)
LogsProcessorAdapter -> Elasticsearch: HTTPS query for [pwa_logs, proxy_logs, lazlo_logs, orders_logs]
Elasticsearch --> LogsProcessorAdapter: Raw log documents
LogsProcessorAdapter --> LogExtractorJob: {pwa_logs, proxy_logs, lazlo_logs, orders_logs, unique_bcookies}
LogExtractorJob -> BigQueryService: ensureAllTablesExist()
BigQueryService -> BigQuery: dataset.exists() / createDataset() / table.exists() / createTable()
BigQueryService -> BigQuery: table.insert(batch) x N for each log type
LogExtractorJob -> MySQLService: connect() + uploadLogs() x N (if ENABLE_MYSQL=true)
MySQLService -> MySQL: CREATE TABLE IF NOT EXISTS + INSERT ... VALUES
LogExtractorJob -> KubernetesCronJob: process.exit(0)
```

## Related

- Architecture dynamic view: `dynamic-hourly-log-extraction`
- Related flows: [BigQuery Table Initialization](bigquery-table-init.md), [Log Transformation and BigQuery Upload](log-transform-bigquery-upload.md), [Combined Logs Denormalization](combined-logs-denormalization.md), [BCookie Session Summary Generation](bcookie-summary-generation.md)
