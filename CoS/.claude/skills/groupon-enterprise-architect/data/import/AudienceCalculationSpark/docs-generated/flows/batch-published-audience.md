---
service: "AudienceCalculationSpark"
title: "Batch Published Audience"
generated: "2026-03-03"
type: flow
flow_name: "batch-published-audience"
flow_type: batch
trigger: "spark-submit invocation by continuumAudienceManagementService"
participants:
  - "continuumAudienceManagementService"
  - "continuumAudienceCalculationSpark"
  - "batchPublishedAudienceFlow"
  - "amsClient"
  - "queryExecution"
  - "audiencecalculationspark_fileExport"
  - "hiveWarehouse"
  - "hdfsStorage"
architecture_ref: "components-continuumAudienceCalculationSpark"
---

# Batch Published Audience

## Summary

The Batch Published Audience flow publishes multiple PAs within a single Spark job run by sharing a common cached base DataFrame. AMS provides a list of PA IDs and a base SQL query; the job caches the query result once as a Spark temp view, then iterates over each PA ID — fetching that PA's configuration from AMS, creating its Hive table, generating CSV and feedback files, collecting deal-bucket metadata, and reporting success or failure per PA. This optimisation avoids repeating the expensive base query for each individual PA.

## Trigger

- **Type**: api-call (spark-submit)
- **Source**: `continuumAudienceManagementService` submits the JAR with `--class BatchPublishedAudience.Main` and a JSON payload argument
- **Frequency**: On-demand — triggered per batch PA workflow execution initiated by AMS

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AudienceManagementService | Triggers job; provides per-PA spark inputs; receives per-PA results | `continuumAudienceManagementService` |
| AudienceCalculationSpark | Spark job runner | `continuumAudienceCalculationSpark` |
| Batch Published Audience Flow | Batch orchestration logic | `batchPublishedAudienceFlow` |
| AMS Client Utility | Fetches PA inputs and reports per-PA results | `amsClient` |
| Query Execution Utility | Executes base and PA SQL | `queryExecution` |
| File Export Utility | Creates PA CSV, feedback CSV, deal-bucket JSON | `audiencecalculationspark_fileExport` |
| Hive Warehouse | Receives PA segment Hive tables | `hiveWarehouse` |
| HDFS Storage | Receives PA CSV, feedback CSV, deal-bucket JSON | `hdfsStorage` |

## Steps

1. **Receive workflow input**: AMS submits job; `BatchPublishedAudience.Main` parses `BatchPASparkInput` containing `publishedAudienceIds`, `cacheQuery`, `cacheTempViewName`, `logPrefix`, and environment/region.
   - From: `continuumAudienceManagementService`
   - To: `continuumAudienceCalculationSpark`
   - Protocol: spark-submit / YARN

2. **Cache base DataFrame**: Executes `cacheQuery` SQL via `spark.sql(...)`, calls `.cache()`, and registers result as temp view `cacheTempViewName`. Retried on failure.
   - From: `queryExecution`
   - To: `hiveWarehouse`
   - Protocol: Hive SQL

3. **For each `publishedAudienceId` in the batch**:

   a. **Fetch PA spark input from AMS**: Calls `GET /<host>/published-audience/<paId>/spark-input?baseOptimizationTable=USERS_LINK_SAD_OPTIMIZATION_TABLE`. Retried on failure.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

   b. **Mark PA as IN_PROGRESS**: Calls `PUT /<host>/updatePublishedAudienceInProgress/<paId>`. Retried on failure.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

   c. **Build PA DataFrame**: Executes `paSparkInput.getSourceDataFrameCreationQuery` via `spark.sql(...)` and appends a `"default"` segment column. Counts rows.
   - From: `queryExecution`
   - To: `hiveWarehouse` (referencing cached temp view)
   - Protocol: Hive SQL

   d. **Create PA Hive table**: Writes PA DataFrame as Parquet/Snappy overwrite to `<database>.<segmentTableId>`.
   - From: `batchPublishedAudienceFlow`
   - To: `hiveWarehouse`
   - Protocol: Hive SQL (Spark saveAsTable)

   e. **Generate segment CSV**: Exports PA segment table to CSV on HDFS via `PublishedAudienceUtil.createCsv(...)`.
   - From: `audiencecalculationspark_fileExport`
   - To: `hdfsStorage`
   - Protocol: HDFS

   f. **Generate feedback CSV**: Creates EDW feedback CSV from PA DataFrame via `PublishedAudienceUtil.createFeedbackCsv(...)`.
   - From: `audiencecalculationspark_fileExport`
   - To: `hdfsStorage`
   - Protocol: HDFS

   g. **Collect deal buckets**: Checks for deal-bucket columns and writes `pa_<paId>_dealbuckets.json` if present.
   - From: `audiencecalculationspark_fileExport`
   - To: `hdfsStorage`
   - Protocol: HDFS

   h. **Report PA result**: Posts `SWF_RESULT.SUCCESSFUL` with `{"default": count}` segment counts to AMS `POST /<host>/updatePublicationResults`. On exception, reports FAILED.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Base cache query failure | Retry; if exhausted, job fails before processing any PA | No PAs processed |
| Fetch PA input failure | Retry; if exhausted, that PA reports FAILED | Other PAs continue |
| PA creation exception | Catch, log, call `amsUpdateFailureResult` | That PA marked FAILED; batch continues |
| CSV/feedback generation failure | Exception propagates to PA create(); PA marked FAILED | Batch continues |

## Sequence Diagram

```
AMS -> AudienceCalculationSpark: spark-submit (BatchPublishedAudience.Main, JSON input)
AudienceCalculationSpark -> HiveWarehouse: cacheQuery -> DataFrame.cache() -> temp view
loop for each publishedAudienceId
  AudienceCalculationSpark -> AMS: GET /published-audience/<paId>/spark-input
  AMS --> AudienceCalculationSpark: PASparkInput
  AudienceCalculationSpark -> AMS: PUT /updatePublishedAudienceInProgress/<paId>
  AudienceCalculationSpark -> HiveWarehouse: sourceDataFrameCreationQuery (joins cached view)
  AudienceCalculationSpark -> HiveWarehouse: saveAsTable(<database>.<segmentTableId>)
  AudienceCalculationSpark -> HDFS: segment CSV, feedback CSV, deal-bucket JSON
  AudienceCalculationSpark -> AMS: POST /updatePublicationResults (SUCCESSFUL/FAILED, count)
end
```

## Related

- Related flows: [Published Audience Publication](published-audience-publication.md)
- Architecture component: `batchPublishedAudienceFlow`
