---
service: "AudienceCalculationSpark"
title: "Sourced Audience Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "sourced-audience-ingestion"
flow_type: batch
trigger: "spark-submit invocation by continuumAudienceManagementService"
participants:
  - "continuumAudienceManagementService"
  - "continuumAudienceCalculationSpark"
  - "sourcedAudienceFlow"
  - "amsClient"
  - "queryExecution"
  - "hiveWarehouse"
  - "hdfsStorage"
architecture_ref: "dynamic-sa-to-pa-sourcedAudienceFlow"
---

# Sourced Audience Ingestion

## Summary

The Sourced Audience (SA) Ingestion flow reads audience membership data from an external source (uploaded CSV on HDFS, a Hive query, or a custom SQL expression) and writes the result as a Parquet/Snappy Hive table. After writing, it validates for duplicate primary keys and reports the final record count (or failure) back to AMS. This flow is the first stage of the audience pipeline — the resulting Hive table feeds subsequent Identity Transform and Published Audience flows.

## Trigger

- **Type**: api-call (spark-submit)
- **Source**: `continuumAudienceManagementService` submits the JAR with `--class com.groupon.audienceservice.SourcedAudience.AudienceImporterMain` and a JSON payload argument
- **Frequency**: On-demand — once per SA workflow execution initiated by AMS

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AudienceManagementService | Triggers job; receives lifecycle callbacks | `continuumAudienceManagementService` |
| AudienceCalculationSpark | Spark job runner | `continuumAudienceCalculationSpark` |
| Sourced Audience Flow | SA ingestion logic | `sourcedAudienceFlow` |
| AMS Client Utility | Outbound HTTP callbacks to AMS | `amsClient` |
| Query Execution Utility | Spark SQL / Hive table operations | `queryExecution` |
| Hive Warehouse | Writes output SA Hive table | `hiveWarehouse` |
| HDFS Storage | Provides uploaded source CSV (csv type) | `hdfsStorage` |

## Steps

1. **Receive workflow input**: AMS submits the job via `spark-submit`; `AudienceImporterMain` parses the JSON argument into a `SourcedAudienceSparkInput` object.
   - From: `continuumAudienceManagementService`
   - To: `continuumAudienceCalculationSpark`
   - Protocol: spark-submit / YARN

2. **Mark SA as IN_PROGRESS**: Calls AMS `PUT /<host>/updateSourcedAudienceInProgress/<saId>` with the YARN `applicationId`. If this fails, the job exits.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

3. **Validate HDFS CSV fields** (CSV source type only): Reads the CSV header from HDFS and confirms all declared field names are present. Reports FAILED to AMS and exits if any fields are missing.
   - From: `sourcedAudienceFlow`
   - To: `hdfsStorage`
   - Protocol: HDFS API

4. **Determine primary key**: Checks `fields` map for `consumer_id` or `bcookie` to identify the audience primary key. Fails if neither is present.

5. **Execute source SQL or load CSV**: Depending on `sourceType`:
   - `csv`: Reads HDFS CSV with `SparkSession.read.format("csv")`, optionally computes `user_key` from `user_id` + `country_id`
   - `hive`, `custom`, `pa_hive`: Executes `sqlQueries` array via Spark SQL; renames columns to `consumer_id`/`bcookie` and optionally `custom_payload`
   - From: `queryExecution`
   - To: `hiveWarehouse` (Hive queries) or `hdfsStorage` (CSV load)
   - Protocol: Hive SQL / HDFS

6. **Cache DataFrame**: Calls `DataFrame.cache()` to avoid recomputation during count operations.

7. **Write SA Hive table**: Saves DataFrame as Parquet/Snappy overwrite to `<database>.<audienceTable>`, partitioned by record count (~5M rows per file).
   - From: `sourcedAudienceFlow`
   - To: `hiveWarehouse`
   - Protocol: Hive SQL (Spark saveAsTable)

8. **Validate for duplicates**: Counts total and distinct primary key values. If duplicates exceed threshold (> 1), reports failure to AMS.

9. **Report final SA result**: Posts record count and status (SUCCESSFUL or FAILED) to AMS `POST /<host>/updateImportResults`.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS IN_PROGRESS update fails | Log error, call `sys.exit(1)` | Job terminates; AMS retains previous state |
| Missing CSV fields | Report FAILED to AMS, call `sys.exit(1)` | Job terminates early |
| No primary key in fields | Call `logAndReportFailureToAms`, exit | AMS receives FAILED result |
| SQL execution failure | `retry()` with 5-min intervals; on exhaustion reports FAILED to AMS | AMS receives FAILED result |
| Duplicate primary keys | Report FAILED to AMS with message | AMS receives FAILED result; user must de-duplicate source |
| Unrecognised sourceType | Report FAILED to AMS | AMS receives FAILED result |

## Sequence Diagram

```
AMS -> AudienceCalculationSpark: spark-submit (AudienceImporterMain, JSON input)
AudienceCalculationSpark -> AMS: PUT /updateSourcedAudienceInProgress/<saId>
AudienceCalculationSpark -> HDFS: Validate CSV header fields (csv type)
AudienceCalculationSpark -> HiveWarehouse: USE <database>
AudienceCalculationSpark -> HiveWarehouse: DROP TABLE IF EXISTS <audienceTable>
AudienceCalculationSpark -> HiveWarehouse/HDFS: Execute SQL or load CSV -> DataFrame
AudienceCalculationSpark -> AudienceCalculationSpark: DataFrame.cache()
AudienceCalculationSpark -> HiveWarehouse: saveAsTable(<database>.<audienceTable>)
AudienceCalculationSpark -> AudienceCalculationSpark: count() + distinctCount() duplicate check
AudienceCalculationSpark -> AMS: POST /updateImportResults (SUCCESSFUL/FAILED, count)
```

## Related

- Architecture dynamic view: `dynamic-sa-to-pa-sourcedAudienceFlow`
- Related flows: [Published Audience Publication](published-audience-publication.md), [Joined Audience](joined-audience.md)
- Next stage: [Published Audience Publication](published-audience-publication.md)
