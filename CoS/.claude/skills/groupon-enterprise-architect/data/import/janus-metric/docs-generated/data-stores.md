---
service: "janus-metric"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "gcs-janus-parquet-inputs"
    type: "gcs"
    purpose: "Input: Janus/Juno/raw event Parquet files produced by upstream ingestion pipelines"
  - id: "janus-web-cloud-db"
    type: "mysql (via janus-web-cloud API)"
    purpose: "Output: Persistent store for volume, quality, audit, and cardinality cubes"
  - id: "ultron-state"
    type: "ultron"
    purpose: "Watermark state tracking which GCS files have been processed"
---

# Data Stores

## Overview

janus-metric does not own any databases directly. It reads from GCS Parquet buckets maintained by upstream ingestion pipelines, writes metric results through the Janus Metadata Service API (which owns an underlying MySQL database), and uses Ultron to track file-processing watermarks. All state ownership is delegated to external services.

## Stores

### GCS Parquet Input Buckets

| Property | Value |
|----------|-------|
| Type | Google Cloud Storage (GCS) — Parquet |
| Architecture ref | `continuumJanusMetricService` (reads from) |
| Purpose | Input event files produced by YATI raw ingestion and Janus/Juno processing pipelines |
| Ownership | external (owned by upstream ingestion pipelines) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Path Pattern | Purpose | Key Fields |
|----------------------|---------|-----------|
| `janus/ds=$dates/hour=$hours/*` | Janus validated event records | ds, hour, event, platform, clientPlatform, rawEvent, country, sourceTopicName, brand, pageApp, isBot, grouponVersion, rawHash, bcookie, validationStatus, validationString |
| `prod/juno/junoHourly/eventDate=$dates/platform=*/eventDestination=*/*` | Juno hourly event records | eventDate, platform, event, clientPlatform, rawEvent, country, pageApp, isBot, grouponVersion, bcookie, validationStatus, validationString |
| `yati_raw_sources/source=mobile_tracking/ds=$dates/hour=$hours/*` | Mobile tracking raw events | topic, rawEvent, ds, hour |
| `yati_raw_sources/source=tracky/ds=$dates/hour=$hours/*` | Tracky NA raw events | topic, rawEvent, ds, hour |
| `yati_raw_sources/source=msys_delivery/ds=$dates/hour=$hours/*` | Email delivery raw events | topic, rawEvent, ds, hour |
| `yati_raw_sources/source=grout_access/ds=$dates/hour=$hours/*` | Email click/open raw events | topic, rawEvent, ds, hour |
| `yati_raw_sources/source=rocketman_send/ds=$dates/hour=$hours/*` | Email send raw events | topic, rawEvent, ds, hour |
| `jupiter/ds=$date/hour=$hour` | Jupiter attribute data for cardinality analysis | All event attributes, yatiTimeMs, yatiUUID, eventDestination |

#### Access Patterns

- **Read**: Spark reads Parquet files in bulk via `spark.read.parquet(path)` for each hour directory; Ultron delta manager determines which paths are new
- **Write**: Not applicable — this service does not write to GCS buckets
- **Indexes**: Not applicable (file-based, partitioned by `ds` and `hour`)

---

### Janus Metadata Service (via API)

| Property | Value |
|----------|-------|
| Type | MySQL (accessed via `janus-web-cloud` HTTP API) |
| Architecture ref | `continuumJanusMetricService` (writes via `jm_janusApiClient`) |
| Purpose | Persistent storage for all aggregated metric cubes and cardinality results |
| Ownership | external (owned by `janus-web-cloud`) |
| Migrations path | Not applicable — schema managed by `janus-web-cloud` |

#### Key Entities (written by this service)

| Cube / Entity | Janus API Endpoint | Key Fields |
|--------------|-------------------|-----------|
| Janus volume cube | `POST /janus/api/v1/metrics/data_volume_cube` | ds, hour, event, platform, client_platform, raw_event, country, source_topic_name, brand, page_app, is_bot, groupon_version, total_cnt, distinct_raw_cnt, bcookie_cnt, ok_cnt, warn_cnt |
| Janus quality cube | `POST /janus/api/v1/metrics/data_quality_cube` | ds, hour, event, platform, client_platform, raw_event, country, brand, page_app, is_bot, groupon_version, attribute, rule_type, total_cnt |
| Janus catfood quality cube | `POST /janus/api/v1/metrics/data_quality_cube_catfood` | ds, hour, event, platform, client_platform, raw_event, country, page_app, is_bot, groupon_version, attribute, rule_type, total_cnt (filtered to specific clientIds) |
| Raw audit cube | `POST /janus/api/v1/metrics/data_audit_cube` | topic, rawEvent, ds, hour, count |
| Juno volume cube | `POST /janus/api/v1/metrics/data_volume_cube_event_time` | day, platform, event, client_platform, raw_event, country, page_app, is_bot, groupon_version, total_cnt, bcookie_cnt, ok_cnt, warn_cnt |
| Attribute cardinality | `POST /janus/api/v1/attribute/cardinality` | attributeName, cardinality (approx distinct count), topN values with counts |

#### Access Patterns

- **Read**: Not applicable — this service only writes
- **Write**: Batch POST requests chunked in groups of 5 records; HTTP 204 indicates success
- **Indexes**: Not applicable — managed by `janus-web-cloud`

---

### Ultron State (Watermark)

| Property | Value |
|----------|-------|
| Type | Ultron (distributed watermark state) |
| Architecture ref | `ultronDeltaManager` component of `continuumJanusMetricService` |
| Purpose | Tracks which GCS files have been processed (high-watermark per Ultron job name) |
| Ownership | external (owned by Ultron API service) |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: Queries Ultron API for current high-watermark before each Spark run to determine which files are new
- **Write**: Updates watermark state after successful file processing; failed files are marked `FAILED` and retried

## Caches

> No evidence found in codebase. This service uses no caching layer.

## Data Flows

1. Upstream ingestion pipelines write validated Parquet files to GCS partitioned by `ds` (date) and `hour`.
2. Airflow DAG triggers a Dataproc Spark job.
3. Ultron delta manager queries the Ultron API to find new files since last run (high-watermark comparison).
4. Spark reads the new Parquet files, executes SQL aggregations, and produces metric cube DataFrames.
5. Results are serialized to JSON and posted in chunks of 5 to the Janus Metadata Service API.
6. Ultron marks processed files as `SUCCEEDED` or `FAILED` based on API response codes.
