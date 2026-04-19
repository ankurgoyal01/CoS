---
service: "janus-metric"
title: "Janus Raw Event Audit Aggregation"
generated: "2026-03-03"
type: flow
flow_name: "janus-raw-event-audit"
flow_type: batch
trigger: "Airflow hourly schedule — janus-raw-metric DAG"
participants:
  - "continuumJanusMetricService"
  - "janusRawMetricRunner"
  - "janusRawMetricEngine"
  - "ultronDeltaManager"
  - "jm_janusApiClient"
architecture_ref: "components-janus-metric-service"
---

# Janus Raw Event Audit Aggregation

## Summary

This flow runs hourly via the `janus-raw-metric` Airflow DAG. It reads raw event files (originating from Kafka topics and archived to GCS by upstream YATI pipelines) for 11 logical source topics across NA and INTL regions. For each topic-and-event-type pair, it counts raw events and persists an audit cube to the Janus Metadata Service. Ultron watermarking is used independently per topic source to track processed files.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG `janus-raw-metric` — `schedule_interval = '@hourly'`
- **Frequency**: Hourly

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Cloud Composer | DAG scheduler | External |
| Google Cloud Dataproc | Spark execution environment | External |
| `janusRawMetricRunner` | Entry point — orchestrates 11 parallel Ultron runs per topic source | `continuumJanusMetricService` |
| `ultronDeltaManager` | Independent delta manager per source topic (11 instances) | `continuumJanusMetricService` |
| `janusRawMetricEngine` | Aggregates raw event counts per topic-event pair using Spark | `continuumJanusMetricService` |
| `jm_janusApiClient` | Posts audit cube to `/janus/api/v1/metrics/data_audit_cube` | `continuumJanusMetricService` |
| Janus Metadata Service (`janus-web-cloud`) | Stores raw event audit counts | External |

## Source Topics Processed

| Ultron Job Name (prod) | GCS Path Key | Event Types |
|-----------------------|-------------|-------------|
| `janus_raw_mobile_tracking-gcp` | `mobileTrackingAuditPath` | GRP3, GRP4, GRP5, GRP9, GRP14, GRP17, GRP24, GRP39 |
| `janus_raw_tracky-gcp` | `trackyFilePath` | `interaction-goal-purchase_server` |
| `janus_raw_tracky_lup1-gcp` | `trackyLup1FilePath` | `interaction-goal-purchase_server` |
| `janus_raw_tracky_json_nginx-gcp` | `trackyJsonNginxPath` | `interaction-goal-purchase`, `tracking-init` |
| `janus_raw_tracky_json_nginx_lup1-gcp` | `trackyJsonNginxLup1Path` | `interaction-goal-purchase`, `tracking-init` |
| `janus_raw_msys-gcp` | `msysDeliveryPath` | `msys_delivery` |
| `janus_raw_msys_lup1-gcp` | `msysDeliveryLup1Path` | `msys_delivery` |
| `janus_raw_grout-gcp` | `groutPath` | `email-click`, `email-open` |
| `janus_raw_grout_lup1-gcp` | `groutLup1Path` | `email-click`, `email-open` |
| `janus_raw_rocketman-gcp` | `rocketmanSendPath` | `email-send` |
| `janus_raw_rocketman_lup1-gcp` | `rocketmanSendLup1Path` | `email-send` |

## Steps

1. **Airflow triggers cluster creation**: Creates `janus-raw-metric-cluster-{timestamp}` with 1 master + 2 worker `n1-standard-4` nodes.
   - From: Airflow
   - To: Dataproc API
   - Protocol: GCP API

2. **Airflow submits Spark job**: Main class `com.groupon.janus.ultron.JanusMetricsRawUltronRunner` with config file and artifact version as arguments.
   - From: Airflow
   - To: Dataproc Spark
   - Protocol: GCP Dataproc API

3. **Loads configuration and initializes clients**: Reads `.properties` file, initializes `HttpJanusClient` with mutual TLS, and initializes SMA metrics environment.
   - From: `janusRawMetricRunner`
   - To: Properties classpath / SMA gateway
   - Protocol: classpath read / HTTP

4. **Iterates over 11 topic sources sequentially**: For each topic-event pair list, the runner builds an independent Ultron delta manager using a unique Ultron job name and path pattern (`ds=$dates/hour=$hours/*` suffix appended).
   - From: `janusRawMetricRunner`
   - To: `ultronDeltaManager` (new instance per topic)
   - Protocol: direct (Scala method call)

5. **Queries Ultron for new files (per topic)**: Each delta manager queries the Ultron API for new GCS files since the last high-watermark for that specific job name.
   - From: `ultronDeltaManager`
   - To: Ultron API (`ultron-api.production.service`)
   - Protocol: HTTPS

6. **Reads raw event files and counts per event type**: `UltronRawMetrics` reads the identified GCS Avro/Parquet files, filters by the target raw event name, and counts events per topic-event pair using Spark transformations.
   - From: `janusRawMetricEngine`
   - To: GCS bucket (raw event files)
   - Protocol: GCS SDK (Spark)

7. **Persists audit cube**: `JanusPersistor.persist()` calls `janusClient.persistAuditCube()` which POSTs the JSON payload to `/janus/api/v1/metrics/data_audit_cube`. HTTP 204 = success.
   - From: `jm_janusApiClient`
   - To: Janus Metadata Service
   - Protocol: HTTPS POST (JSON)

8. **Updates Ultron watermark**: Processed files marked `SUCCEEDED` or `FAILED` per topic.
   - From: `ultronDeltaManager`
   - To: Ultron API
   - Protocol: HTTPS

9. **Cluster deletion**: Runs after all topic sources complete, regardless of success or failure.
   - From: Airflow
   - To: Dataproc API
   - Protocol: GCP API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Audit cube POST returns non-204 | File marked `FAILED` in Ultron | Retried on next hourly run; failure logged |
| GCS file read exception | Exception propagated; file marked `FAILED` | Next run retries; SMA failure gauge = 1 |
| Ultron API unavailable for a topic | Exception propagates for that topic; job may continue others | Airflow task fails; email notification |

## Sequence Diagram

```
Airflow -> Dataproc: Create cluster (janus-raw-metric-cluster-{ts})
Airflow -> Dataproc: Submit Spark JAR (JanusMetricsRawUltronRunner)
JanusMetricsRawUltronRunner -> UltronAPI: GET watermark (janus_raw_mobile_tracking-gcp)
UltronAPI --> JanusMetricsRawUltronRunner: New file paths
JanusMetricsRawUltronRunner -> GCS: Read raw event files (mobile_tracking, ds=$dates/hour=$hours/*)
GCS --> JanusMetricsRawUltronRunner: Raw event DataFrame
JanusMetricsRawUltronRunner -> Spark: Count events per topic-event pair
JanusMetricsRawUltronRunner -> JanusWebCloud: POST /janus/api/v1/metrics/data_audit_cube
JanusWebCloud --> JanusMetricsRawUltronRunner: HTTP 204
JanusMetricsRawUltronRunner -> UltronAPI: Mark files SUCCEEDED
[Repeat for all 11 topic sources]
Airflow -> Dataproc: Delete cluster
```

## Related

- Architecture component view: `components-janus-metric-service`
- Related flows: [Janus Volume and Quality Cube Aggregation](janus-volume-quality-aggregation.md), [Ultron Watermark Delta Management](ultron-watermark-delta.md)
