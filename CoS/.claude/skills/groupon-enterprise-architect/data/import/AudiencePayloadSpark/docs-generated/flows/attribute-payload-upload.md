---
service: "AudiencePayloadSpark"
title: "Attribute Payload Upload"
generated: "2026-03-03"
type: flow
flow_name: "attribute-payload-upload"
flow_type: batch
trigger: "Manual Fabric command or cron schedule"
participants:
  - "continuumAudiencePayloadOps"
  - "continuumAudiencePayloadSpark"
  - "amsApi"
  - "hiveMetastore"
  - "cassandraKeyspaces"
  - "gcpBigtable"
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
architecture_ref: "dynamic-payload_generation_flow"
---

# Attribute Payload Upload

## Summary

The attribute payload upload flow reads user or bcookie system attributes from a Hive source table and writes the results to Cassandra attribute tables (`user_attr2`, `bcookie_attr_v1`) and GCP Bigtable (`user_data_main`, `bcookie_data_main`). It supports both full upload (all records in the system table) and delta upload (only records changed since a previous base table), making stale entries deletable. The flow is triggered by an operator Fabric command or a scheduled cron job.

## Trigger

- **Type**: manual / schedule
- **Source**: `continuumAudiencePayloadOps` — Fabric task `upload_attributes` or cron invocation
- **Frequency**: Typically daily or on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Fabric scripts (`continuumAudiencePayloadOps`) | Submits `spark-submit` job with CLI arguments | `continuumAudiencePayloadOps` |
| `AttrPayloadGeneratorMain` | Spark job entrypoint; parses CLI args and builds SparkSession | `attrPayloadGeneratorMain` |
| `AttrPayloadGenerator` | Core orchestrator; builds queries, computes delta, drives writes | `attributePayloadEngine` |
| AMS API | Returns the latest system table name if not specified | `amsApi` |
| Hive Metastore | Source of system attribute table(s) | `hiveMetastore` |
| `CassandraWriter` / `CassandraClientFactory` | Writes updated rows and removes stale rows in Cassandra | `cassandraAccessLayer` |
| GCP Bigtable (`BigtableHandler`) | Writes updated rows and removes stale rows in Bigtable | `bigtableAccessLayer` |

## Steps

1. **Submit job**: Operator runs `fab production:na upload_attributes:users` (or equivalent).
   - From: `fabricTasks`
   - To: `submitPayloadScript` (CommandBuilder)
   - Protocol: direct (Python function call)

2. **Build and submit spark-submit command**: `CommandBuilder.upload_system_attributes()` assembles the `spark-submit` invocation with `--env`, `--payload-type`, `--system-table`, `--base-table` arguments.
   - From: `submitPayloadScript`
   - To: YARN cluster via `spark-submit`
   - Protocol: spark-submit

3. **Resolve system table name**: If `--system-table` is not provided, `AttrPayloadGenerator` calls AMS API `GET /getSourcedAudience/1?type=system&systemSource=users` to get the latest system table name.
   - From: `configAndAudienceUtil` (`AudienceUtil.getSystemTable`)
   - To: `amsApi`
   - Protocol: HTTP (OkHttp)

4. **Load source Hive table**: Executes Spark SQL `SELECT <attribute_columns> FROM <hiveDb>.<systemTable> WHERE consumer_id IS NOT NULL`.
   - From: `attributePayloadEngine` (`AttrPayloadGenerator.getAttrDataframe`)
   - To: `hiveMetastore`
   - Protocol: Spark SQL with Hive support

5. **Compute delta (if base table provided)**: Executes `newTable.except(oldTable)` for additions and `oldTable.leftanti_join(newTable)` for deletions. For full upload, `oldTable` is null and all records are treated as additions.
   - From: `attributePayloadEngine` (`getDeltaUploadDataFrames`)
   - To: Hive (reads base table)
   - Protocol: Spark SQL

6. **Write updated records to Bigtable**: Maps DataFrame columns and calls `BigtableHandler.uploadToBigtable(updateDfFinal, columnsToUpload)`.
   - From: `attributePayloadEngine`
   - To: `gcpBigtable` (instance `grp-prod-bigtable-rtams-ins`)
   - Protocol: gRPC (bigtable_client)

7. **Delete stale records from Bigtable**: Calls `BigtableHandler.deleteFamilyFromBigtable(removeDfFinal)` for consumer IDs no longer in the system table.
   - From: `attributePayloadEngine`
   - To: `gcpBigtable`
   - Protocol: gRPC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS API unavailable | Retry with exponential backoff (3 retries, starting 4s, doubling) | Job fails if all retries exhausted |
| Bigtable upload exception | Exception caught and re-thrown with stack trace logged | Spark job fails; YARN reports failure |
| Spark SQL analysis exception | Caught by top-level `try/catch` in `run()` | Job fails; error logged |
| Empty delta (no changes) | Normal completion with zero writes | Job succeeds silently |

## Sequence Diagram

```
Operator          -> fabricTasks         : fab production:na upload_attributes:users
fabricTasks       -> submitPayloadScript : CommandBuilder.upload_system_attributes()
submitPayloadScript -> AttrPayloadGeneratorMain : spark-submit --env production-na --payload-type users
AttrPayloadGeneratorMain -> AmsApi       : GET /getSourcedAudience/1?type=system&systemSource=users
AmsApi            --> AttrPayloadGeneratorMain : { "name": "ams.user_attributes_20260303" }
AttrPayloadGeneratorMain -> HiveMetastore : SELECT consumer_id, <attrs> FROM ams.user_attributes_20260303
HiveMetastore     --> AttrPayloadGeneratorMain : DataFrame (new records)
AttrPayloadGeneratorMain -> HiveMetastore : SELECT consumer_id, <attrs> FROM ams.user_attributes_20260302
HiveMetastore     --> AttrPayloadGeneratorMain : DataFrame (old records)
AttrPayloadGeneratorMain -> AttrPayloadGenerator : getDeltaUploadDataFrames(new, old)
AttrPayloadGenerator -> BigtableHandler  : uploadToBigtable(updateDf, columns)
BigtableHandler   --> AttrPayloadGenerator : success
AttrPayloadGenerator -> BigtableHandler  : deleteFamilyFromBigtable(removeDf)
BigtableHandler   --> AttrPayloadGenerator : success
```

## Related

- Architecture dynamic view: `dynamic-payload_generation_flow`
- Related flows: [PA Membership Upload](pa-membership-upload.md), [SAD Aggregation](sad-aggregation.md)
