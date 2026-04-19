---
service: "AudienceCalculationSpark"
title: "Joined Audience"
generated: "2026-03-03"
type: flow
flow_name: "joined-audience"
flow_type: batch
trigger: "spark-submit invocation by continuumAudienceManagementService"
participants:
  - "continuumAudienceManagementService"
  - "continuumAudienceCalculationSpark"
  - "joinedAudienceFlow"
  - "sourcedAudienceFlow"
  - "publishedAudienceFlow"
  - "amsClient"
  - "queryExecution"
  - "hiveWarehouse"
  - "hdfsStorage"
  - "cassandraAudienceStore"
architecture_ref: "dynamic-joined-audience-sourcedAudienceFlow"
---

# Joined Audience

## Summary

The Joined Audience flow chains SA custom query execution and PA publication into a single Spark job. It avoids a full round-trip through AMS between the SA and PA stages: the SA DataFrame is computed from a custom SQL query, optionally saved as a Hive table, registered as a Spark temp view, and immediately used as input for the PA publication step — all within one job run. Both SA and PA results are reported to AMS independently. Retry logic wraps the entire SA + PA sequence.

## Trigger

- **Type**: api-call (spark-submit)
- **Source**: `continuumAudienceManagementService` submits the JAR with `--class com.groupon.audienceservice.JoinedAudience.AudienceJoinedMain` and a JSON payload argument
- **Frequency**: On-demand — once per joined audience workflow execution initiated by AMS

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AudienceManagementService | Triggers job; receives SA and PA lifecycle callbacks | `continuumAudienceManagementService` |
| AudienceCalculationSpark | Spark job runner | `continuumAudienceCalculationSpark` |
| Joined Audience Flow | Orchestrates SA + PA in sequence | `joinedAudienceFlow` |
| Sourced Audience Flow | Executes custom SA SQL query | `sourcedAudienceFlow` |
| Published Audience Flow | Executes PA segmentation and artifact generation | `publishedAudienceFlow` |
| AMS Client Utility | Outbound HTTP callbacks to AMS | `amsClient` |
| Query Execution Utility | Spark SQL / Hive temp view operations | `queryExecution` |
| Hive Warehouse | Optional SA table storage; PA segment tables | `hiveWarehouse` |
| HDFS Storage | PA CSV, feedback CSV, deal-bucket JSON outputs | `hdfsStorage` |
| Cassandra Audience Store | PA membership payloads (non-realtime) | `cassandraAudienceStore` |

## Steps

1. **Receive workflow input**: AMS submits job; `AudienceJoinedMain` parses `JoinedSparkInput` JSON containing both `sourcedAudienceSparkInput` and `paSparkInput`, plus `sourcedAudienceToBeSaved` and `sourcedAudienceTempViewName` fields.
   - From: `continuumAudienceManagementService`
   - To: `continuumAudienceCalculationSpark`
   - Protocol: spark-submit / YARN

2. **Initialise**: Registers `toJsonUDF` Spark SQL function and validates initial state.

3. **Mark SA as IN_PROGRESS**: Calls AMS `PUT /<host>/updateSourcedAudienceInProgress/<saId>`. Sets `isRetry=true` to prevent duplicate IN_PROGRESS calls on retry.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

4. **Create SA DataFrame from custom query**: Calls `AudienceImporter.calculateCustomQuerySourcedAudienceDataFrame(saveSA=sourcedAudienceToBeSaved)`:
   - Validates `sourceType == "custom"` (only custom queries allowed in joined flow)
   - Executes `sql(0)` via Spark SQL → produces DataFrame with `consumer_id`/`bcookie` + `custom_payload`
   - Checks for duplicates if SQL does not use `SELECT DISTINCT`
   - If `sourcedAudienceToBeSaved=true`: drops old table and saves as Parquet Hive table
   - From: `sourcedAudienceFlow` → `queryExecution`
   - To: `hiveWarehouse` (if saving)
   - Protocol: Hive SQL

5. **Register SA temp view**: Creates a Spark temp view named `sourcedAudienceTempViewName` from the SA DataFrame, making it queryable by the PA `sourceDataFrameCreationQuery`.
   - From: `joinedAudienceFlow`
   - To: In-memory Spark session
   - Protocol: Spark SQL

6. **Count SA records** (if `sourcedAudienceToBeSaved=true`): Counts SA rows for result reporting.

7. **Execute PA publication**: Delegates to `AudiencePublisher.publishAndFeedback()` (same logic as [Published Audience Publication](published-audience-publication.md) flow), with `fromJoinedAudience=true` to suppress PA result reporting within that method.
   - From: `joinedAudienceFlow`
   - To: `publishedAudienceFlow`
   - Protocol: Internal Spark call

8. **Report SA result**: Posts SA record count and status to AMS `POST /<host>/updateImportResults`.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

9. **Report PA result**: Posts PA segment counts and status to AMS `POST /<host>/updatePublicationResults`.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Initialisation error | Reports FAILED for both SA and PA; rethrows | AMS receives FAILED for both |
| Non-custom sourceType | Returns Failure immediately | SA creation aborted; AMS receives FAILED |
| SA custom query failure | Retry with 5-min interval; on exhaustion reports both SA and PA as FAILED | AMS receives FAILED for both |
| Duplicate SA records | Returns Failure; reports both SA and PA as FAILED | AMS receives FAILED for both |
| PA publication failure | Set `paResult=FAILED`; `saResult` may be SUCCESSFUL | AMS receives mixed results |
| Any unhandled exception | Reports both SA and PA results before exiting | AMS state updated |

## Sequence Diagram

```
AMS -> AudienceCalculationSpark: spark-submit (AudienceJoinedMain, JSON input)
AudienceCalculationSpark -> AMS: PUT /updateSourcedAudienceInProgress/<saId>
AudienceCalculationSpark -> HiveWarehouse: USE <database>
AudienceCalculationSpark -> HiveWarehouse: <customSql> -> SA DataFrame
AudienceCalculationSpark -> AudienceCalculationSpark: SA DataFrame.cache() + duplicate check
AudienceCalculationSpark -> HiveWarehouse: saveAsTable (if sourcedAudienceToBeSaved=true)
AudienceCalculationSpark -> AudienceCalculationSpark: createOrReplaceTempView(<saViewName>)
AudienceCalculationSpark -> HiveWarehouse: sourceDataFrameCreationQuery (joins SA temp view) -> PA baseDF
AudienceCalculationSpark -> AudienceCalculationSpark: segmentation + segment tables
AudienceCalculationSpark -> HDFS: PA CSV, feedback CSV, deal-bucket JSON
AudienceCalculationSpark -> Cassandra: PA membership payloads
AudienceCalculationSpark -> AMS: POST /updateImportResults (SA result)
AudienceCalculationSpark -> AMS: POST /updatePublicationResults (PA result)
```

## Related

- Architecture dynamic view: `dynamic-joined-audience-sourcedAudienceFlow`
- Related flows: [Sourced Audience Ingestion](sourced-audience-ingestion.md), [Published Audience Publication](published-audience-publication.md)
