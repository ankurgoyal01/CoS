---
service: "janus-metric"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

janus-metric has four external dependencies: the Janus Metadata Service API (`janus-web-cloud`) for persisting metric cubes, the Ultron API for watermark state management, GCS for Parquet input files, and the SMA metrics gateway (InfluxDB via Telegraf) for operational telemetry. Internally, it integrates with one Groupon service: Janus Metadata Service. All outbound calls use HTTPS. The service makes no inbound connections — it is trigger-only via Airflow.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Janus Metadata Service (`janus-web-cloud`) | HTTPS / REST | Persist volume, quality, audit, and cardinality cubes | yes | `continuumJanusMetricService` -> Janus API |
| Ultron API | HTTPS | Watermark state reads/writes for delta file tracking | yes | `ultronDeltaManager` |
| GCS (Google Cloud Storage) | GCS SDK | Read Parquet input files (Janus, Juno, raw sources, Jupiter) | yes | `continuumJanusMetricService` -> GCS |
| SMA Metrics Gateway (Telegraf/InfluxDB) | HTTP (InfluxDB line protocol) | Publish pipeline health gauges and duration timers | no | `continuumJanusMetricService` -> `metricsStack` |

### Janus Metadata Service (`janus-web-cloud`) Detail

- **Protocol**: HTTPS (REST, JSON body)
- **Base URL (prod)**: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` (config key: `endpoint`)
- **Auth**: Mutual TLS — JKS keystore at `/var/groupon/janus-yati-keystore.jks`, truststore at `/var/groupon/truststore.jks`
- **Purpose**: Receive aggregated Janus volume/quality/audit/cardinality cubes and Juno volume cubes; HTTP 204 = success
- **Endpoints called**:
  - `POST /janus/api/v1/metrics/data_volume_cube`
  - `POST /janus/api/v1/metrics/data_quality_cube`
  - `POST /janus/api/v1/metrics/data_quality_cube_catfood`
  - `POST /janus/api/v1/metrics/data_audit_cube`
  - `POST /janus/api/v1/metrics/data_volume_cube_event_time`
  - `POST /janus/api/v1/attribute/cardinality`
  - `GET /janus/api/v1/{getRequetUri}` (generic GET for metadata lookups)
- **Failure mode**: Returns `ResponseCode.Failure`; Ultron marks files as `FAILED`; SMA failure gauge set to 1; next Airflow run retries unprocessed files
- **Circuit breaker**: No evidence found in codebase

### Ultron API Detail

- **Protocol**: HTTPS
- **Base URL (prod)**: `ultron-api.production.service` (config key: `ultronUrl`)
- **Auth**: Inherits JKS keystore / truststore from `SecureJanusMDSUtil`
- **Purpose**: Track high-watermark of processed GCS files per Ultron job name; prevents duplicate processing across DAG runs
- **Job names (prod)**: `janus_volume_and_quality_metrics-gcp`, `juno_metrics-gcp`, `janus_raw_mobile_tracking-gcp`, `janus_raw_tracky-gcp`, `janus_raw_tracky_lup1-gcp`, `janus_raw_tracky_json_nginx-gcp`, `janus_raw_tracky_json_nginx_lup1-gcp`, `janus_raw_msys-gcp`, `janus_raw_msys_lup1-gcp`, `janus_raw_grout-gcp`, `janus_raw_grout_lup1-gcp`, `janus_raw_rocketman-gcp`, `janus_raw_rocketman_lup1-gcp`
- **Failure mode**: Watermark state unavailable; job fails to identify new files; DAG task fails with exception
- **Circuit breaker**: No evidence found in codebase

### GCS (Google Cloud Storage) Detail

- **Protocol**: GCS SDK (accessed through Spark's `spark.read.parquet()` and Ultron file listing)
- **Base URL / SDK**: GCS bucket paths (e.g., `gs://grpn-dnd-prod-pipelines-pde/...`, `gs://grpn-dnd-prod-pipelines-yati-raw/...`)
- **Auth**: Dataproc service account `sa-dataproc-nodes@prj-grp-janus-prod-0808.iam.gserviceaccount.com` with scope `https://www.googleapis.com/auth/cloud-platform`
- **Purpose**: Source of all Parquet event data — Janus validated events, Juno hourly events, YATI raw topic files, Jupiter attribute data
- **Failure mode**: Spark job fails with file read exception; Ultron marks files as `FAILED`
- **Circuit breaker**: No evidence found in codebase

### SMA Metrics Gateway (Telegraf/InfluxDB) Detail

- **Protocol**: HTTP (InfluxDB line protocol via OkHttp client)
- **Base URL (prod)**: `http://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` (config key: `metricsGateway`)
- **Host header (prod)**: `telegraf.production.service` (config key: `metricsHostHeader`)
- **Auth**: No authentication — internal network only
- **Purpose**: Emit `custom.data.janus-metric-failure` gauge, `custom.data.juno-metric-failure` gauge, `custom.data.janus-metric-duration` timer, `custom.data.juno-metric-duration` timer per Spark run
- **Failure mode**: Logged error; does not fail the Spark job
- **Circuit breaker**: No evidence found in codebase; OkHttp batch flush with exception handler

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Janus Metadata Service (`janus-web-cloud`) | HTTPS | Fetches valid country list for Juno country-filtering query via `janusMetadataServiceUri` | `jm_janusApiClient` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. janus-metric is a batch sink service; it is invoked by Airflow DAGs and does not expose a consumable interface. Downstream consumers of its metric output read from the Janus Metadata Service.

## Dependency Health

- Janus API calls use chunked POST (5 records per chunk) with per-chunk success checking; a single chunk failure causes the file to be marked `FAILED` and retried on the next run
- Ultron throttle value controls concurrency (`ultronThrottleValue=3` for Janus jobs; `junoUltronThrottleValue=500` for Juno jobs)
- SMA metrics batch-flush every 10 seconds with shutdown hook to drain remaining metrics
- No retry logic or circuit breaker patterns are configured beyond Ultron's watermark-based retry
