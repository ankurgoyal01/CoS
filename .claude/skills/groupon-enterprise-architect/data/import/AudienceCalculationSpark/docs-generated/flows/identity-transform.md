---
service: "AudienceCalculationSpark"
title: "Identity Transform"
generated: "2026-03-03"
type: flow
flow_name: "identity-transform"
flow_type: batch
trigger: "spark-submit invocation by continuumAudienceManagementService"
participants:
  - "continuumAudienceManagementService"
  - "continuumAudienceCalculationSpark"
  - "identityTransformFlow"
  - "amsClient"
  - "queryExecution"
  - "hiveWarehouse"
architecture_ref: "components-continuumAudienceCalculationSpark"
---

# Identity Transform

## Summary

The Identity Transform flow executes a user-provided SQL statement against existing Hive audience tables to produce a new Calculated Audience (CA) Hive table. It is used to apply identity resolution or data enrichment logic on top of a sourced audience, transforming one audience representation (e.g. bcookie-based) into another (e.g. consumer_id-based) or calculating derived attributes. Results are written as Parquet/Snappy and the row count is reported back to AMS.

## Trigger

- **Type**: api-call (spark-submit)
- **Source**: `continuumAudienceManagementService` submits the JAR with `--class com.groupon.audienceservice.IdentityTransform.IdentityTransformMain` and a JSON payload argument
- **Frequency**: On-demand — once per calculated audience workflow execution initiated by AMS

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AudienceManagementService | Triggers job; receives lifecycle callbacks | `continuumAudienceManagementService` |
| AudienceCalculationSpark | Spark job runner | `continuumAudienceCalculationSpark` |
| Identity Transform Flow | CA SQL execution and result reporting | `identityTransformFlow` |
| AMS Client Utility | Outbound HTTP callbacks to AMS | `amsClient` |
| Query Execution Utility | Spark SQL / Hive table operations | `queryExecution` |
| Hive Warehouse | Source tables (SA/CA); destination CA table | `hiveWarehouse` |

## Steps

1. **Receive workflow input**: AMS submits the job via `spark-submit`; `IdentityTransformMain` parses the JSON argument to obtain `dbName`, `outputTableName`, `cId` (calculated audience ID), and `sql`.
   - From: `continuumAudienceManagementService`
   - To: `continuumAudienceCalculationSpark`
   - Protocol: spark-submit / YARN

2. **Mark CA as IN_PROGRESS**: Calls AMS `PUT /<host>/updateCalculatedAudienceInProgress/<cId>` with YARN `applicationId`. Exits on failure.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

3. **Configure Hive**: Executes `set hive.mapred.mode=strict` and `USE <dbName>` to scope subsequent queries.
   - From: `queryExecution`
   - To: `hiveWarehouse`
   - Protocol: Hive SQL

4. **Drop existing output table**: Executes `DROP TABLE IF EXISTS <outputTableName>` to allow overwrite on retry.
   - From: `queryExecution`
   - To: `hiveWarehouse`
   - Protocol: Hive SQL

5. **Execute identity transform SQL**: Runs the provided `sql` string via `executeSelectQuery`, producing a DataFrame.
   - From: `queryExecution`
   - To: `hiveWarehouse`
   - Protocol: Hive SQL

6. **Cache DataFrame**: Calls `DataFrame.cache()`.

7. **Write CA Hive table**: Saves the result DataFrame as Parquet/Snappy overwrite to `<dbName>.<outputTableName>`.
   - From: `identityTransformFlow`
   - To: `hiveWarehouse`
   - Protocol: Hive SQL (Spark saveAsTable)

8. **Report final CA result**: Counts rows and posts result (SUCCESSFUL or FAILED) to AMS `POST /<host>/updateCalculationResults`.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS IN_PROGRESS update fails | Log error, call `sys.exit(1)` | Job terminates |
| SQL execution failure | `logAndReportFailureToAms` with error message | AMS receives FAILED result |
| General exception | Catch-all handler logs and reports FAILED | AMS receives FAILED result |

## Sequence Diagram

```
AMS -> AudienceCalculationSpark: spark-submit (IdentityTransformMain, JSON input)
AudienceCalculationSpark -> AMS: PUT /updateCalculatedAudienceInProgress/<cId>
AudienceCalculationSpark -> HiveWarehouse: set hive.mapred.mode=strict
AudienceCalculationSpark -> HiveWarehouse: USE <dbName>
AudienceCalculationSpark -> HiveWarehouse: DROP TABLE IF EXISTS <outputTableName>
AudienceCalculationSpark -> HiveWarehouse: <sql> -> DataFrame
AudienceCalculationSpark -> AudienceCalculationSpark: DataFrame.cache()
AudienceCalculationSpark -> HiveWarehouse: saveAsTable(<dbName>.<outputTableName>)
AudienceCalculationSpark -> AMS: POST /updateCalculationResults (SUCCESSFUL/FAILED, count)
```

## Related

- Related flows: [Sourced Audience Ingestion](sourced-audience-ingestion.md), [Published Audience Publication](published-audience-publication.md)
- Architecture component: `identityTransformFlow`
