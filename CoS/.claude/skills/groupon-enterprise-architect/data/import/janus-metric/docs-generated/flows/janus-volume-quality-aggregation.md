---
service: "janus-metric"
title: "Janus Volume and Quality Cube Aggregation"
generated: "2026-03-03"
type: flow
flow_name: "janus-volume-quality-aggregation"
flow_type: batch
trigger: "Airflow hourly schedule — janus-metric DAG"
participants:
  - "continuumJanusMetricService"
  - "janusVolumeQualityRunner"
  - "janusMetricComputationEngine"
  - "ultronDeltaManager"
  - "jm_janusApiClient"
architecture_ref: "components-janus-metric-service"
---

# Janus Volume and Quality Cube Aggregation

## Summary

This flow runs hourly via the `janus-metric` Airflow DAG on an ephemeral Google Cloud Dataproc cluster. It reads validated Janus event Parquet files from GCS (produced by the upstream YATI ingestion pipeline), executes three Spark SQL aggregations to produce volume, quality, and catfood quality cubes, and persists all results in chunked HTTPS POST requests to the Janus Metadata Service. Ultron watermarking ensures each GCS file is processed exactly once.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG `janus-metric` — `schedule_interval = '@hourly'`
- **Frequency**: Hourly

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Cloud Composer | DAG scheduler — creates Dataproc cluster and submits Spark job | External |
| Google Cloud Dataproc | Spark execution environment | External |
| `janusVolumeQualityRunner` | Entry point — loads config, initializes Ultron delta manager, starts run | `continuumJanusMetricService` |
| `ultronDeltaManager` | Determines new files by querying Ultron high-watermark | `continuumJanusMetricService` |
| `janusMetricComputationEngine` | Reads Parquet, executes volume/quality/catfood SQL, collects results | `continuumJanusMetricService` |
| `jm_janusApiClient` | Posts cube data to Janus Metadata Service HTTPS endpoints | `continuumJanusMetricService` |
| Janus Metadata Service (`janus-web-cloud`) | Receives and stores metric cubes | External |
| SMA Metrics Gateway | Receives pipeline health gauges and duration timers | External |

## Steps

1. **Airflow triggers cluster creation**: `DataprocCreateClusterOperator` creates a Dataproc cluster named `janus-metric-cluster-{timestamp}` with 1 master + 2 worker `n1-standard-4` nodes.
   - From: Airflow Cloud Composer
   - To: Google Cloud Dataproc API
   - Protocol: GCP API

2. **Airflow submits Spark job**: `DataprocSubmitJobOperator` submits the JAR with main class `com.groupon.janus.ultron.JanusMetricsUltronRunner`, passing config file name and artifact version as arguments; mode defaults to `"regular"`.
   - From: Airflow Cloud Composer
   - To: Google Cloud Dataproc (Spark)
   - Protocol: GCP Dataproc API

3. **Loads configuration**: `JanusMetricsUltronRunner` reads the `.properties` file from the JAR classpath, initializes the SMA metrics environment with InfluxDB connection, and creates an `HttpJanusClient` with mutual TLS credentials.
   - From: `janusVolumeQualityRunner`
   - To: Properties file on classpath / SMA gateway / Janus API endpoint
   - Protocol: classpath read / HTTP

4. **Queries Ultron for new files**: `UltronMetricsFactory.getDeltaManager()` builds a delta manager for job `janus_volume_and_quality_metrics-gcp` and calls the Ultron API to identify GCS paths under `ultronJanusVolumeAndQualityListPath` that have not yet been processed (high-watermark comparison).
   - From: `ultronDeltaManager`
   - To: Ultron API (`ultron-api.production.service`)
   - Protocol: HTTPS

5. **Groups new files by hour directory**: New file paths are grouped by their parent hour directory (e.g., `gs://.../janus/ds=2026-03-03/hour=12/`) to ensure all files in an hour are aggregated together.
   - From: `janusMetricComputationEngine`
   - To: Internal processing
   - Protocol: direct

6. **Reads Parquet data**: For each hour directory, Spark reads all Parquet files into a DataFrame and registers a temp view `temp_janus_all_for_metrics`.
   - From: `janusMetricComputationEngine`
   - To: GCS bucket (Parquet files)
   - Protocol: GCS SDK (Spark)

7. **Aggregates volume cube**: Spark SQL executes `janus_volume.sql` against the temp view — groups by ds, hour, event, platform, clientPlatform, rawEvent, country, sourceTopicName, brand, pageApp, isBot, grouponVersion; computes total_cnt, distinct_raw_cnt, bcookie_cnt, ok_cnt, warn_cnt, and rule-violation statistics.
   - From: `janusMetricComputationEngine`
   - To: In-memory Spark DataFrame
   - Protocol: Spark SQL

8. **Persists volume cube**: Results are collected as JSON, wrapped in `VolumeCubePersistRequest`, and posted to `/janus/api/v1/metrics/data_volume_cube` in chunks of 5 records. HTTP 204 = success.
   - From: `jm_janusApiClient`
   - To: Janus Metadata Service (`janus-web-cloud`)
   - Protocol: HTTPS POST (JSON)

9. **Aggregates quality cube**: Spark filters rows with non-empty `validationString`, explodes validation rules, and executes a quality-cube SQL grouping by event, platform, attribute, and rule_type with counts.
   - From: `janusMetricComputationEngine`
   - To: In-memory Spark DataFrame
   - Protocol: Spark SQL

10. **Persists quality cube**: Results posted in chunks of 5 to `/janus/api/v1/metrics/data_quality_cube`. HTTP 204 = success.
    - From: `jm_janusApiClient`
    - To: Janus Metadata Service
    - Protocol: HTTPS POST (JSON)

11. **Aggregates catfood quality cube**: Same quality logic filtered to two specific `clientId` values; posted to `/janus/api/v1/metrics/data_quality_cube_catfood`.
    - From: `jm_janusApiClient`
    - To: Janus Metadata Service
    - Protocol: HTTPS POST (JSON)

12. **Updates Ultron watermark**: Successfully processed files are marked `FileStatus.SUCCEEDED`; failed files are marked `FileStatus.FAILED`. Ultron updates the high-watermark accordingly.
    - From: `ultronDeltaManager`
    - To: Ultron API
    - Protocol: HTTPS

13. **Emits SMA metrics**: `SMAMetrics.gaugeJanusAllMetricFailure(0/1)` and `SMAMetrics.timeJanusAllMetricDuration(duration)` are sent to the metrics gateway.
    - From: `janusMetricComputationEngine`
    - To: SMA metrics gateway (Telegraf)
    - Protocol: HTTP (InfluxDB line protocol via OkHttp)

14. **Cluster deletion**: `DataprocDeleteClusterOperator` deletes the cluster (trigger rule: `all_done` — runs regardless of Spark job success or failure).
    - From: Airflow Cloud Composer
    - To: Google Cloud Dataproc API
    - Protocol: GCP API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Volume cube POST returns non-204 | `deleteMetadata = false`; files marked `FAILED` in Ultron | Failure gauge = 1; files retried on next hourly run |
| Quality cube POST returns non-204 | `deleteMetadata = false`; files marked `FAILED` | Failure gauge = 1; retry on next run |
| GCS Parquet read exception | Caught; `deleteMetadata = false` | Files remain `FAILED`; SMA gauge = 1; retry |
| Ultron API unavailable | Exception propagates; Spark job exits | Airflow task fails; email notification sent |
| Dataproc cluster creation fails | Airflow retries up to 3 times | If all retries fail, DAG run fails; email notification |

## Sequence Diagram

```
Airflow -> Dataproc: Create cluster (janus-metric-cluster-{ts})
Airflow -> Dataproc: Submit Spark JAR (JanusMetricsUltronRunner, args: config, version, regular)
JanusMetricsUltronRunner -> UltronAPI: GET watermark (janus_volume_and_quality_metrics-gcp)
UltronAPI --> JanusMetricsUltronRunner: List of new GCS file paths
JanusMetricsUltronRunner -> GCS: spark.read.parquet(hour_directory)
GCS --> JanusMetricsUltronRunner: Parquet DataFrame
JanusMetricsUltronRunner -> Spark: SQL: janus_volume.sql -> volume cube
JanusMetricsUltronRunner -> JanusWebCloud: POST /janus/api/v1/metrics/data_volume_cube (chunks of 5)
JanusWebCloud --> JanusMetricsUltronRunner: HTTP 204
JanusMetricsUltronRunner -> Spark: SQL: quality cube query
JanusMetricsUltronRunner -> JanusWebCloud: POST /janus/api/v1/metrics/data_quality_cube (chunks of 5)
JanusWebCloud --> JanusMetricsUltronRunner: HTTP 204
JanusMetricsUltronRunner -> JanusWebCloud: POST /janus/api/v1/metrics/data_quality_cube_catfood
JanusWebCloud --> JanusMetricsUltronRunner: HTTP 204
JanusMetricsUltronRunner -> UltronAPI: Mark files SUCCEEDED
JanusMetricsUltronRunner -> SMAGateway: gauge=0, duration=X
Airflow -> Dataproc: Delete cluster
```

## Related

- Architecture component view: `components-janus-metric-service`
- Related flows: [Janus Raw Event Audit Aggregation](janus-raw-event-audit.md), [Ultron Watermark Delta Management](ultron-watermark-delta.md)
