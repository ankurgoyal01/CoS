---
service: "AudienceCalculationSpark"
title: "Published Audience Publication"
generated: "2026-03-03"
type: flow
flow_name: "published-audience-publication"
flow_type: batch
trigger: "spark-submit invocation by continuumAudienceManagementService"
participants:
  - "continuumAudienceManagementService"
  - "continuumAudienceCalculationSpark"
  - "publishedAudienceFlow"
  - "amsClient"
  - "queryExecution"
  - "audiencecalculationspark_fileExport"
  - "realtimeBigtableAdapter"
  - "hiveWarehouse"
  - "hdfsStorage"
  - "cassandraAudienceStore"
  - "bigtableRealtimeStore"
architecture_ref: "dynamic-sa-to-pa-sourcedAudienceFlow"
---

# Published Audience Publication

## Summary

The Published Audience (PA) Publication flow takes a source DataFrame (assembled from joined Hive tables), applies segmentation using deterministic hash splits, writes one Hive table per segment, generates CSV and EDW feedback files on HDFS, writes PA membership payloads to Cassandra (non-realtime) or GCP Bigtable (realtime/NA), collects deal-bucket metadata, and reports segment counts and final status back to AMS. This is the final production step of the audience pipeline, making audiences available for email targeting and real-time delivery.

## Trigger

- **Type**: api-call (spark-submit)
- **Source**: `continuumAudienceManagementService` submits the JAR with `--class com.groupon.audienceservice.PublishedAudience.AudiencePublisherMain` and a JSON payload argument
- **Frequency**: On-demand — once per PA workflow execution initiated by AMS

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AudienceManagementService | Triggers job; receives lifecycle callbacks | `continuumAudienceManagementService` |
| AudienceCalculationSpark | Spark job runner | `continuumAudienceCalculationSpark` |
| Published Audience Flow | PA segmentation, table creation, artifact generation | `publishedAudienceFlow` |
| AMS Client Utility | Outbound HTTP callbacks to AMS | `amsClient` |
| Query Execution Utility | Spark SQL / Hive table and UDF operations | `queryExecution` |
| File Export Utility | CSV and JSON artifact generation | `audiencecalculationspark_fileExport` |
| Realtime Bigtable Adapter | Bigtable realtime payload writer (NA only) | `realtimeBigtableAdapter` |
| Hive Warehouse | Source tables; PA segment tables written here | `hiveWarehouse` |
| HDFS Storage | Receives PA CSV, feedback CSV, deal-bucket JSON | `hdfsStorage` |
| Cassandra Audience Store | Receives PA membership payloads (non-realtime) | `cassandraAudienceStore` |
| Bigtable Realtime Store | Receives realtime PA membership payloads (NA only) | `bigtableRealtimeStore` |

## Steps

1. **Receive workflow input**: AMS submits job; `AudiencePublisherMain` parses `PASparkInput` JSON including segment definitions, source query, CSV paths, and AMS host.
   - From: `continuumAudienceManagementService`
   - To: `continuumAudienceCalculationSpark`
   - Protocol: spark-submit / YARN

2. **Mark PA as IN_PROGRESS**: Calls AMS `PUT /<host>/updatePublishedAudienceInProgress/<paId>`.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

3. **Fetch PA detail from AMS**: Calls `GET /<host>/getPublishedAudience/<paId>` to determine `audienceType` (ConsumerId, Bcookie, or Universal) and `sadId`.
   - From: `amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

4. **Register EMEA UDFs** (EMEA region only): Adds UDF JAR files (`AudienceManagementHive-1.11.jar`, `CollectAllUdaf-1.0-SNAPSHOT.jar`) and registers custom Hive UDF functions.
   - From: `queryExecution`
   - To: `hiveWarehouse`
   - Protocol: Hive SQL

5. **Create base parent DataFrame**: Executes `sourceDataFrameCreationQuery` (SQL that joins SA/CA tables) to produce the base audience DataFrame.
   - From: `queryExecution`
   - To: `hiveWarehouse`
   - Protocol: Hive SQL

6. **Normalise base DataFrame** (EMEA only, when `sourceDataFrameWithoutComplexFieldCreationQuery` is present): Registers a temp table and executes the de-normalisation query to flatten complex struct columns.
   - From: `queryExecution`
   - To: `hiveWarehouse`
   - Protocol: Hive SQL

7. **Cache audience DataFrame**: Calls `DataFrame.cache()` on the (normalised) base DataFrame.

8. **Segment audience**: Applies `randomHashSplit` using MurmurHash3 on the primary key column to split the DataFrame into proportional non-default segments. Seed is `paId` (or `sadId` for SAD-backed PAs) for deterministic consistency.

9. **Create segment tables and CSVs**: For each segment (non-default first, then default):
   - Registers temp table for segment DataFrame
   - Creates final segment Hive table with `segment` label column appended
   - Exports segment to CSV via `CiaFileUtil.parquetToCSV` → HDFS
   - From: `queryExecution` + `audiencecalculationspark_fileExport`
   - To: `hiveWarehouse` + `hdfsStorage`
   - Protocol: Hive SQL + HDFS

10. **Write PA membership payload**:
    - If `realtime=true` (NA only): Converts DataFrame to `<paId>;<sadId>;<custom_payload>;<segment>` format; writes to Bigtable `user_data_main` or `bcookie_data_main` via `BigtableHandler`
    - If `realtime=false` and `enablePayload=true`: Writes to Cassandra via `PAPayloadGenerator.mapPaDataFrameToCassandra(df.repartition(200), ...)`
    - From: `realtimeBigtableAdapter` or `publishedAudienceFlow`
    - To: `bigtableRealtimeStore` or `cassandraAudienceStore`
    - Protocol: Bigtable API / Cassandra

11. **Collect deal buckets**: Checks PA DataFrame for `oc_deal_bucket`, `rs_deal_bucket`, `ga_deal_bucket`, `gg_deal_bucket` columns; if present, writes `pa_<paId>_dealbuckets.json` to HDFS.
    - From: `audiencecalculationspark_fileExport`
    - To: `hdfsStorage`
    - Protocol: HDFS

12. **Generate EDW feedback CSV**: Executes `feedbackTableCreationQuery`, creates a temp view, then exports to `feedback_pa_<paId>.csv` on HDFS.
    - From: `audiencecalculationspark_fileExport`
    - To: `hdfsStorage`
    - Protocol: HDFS

13. **Report final PA result**: Posts segment count map, HDFS URI base, and result status (SUCCESSFUL/FAILED) to AMS `POST /<host>/updatePublicationResults`.
    - From: `amsClient`
    - To: `continuumAudienceManagementService`
    - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS IN_PROGRESS update fails | Log and return Failure | Job exits; AMS state unchanged |
| Base DataFrame creation fails | Set `paResult=FAILED`, recover and report to AMS | AMS receives FAILED |
| Segment table creation fails | Set `paResult=FAILED`, rethrow in recovery | AMS receives FAILED |
| Bigtable write fails | Exception propagates; `paResult=FAILED` | AMS receives FAILED |
| Cassandra write fails | Exception propagates; `paResult=FAILED` | AMS receives FAILED |
| PA dedup source table not found | Return Failure | AMS receives FAILED |

## Sequence Diagram

```
AMS -> AudienceCalculationSpark: spark-submit (AudiencePublisherMain, JSON input)
AudienceCalculationSpark -> AMS: PUT /updatePublishedAudienceInProgress/<paId>
AudienceCalculationSpark -> AMS: GET /getPublishedAudience/<paId>
AMS --> AudienceCalculationSpark: PADetail (audienceType, sadId)
AudienceCalculationSpark -> HiveWarehouse: sourceDataFrameCreationQuery -> baseDF
AudienceCalculationSpark -> AudienceCalculationSpark: cache baseDF
AudienceCalculationSpark -> AudienceCalculationSpark: randomHashSplit(baseDF) -> segmentDFs
AudienceCalculationSpark -> HiveWarehouse: CREATE TABLE published_<paId>_<label>_<ts>
AudienceCalculationSpark -> HDFS: parquetToCSV -> pa_<paId>_<label>.csv
AudienceCalculationSpark -> Bigtable/Cassandra: write PA membership payloads
AudienceCalculationSpark -> HDFS: pa_<paId>_dealbuckets.json (if deal buckets present)
AudienceCalculationSpark -> HDFS: feedback_pa_<paId>.csv
AudienceCalculationSpark -> AMS: POST /updatePublicationResults (SUCCESSFUL/FAILED, segmentCounts)
```

## Related

- Architecture dynamic view: `dynamic-sa-to-pa-sourcedAudienceFlow`
- Related flows: [Sourced Audience Ingestion](sourced-audience-ingestion.md), [Joined Audience](joined-audience.md), [Batch Published Audience](batch-published-audience.md)
