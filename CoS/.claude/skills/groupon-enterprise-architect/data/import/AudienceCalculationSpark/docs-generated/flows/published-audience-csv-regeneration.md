---
service: "AudienceCalculationSpark"
title: "Published Audience CSV Regeneration"
generated: "2026-03-03"
type: flow
flow_name: "published-audience-csv-regeneration"
flow_type: batch
trigger: "spark-submit invocation by continuumAudienceManagementService"
participants:
  - "continuumAudienceManagementService"
  - "continuumAudienceCalculationSpark"
  - "csvCreatorFlow"
  - "amsClient"
  - "audiencecalculationspark_fileExport"
  - "hiveWarehouse"
  - "hdfsStorage"
architecture_ref: "components-continuumAudienceCalculationSpark"
---

# Published Audience CSV Regeneration

## Summary

The Published Audience CSV Regeneration flow re-exports PA segment CSV files from existing Hive tables without recalculating the audience itself. It is used when the PA Hive tables already exist but the CSV files are missing or need to be recreated — for example after a partial failure in the original publication run. The flow iterates over each segment definition in the PA spark input, calls `CiaFileUtil.parquetToCSV` for each segment table, and updates AMS with `IN_PROGRESS` and `CREATED` (or `FAILED`) CSV status flags.

## Trigger

- **Type**: api-call (spark-submit)
- **Source**: `continuumAudienceManagementService` submits the JAR with `--class com.groupon.audienceservice.PublishedAudience.PublishedAudienceCsvCreatorMain` and a JSON payload argument
- **Frequency**: On-demand — triggered when AMS detects missing or stale PA CSV files

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AudienceManagementService | Triggers job; receives CSV status updates | `continuumAudienceManagementService` |
| AudienceCalculationSpark | Spark job runner | `continuumAudienceCalculationSpark` |
| CSV Creator Flow | Segment CSV regeneration logic | `csvCreatorFlow` |
| AMS Client Utility | Reports CSV status (IN_PROGRESS, CREATED, FAILED) | `amsClient` |
| File Export Utility | Converts Hive Parquet tables to CSV on HDFS | `audiencecalculationspark_fileExport` |
| Hive Warehouse | Source — existing PA segment Parquet tables | `hiveWarehouse` |
| HDFS Storage | Destination — regenerated PA segment CSV files | `hdfsStorage` |

## Steps

1. **Receive workflow input**: AMS submits job; `PublishedAudienceCsvCreatorMain` parses `PASparkInput` JSON with `paId`, `segmentInputs`, `paCsvPath`, and AMS host.
   - From: `continuumAudienceManagementService`
   - To: `continuumAudienceCalculationSpark`
   - Protocol: spark-submit / YARN

2. **Mark CSV generation as IN_PROGRESS**: Calls AMS `PUT /<host>/published-audience/<paId>/csv-status` with `{"csvStatus": "IN_PROGRESS"}`.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

3. **For each segment in `segmentInputs`**:
   - Reads existing PA Hive table `<database>.<audienceTableId>` (Parquet/Snappy)
   - Converts to CSV via `CiaFileUtil.parquetToCSV(spark, tempFolder, database, audienceTableId, paCsvPath + csvFile, defaultHDFS, generateCsv, log)`
   - Writes CSV file to `<paCsvPath>/<csvFile>` on HDFS
   - On failure: updates AMS CSV status to `FAILED` and calls `sys.exit(1)`
   - From: `audiencecalculationspark_fileExport`
   - To: `hiveWarehouse` (read) + `hdfsStorage` (write)
   - Protocol: HDFS

4. **Mark CSV generation as CREATED**: Calls AMS `PUT /<host>/published-audience/<paId>/csv-status` with `{"csvStatus": "CREATED"}`.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CSV export failure for a segment | Update AMS CSV status to `FAILED`, call `sys.exit(1)` | Job terminates; remaining segments not processed |
| AMS status update failure | Not explicitly handled; exception propagates | Job fails |

## Sequence Diagram

```
AMS -> AudienceCalculationSpark: spark-submit (PublishedAudienceCsvCreatorMain, JSON input)
AudienceCalculationSpark -> AMS: PUT /published-audience/<paId>/csv-status {"csvStatus":"IN_PROGRESS"}
loop for each segmentInput
  AudienceCalculationSpark -> HiveWarehouse: read <database>.<audienceTableId> (Parquet)
  AudienceCalculationSpark -> HDFS: write <paCsvPath>/<csvFile>
end
AudienceCalculationSpark -> AMS: PUT /published-audience/<paId>/csv-status {"csvStatus":"CREATED"}
```

## Related

- Related flows: [Published Audience Publication](published-audience-publication.md)
- Architecture component: `csvCreatorFlow`
