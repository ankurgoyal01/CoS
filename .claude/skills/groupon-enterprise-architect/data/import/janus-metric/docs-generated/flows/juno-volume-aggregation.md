---
service: "janus-metric"
title: "Juno Hourly Volume Cube Aggregation"
generated: "2026-03-03"
type: flow
flow_name: "juno-volume-aggregation"
flow_type: batch
trigger: "Airflow daily schedule — juno-metric DAG"
participants:
  - "continuumJanusMetricService"
  - "junoMetricRunner"
  - "junoMetricEngine"
  - "ultronDeltaManager"
  - "jm_janusApiClient"
architecture_ref: "components-janus-metric-service"
---

# Juno Hourly Volume Cube Aggregation

## Summary

This flow runs daily via the `juno-metric` Airflow DAG on an ephemeral Dataproc cluster. It reads Juno hourly event Parquet files from GCS partitioned by `eventDate`, `platform`, and `eventDestination`, and aggregates them into Juno volume cubes using Spark SQL. Files are processed in configurable batches (default: 25 per Spark query). The country dimension is filtered to known valid countries fetched from the Janus Metadata Service at startup. Results are persisted to the Janus Metadata Service via HTTPS.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG `juno-metric` — `schedule_interval = '@daily'`
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Cloud Composer | DAG scheduler | External |
| Google Cloud Dataproc | Spark execution environment | External |
| `junoMetricRunner` | Entry point — loads config, fetches country list, starts Ultron run | `continuumJanusMetricService` |
| `ultronDeltaManager` | Delta manager for Juno files (job: `juno_metrics-gcp`) | `continuumJanusMetricService` |
| `junoMetricEngine` | Reads Juno Parquet files in batches, runs SQL aggregations, collects results | `continuumJanusMetricService` |
| `jm_janusApiClient` | Posts Juno volume cubes to `/janus/api/v1/metrics/data_volume_cube_event_time` | `continuumJanusMetricService` |
| Janus Metadata Service (`janus-web-cloud`) | Provides valid country list; stores Juno volume cubes | External |

## Steps

1. **Airflow triggers cluster creation**: Creates `juno-metric-cluster-{timestamp}` with 1 master + 4 worker `n1-standard-4` nodes (larger than Janus jobs due to daily volume).
   - From: Airflow
   - To: Dataproc API
   - Protocol: GCP API

2. **Airflow submits Spark job**: Main class `com.groupon.janus.ultron.JunoMetricsUltronRunner` with config file and artifact version.
   - From: Airflow
   - To: Dataproc Spark
   - Protocol: GCP Dataproc API

3. **Fetches valid country list**: `UltronJunoMetrics` calls `Dimensions.getCountries(janusMetadataServiceUri)` to retrieve the list of valid country codes from the Janus Metadata Service. This list is injected into the Juno SQL query's `$countries` filter clause.
   - From: `junoMetricRunner`
   - To: Janus Metadata Service (`janus-web-cloud.production.service`)
   - Protocol: HTTPS (via `jm_janusApiClient`)

4. **Queries Ultron for new Juno files**: Delta manager queries Ultron for GCS paths under `ultronJunoListPath` (`gs://.../juno/junoHourly/eventDate=$dates/platform=*/eventDestination=*/*`) that are newer than the high-watermark.
   - From: `ultronDeltaManager`
   - To: Ultron API
   - Protocol: HTTPS

5. **Processes files in batches**: New files are grouped into batches of `junoBatchSize` (default: 25). Each batch is processed as a single Spark query to balance parallelism and resource use.
   - From: `junoMetricEngine`
   - To: internal batch iterator
   - Protocol: direct

6. **Reads Juno Parquet data**: `spark.read.parquet(junoDirs)` reads all files in the batch; a temp view `junoHourly` is registered.
   - From: `junoMetricEngine`
   - To: GCS bucket
   - Protocol: GCS SDK (Spark)

7. **Executes Juno volume SQL**: `juno_volume.sql` is executed — groups by `eventDate`, `platform`, `event`, `clientPlatform`, `rawEvent`, `country` (filtered to valid countries), `pageApp`, `isBot`, `grouponVersion`; computes `total_cnt`, `bcookie_cnt`, `ok_cnt`, `warn_cnt`, and rule-violation statistics. The Spark application ID is added as a `job` column.
   - From: `junoMetricEngine`
   - To: In-memory Spark DataFrame
   - Protocol: Spark SQL

8. **Persists Juno volume cube**: Results collected as JSON, wrapped in `VolumeCubePersistRequest`, and posted to `/janus/api/v1/metrics/data_volume_cube_event_time` in chunks of 5.
   - From: `jm_janusApiClient`
   - To: Janus Metadata Service
   - Protocol: HTTPS POST (JSON)

9. **Updates Ultron watermark**: Files in the batch marked `SUCCEEDED` or `FAILED` after each batch's persist attempt.
   - From: `ultronDeltaManager`
   - To: Ultron API
   - Protocol: HTTPS

10. **Emits SMA metrics**: `gaugeJunoHourlyMetricFailure(0/1)` and `timeJunoHourlyMetricDuration(duration)` sent to SMA gateway after all batches complete.
    - From: `junoMetricEngine`
    - To: SMA metrics gateway
    - Protocol: HTTP (InfluxDB line protocol)

11. **Cluster deletion**: Trigger rule `all_done`; cluster deleted regardless of job outcome.
    - From: Airflow
    - To: Dataproc API
    - Protocol: GCP API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Juno volume cube POST fails (non-204) | `SMAMetrics.gaugeJunoHourlyMetricFailure(1)`; files in batch marked `FAILED` | Next daily run retries |
| GCS Parquet read exception | Logged; batch files marked `FAILED`; failure gauge = 1 | Retry on next daily run |
| Country list fetch fails | `UltronJunoMetrics` fails to initialize; entire job exits | Airflow task fails; email notification |
| All batches in a run fail | Distinct status list returned; watermark not advanced | Full retry on next daily run |

## Sequence Diagram

```
Airflow -> Dataproc: Create cluster (juno-metric-cluster-{ts}, 4 workers)
Airflow -> Dataproc: Submit Spark JAR (JunoMetricsUltronRunner)
JunoMetricsUltronRunner -> JanusWebCloud: GET valid country list (janusMetadataServiceUri)
JanusWebCloud --> JunoMetricsUltronRunner: Country codes list
JunoMetricsUltronRunner -> UltronAPI: GET watermark (juno_metrics-gcp)
UltronAPI --> JunoMetricsUltronRunner: New Juno file paths
loop [batches of 25]
  JunoMetricsUltronRunner -> GCS: spark.read.parquet(batch of 25 dirs)
  GCS --> JunoMetricsUltronRunner: Juno DataFrame
  JunoMetricsUltronRunner -> Spark: SQL: juno_volume.sql (with country filter)
  JunoMetricsUltronRunner -> JanusWebCloud: POST /janus/api/v1/metrics/data_volume_cube_event_time
  JanusWebCloud --> JunoMetricsUltronRunner: HTTP 204
  JunoMetricsUltronRunner -> UltronAPI: Mark batch files SUCCEEDED
end
JunoMetricsUltronRunner -> SMAGateway: gauge=0, duration=X
Airflow -> Dataproc: Delete cluster
```

## Related

- Architecture component view: `components-janus-metric-service`
- Related flows: [Janus Volume and Quality Cube Aggregation](janus-volume-quality-aggregation.md), [Ultron Watermark Delta Management](ultron-watermark-delta.md)
