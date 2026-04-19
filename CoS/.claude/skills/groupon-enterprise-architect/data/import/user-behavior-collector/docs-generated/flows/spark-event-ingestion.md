---
service: "user-behavior-collector"
title: "Spark Event Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "spark-event-ingestion"
flow_type: batch
trigger: "Daily cron (update_deal_views) at 06:00 UTC (NA) / 17:15 UTC (EMEA)"
participants:
  - "continuumUserBehaviorCollectorJob"
  - "janusKafkaEventFiles_3b6f"
  - "gdoopHadoopCluster_8d2c"
  - "continuumDealViewNotificationDb"
architecture_ref: "continuumUserBehaviorCollectorJob-components"
---

# Spark Event Ingestion

## Summary

The Spark Event Ingestion flow is the core data-collection step of the batch job. It advances a file-pointer cursor stored in PostgreSQL to determine which Janus Kafka parquet files have not yet been processed, submits a Spark job to the gdoop YARN cluster to read and parse those files, classifies raw events into five typed streams (deal views, purchases, searches, ratings, email opens), writes intermediate results to HDFS, and then persists the classified records from HDFS into the `deal_view_notification` PostgreSQL database.

## Trigger

- **Type**: schedule
- **Source**: System cron at `/etc/cron.d/user-behavior-collector`; runs the `update_deal_views` script
- **Frequency**: Daily — NA production: 06:00 UTC; EMEA production: 17:15 UTC

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Job Orchestrator | Reads file pointer; submits Spark job; reads HDFS results; persists to DB | `continuumUserBehaviorCollectorJob` |
| Spark Pipeline | Distributed event parsing and classification on YARN | `continuumUserBehaviorCollectorJob` (sparkPipeline component) |
| Janus Kafka Event Files (HDFS/GCS) | Source of raw user behavior Parquet files | `janusKafkaEventFiles_3b6f` |
| Gdoop Hadoop Cluster (YARN) | Executes the Spark application | `gdoopHadoopCluster_8d2c` |
| Deal View Notification DB | Stores file-pointer state; receives persisted event records | `continuumDealViewNotificationDb` |

## Steps

1. **Read file pointer from DB**: Job Orchestrator reads `next-kafka-file` from `key-value-store` table in `continuumDealViewNotificationDb`
   - From: `continuumUserBehaviorCollectorJob` (jobOrchestrator)
   - To: `continuumDealViewNotificationDb`
   - Protocol: JDBC

2. **List new Kafka files**: `KafkaPathList.listNewFiles(startFile)` enumerates all parquet files under `/user/kafka/source=janus-all/` newer than the file pointer on HDFS/GCS
   - From: `continuumUserBehaviorCollectorJob`
   - To: `janusKafkaEventFiles_3b6f` (HDFS/GCS)
   - Protocol: HDFS FileSystem API

3. **Clean up previous intermediate HDFS folders**: Deletes existing deal-view, deal-purchase, user-search, user-rating, and email-open intermediate folders from the previous run under `/grp_gdoop_emerging_channels/`
   - From: `continuumUserBehaviorCollectorJob`
   - To: `gdoopHadoopCluster_8d2c` (HDFS)
   - Protocol: HDFS FileSystem API

4. **Submit Spark job to YARN**: `SparkJobSubmitter` launches the Spark application with `master=yarn`, reads all new parquet files via `spark.read().parquet(files)`
   - From: `continuumUserBehaviorCollectorJob` (sparkPipeline)
   - To: `gdoopHadoopCluster_8d2c` (YARN)
   - Protocol: Spark / YARN

5. **Parse and classify raw events**: Spark job deserializes each Parquet record to `RawEvent`, filters by country, and routes to typed RDDs: `DealViewInfo`, `DealPurchaseInfo`, `UserSearchInfo` (mobile: `rawEvent=GRP1`; web: `rawEvent=bh-impression`), `UserRatingData`, `EmailOpenInfo` (channel=`targeted_deal`)
   - From: `continuumUserBehaviorCollectorJob` (sparkPipeline)
   - To: in-memory Spark RDDs on `gdoopHadoopCluster_8d2c`
   - Protocol: Spark in-memory

6. **Deduplicate search events**: Mobile search events are de-duplicated by `(bcookie, searchString, brand)` key; web search events by `(consumerId, searchString, brand)` key using `reduceByKey`; latest event time wins
   - From: `continuumUserBehaviorCollectorJob` (sparkPipeline)
   - To: in-memory RDD
   - Protocol: Spark in-memory

7. **Write typed event files to HDFS**: Each typed RDD is serialized to JSON and saved as text files to intermediate HDFS paths (`/grp_gdoop_emerging_channels/<user>-deal-views-<suffix>/`, etc.)
   - From: `continuumUserBehaviorCollectorJob` (sparkPipeline)
   - To: `gdoopHadoopCluster_8d2c` (HDFS)
   - Protocol: HDFS (Spark `saveAsTextFile`)

8. **Read intermediate files and persist to DB**: Data Access Layer reads HDFS result files and batch-inserts `DealViewPersistBatch`, `DealPurchasePersistBatch`, `EmailOpenPersistBatch` records into `continuumDealViewNotificationDb`
   - From: `continuumUserBehaviorCollectorJob` (userBehaviorCollector_dataAccessLayer)
   - To: `continuumDealViewNotificationDb`
   - Protocol: JDBC / Hibernate

9. **Advance file pointer in DB**: Writes `nextFile` value back to `next-kafka-file` key in `key-value-store` table
   - From: `continuumUserBehaviorCollectorJob` (jobOrchestrator)
   - To: `continuumDealViewNotificationDb`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Spark job fails | Job exits non-zero; `stderr.log` is emailed to team; PagerDuty paged | File pointer not advanced; retry required; drop one day data if too late |
| Malformed/null event fields | `.filter(pair -> pair != null)` removes null-mapped events | Record silently dropped; others processed normally |
| HDFS intermediate folder delete fails | Logged; processing continues | Previous run's data may still exist; overwritten on next write |
| Country filter mismatch | Event filtered out in `rawEvents` filter | Record not persisted; no alert |
| Last file in list (partial file) | Always excluded: `filesToProcess = files.size() - 1` | Partial file never read |

## Sequence Diagram

```
CronScheduler -> JobOrchestrator: Invoke update_deal_views script
JobOrchestrator -> DealViewNotificationDb: Read next-kafka-file from key-value-store
DealViewNotificationDb --> JobOrchestrator: Return startFile path
JobOrchestrator -> JanusKafkaFiles(HDFS): List parquet files since startFile
JanusKafkaFiles(HDFS) --> JobOrchestrator: Return file list
JobOrchestrator -> GdoopHDFS: Delete old intermediate folders
JobOrchestrator -> SparkPipeline: Submit Spark job to YARN with file list
SparkPipeline -> JanusKafkaFiles(HDFS/GCS): spark.read().parquet(files)
SparkPipeline -> SparkPipeline: Parse RawEvent, filter by country, classify event types
SparkPipeline -> SparkPipeline: Deduplicate search events by key
SparkPipeline -> GdoopHDFS: saveAsTextFile to intermediate folders
SparkPipeline --> JobOrchestrator: Return JobResult (nextFile, folder paths)
JobOrchestrator -> DataAccessLayer: Read HDFS files and batch-insert to DB
DataAccessLayer -> DealViewNotificationDb: INSERT DealViewInfo, DealPurchaseInfo, EmailOpenInfo records
DataAccessLayer --> JobOrchestrator: Done
JobOrchestrator -> DealViewNotificationDb: Update next-kafka-file to nextFile
```

## Related

- Architecture dynamic view: `continuumUserBehaviorCollectorJob-components`
- Related flows: [Deal Info Refresh](deal-info-refresh.md), [Audience Publishing](audience-publishing.md)
