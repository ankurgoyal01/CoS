---
service: "janus-muncher"
title: "Delta Processing Flow"
generated: "2026-03-03"
type: flow
flow_name: "delta-processing"
flow_type: scheduled
trigger: "Airflow muncher-delta DAG scheduled at :12 past every hour"
participants:
  - "continuumJanusMuncherOrchestrator"
  - "continuumJanusMuncherService"
  - "hdfsStorage"
  - "hiveWarehouse"
  - "metricsStack"
architecture_ref: "dynamic-janusMuncherDeltaProcessing"
---

# Delta Processing Flow

## Summary

The delta processing flow is the core hourly pipeline run. The Airflow `muncher-delta` DAG provisions an ephemeral Dataproc cluster, submits the `MuncherMain` Spark job, which reads newly available canonical Janus event Parquet files from GCS for the current watermark window, deduplicates them, writes deduplicated records to the Janus All GCS path, transforms a subset into Juno format, and writes to the Juno Hourly GCS path. If the watermark after processing is still more than one hour behind, the job recursively re-runs until caught up. The Dataproc cluster is deleted after the job completes.

## Trigger

- **Type**: schedule
- **Source**: Airflow Cloud Composer — DAG `muncher-delta` (non-SOX) and `muncher-delta-sox` (SOX)
- **Frequency**: Non-SOX: hourly at :12 (`12 * * * *`); SOX: hourly at :07 (`7 * * * *`); `max_active_runs = 2`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow DAG Pack | Schedules DAG run; creates and deletes Dataproc cluster | `continuumJanusMuncherOrchestrator` → `orchestratorDagPack` |
| Dataproc Job Launcher | Submits `MuncherMain` Spark job to Dataproc cluster | `continuumJanusMuncherOrchestrator` → `dataprocJobLauncher` |
| MuncherMain Runner | Main Spark entry point; parses args, loads config, runs delta loop | `continuumJanusMuncherService` → `muncherMainRunner` |
| Transformation Pipeline | Reads, transforms, deduplicates, and writes Janus/Juno event records | `continuumJanusMuncherService` → `muncherTransformationPipeline` |
| Ultron State Client | Loads previous watermark; persists new high-watermark after success | `continuumJanusMuncherService` → `muncherUltronClient` |
| Janus Metadata Client | Fetches event destination and schema attributes | `continuumJanusMuncherService` → `muncherMetadataClient` |
| Storage Access Layer | Reads input GCS files; manages staging and output paths | `continuumJanusMuncherService` → `muncherStorageAccessLayer` |
| SMA Metrics Reporter | Emits job duration and throughput metrics | `continuumJanusMuncherService` → `muncherMetricsReporter` |
| GCS (HDFS) | Provides canonical input Parquet files; stores Janus All and Juno Hourly outputs | `hdfsStorage` |
| Telegraf / SMA Gateway | Receives metrics | `metricsStack` |

## Steps

1. **Schedule DAG run**: Airflow schedules `muncher-delta` DAG at `:12` past each hour.
   - From: `orchestratorDagPack`
   - To: `dataprocJobLauncher`
   - Protocol: Airflow task dependency

2. **Create Dataproc cluster**: `DataprocCreateClusterOperator` provisions an ephemeral cluster named `muncher-delta-cluster-{timestamp}` with 1 master (`n1-standard-4`) and 13 workers (`e2-highmem-8`).
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

3. **Submit Spark job**: `DataprocSubmitJobOperator` submits the `MuncherMain` Spark class with args `[dag_id, artifact_version, muncher-prod, delta]`.
   - From: `dataprocJobLauncher`
   - To: `muncherMainRunner`
   - Protocol: Dataproc Spark job submission

4. **Load config**: `MuncherMain` calls `ConfigProvider.getConfig("muncher-prod")` to load HOCON config from the bundled resource file.
   - From: `muncherMainRunner`
   - To: local classpath config
   - Protocol: Direct (pureconfig / typesafe-config)

5. **Load watermark state**: `MuncherDeltaJob` calls `getDeltaManager` which initialises `ultron-client` and fetches the previous high-watermark for job `JunoHourlyGcp` from `ultron-api.production.service`.
   - From: `muncherUltronClient`
   - To: Ultron State API via edge-proxy
   - Protocol: HTTP (mTLS via edge-proxy)

6. **Fetch Janus metadata**: `JanusMetadataService` queries `janus-web-cloud.production.service/janus/api/v1` to retrieve event destination mappings and schema attributes.
   - From: `muncherMetadataClient`
   - To: Janus Metadata API via edge-proxy
   - Protocol: HTTP (mTLS via edge-proxy)

7. **Scan and lock input files**: Storage Access Layer lists GCS files in the canonical input path for the current watermark window; skips files written within the last 5 minutes (`skipNewFilesMinutes = 5`); applies file locking with `lockLookbackDays = 2` lookback.
   - From: `muncherStorageAccessLayer`
   - To: GCS (`hdfsStorage`)
   - Protocol: Hadoop FileSystem API / GCS

8. **Read and stage input**: `JanusAllJsonReader` or `JanusAllParquetReader` reads canonical Parquet files into a Spark DataFrame; `ParquetStageWriter` writes to the staging path `gs://.../janusAllStaging/{jobContextId}`.
   - From: `muncherTransformationPipeline`
   - To: `hdfsStorage` (staging path)
   - Protocol: Spark DataFrameWriter / GCS

9. **Deduplicate and write Janus All**: `JanusAllDedupTransformer` applies deduplication (excluding columns `logstashtime`, `logstashtimems`, `rawHash`); validates event key skew against threshold of 25,000; sends email alert if events are excluded (`alertExcludedEvents = true`); `JanusAllParquetWriter` writes deduplicated records to `gs://.../janus/{ds}/{hour}/`.
   - From: `muncherTransformationPipeline`
   - To: `hdfsStorage` (Janus All output path)
   - Protocol: Spark DataFrameWriter / GCS

10. **Transform and write Juno Hourly**: Re-reads deduplicated Janus All Parquet; `JunoTransformer` applies Juno-specific transformations and filters (`event != 'abExperiment'`), looks back 7 event days; `JunoParquetWriter` writes GZIP Parquet files partitioned by `eventDate`, `platform`, `eventDestination` to `gs://.../juno/junoHourly/`.
    - From: `muncherTransformationPipeline`
    - To: `hdfsStorage` (Juno Hourly output path)
    - Protocol: Spark DataFrameWriter / GCS

11. **Persist high-watermark**: On successful processing, `MuncherMain` computes the new high-watermark and persists it to Ultron State API.
    - From: `muncherUltronClient`
    - To: Ultron State API via edge-proxy
    - Protocol: HTTP (mTLS via edge-proxy)

12. **Lag catch-up check**: If the actual watermark after processing is earlier than one hour ago, `MuncherMain` recursively calls `runMuncher` to process the next lagging window.
    - From: `muncherMainRunner`
    - To: `muncherMainRunner` (recursive)
    - Protocol: Direct Scala call

13. **Emit metrics**: `SMAMetrics.gaugeMuncherJobsRunningDuration` publishes job wall-clock duration to the Telegraf gateway.
    - From: `muncherMetricsReporter`
    - To: `metricsStack`
    - Protocol: HTTP (InfluxDB line protocol)

14. **Cleanup staging paths**: `MuncherMain.tearDown` moves any remaining staging files (`janusAllStaging`, `junoHourlyStaging`) to the trash path on job completion or failure.
    - From: `muncherStorageAccessLayer`
    - To: `hdfsStorage`
    - Protocol: Hadoop FileSystem API / GCS

15. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` tears down the ephemeral cluster (`trigger_rule = all_done`).
    - From: `dataprocJobLauncher`
    - To: Google Cloud Dataproc API
    - Protocol: GCP Dataproc REST API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Input GCS files not available | `Watermark` returns no files; `processFiles` receives empty list and returns `DeltaJobResult` with no action | Job succeeds with no output; next run will retry the same window |
| Spark job exception during processing | Exception caught; input file statuses set to `FAILED`; exception re-thrown; Airflow marks task failed | Airflow DAG run fails; email alert sent; `muncher-backfill` DAG may auto-trigger |
| Source row count is zero after staging | `require(totalSourceRowCount > 0)` assertion fails the job | Exception propagates; file cleanup runs; Airflow task fails |
| Watermark lag > 1 hour | `MuncherMain.runMuncher` recursively re-invokes itself | Successive hourly windows are processed until watermark is current |
| Dataproc cluster creation failure | Retried up to 3 times (`create_cluster_retries = 3`) | After 3 failures, Airflow task fails; alert sent |
| Staging path already exists on teardown | Logs a warning; no exception raised | Staging files remain until next cleanup; trash path may accumulate |

## Sequence Diagram

```
Airflow (DAG) -> Dataproc API: Create cluster muncher-delta-cluster-{ts}
Dataproc API -> MuncherMain: Submit Spark job (class=MuncherMain, args=[dag_id, version, muncher-prod, delta])
MuncherMain -> UltronStateAPI: GET previous watermark (job=JunoHourlyGcp)
UltronStateAPI --> MuncherMain: Watermark timestamp
MuncherMain -> JanusMetadataAPI: GET /janus/api/v1 (event destination metadata)
JanusMetadataAPI --> MuncherMain: Schema and destination attributes
MuncherMain -> GCS: List input files for watermark window
GCS --> MuncherMain: Parquet file paths
MuncherMain -> GCS: Read canonical Parquet, write to staging path
MuncherMain -> GCS: Read staging, deduplicate, write Janus All output
MuncherMain -> GCS: Re-read Janus All, transform, write Juno Hourly output
MuncherMain -> UltronStateAPI: PUT new high-watermark
MuncherMain -> TelegrafGateway: POST job duration metric
MuncherMain -> GCS: Move staging paths to trash (tearDown)
Airflow (DAG) -> Dataproc API: Delete cluster
```

## Related

- Architecture dynamic view: `dynamic-janusMuncherDeltaProcessing`
- Related flows: [Backfill](backfill.md), [Hive Partition Management](hive-partition-management.md), [Watchdog and Lag Monitoring](watchdog-lag-monitoring.md)
