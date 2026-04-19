---
service: "deal-performance-bucketing-and-export-pipelines"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumDealPerformancePostgres"
    type: "postgresql"
    purpose: "Stores aggregated hourly and daily deal performance data for API access"
  - id: "hdfsCluster"
    type: "gcs"
    purpose: "Raw event input and bucketed Avro output storage"
---

# Data Stores

## Overview

The service reads raw deal event data from GCS and writes bucketed Avro output back to GCS. A separate export pipeline reads the GCS output and writes aggregated performance records to a GDS-managed PostgreSQL database. The PostgreSQL database is the persistence layer for the deal-performance-api-v2 service. There is no in-memory cache layer.

## Stores

### GCS / HDFS Object Storage (`hdfsCluster`)

| Property | Value |
|----------|-------|
| Type | GCS (Google Cloud Storage) / HDFS |
| Architecture ref | `hdfsCluster` |
| Purpose | Raw event input; bucketed Avro pipeline output |
| Ownership | shared (GCS bucket managed by grp-mars-mds; HDFS by gdoop) |
| Migrations path | Not applicable |

#### Key Paths (Production)

| Path | Purpose | Key Fields |
|------|---------|-----------|
| `gs://grpn-dnd-prod-analytics-grp-mars-mds/user/grp_gdoop_mars_mds/dps/events` | Raw deal events input (partitioned by `/date=*/hour=*`) | InstanceStoreAttributedDealImpression Avro records |
| `gs://grpn-dnd-prod-analytics-grp-mars-mds/user/grp_gdoop_mars_mds/dps/time_granularity=hourly/event_source={src}/date={date}/hour={hour}/event_type={type}` | Bucketed Avro output (AvroDealPerformance records) | timeBucket, brand, platform, eventType, dealId, bucketId, count |
| `hdfs://gdoop-namenode/user/grp_gdoop_platform-data-eng/janus` | A/B experiment instance data from Janus (partitioned by `/ds=*/hour=*`) | ExperimentInstance records (bcookie, experimentId) |

#### Access Patterns

- **Read**: `HDFSReadTransform` reads multiple date-hour partitioned directories per run (up to 7 hours back via `dirsToScanPerRunInHours`). Uses Hadoop FileSystem API via GCS connector (`GoogleHadoopFileSystem`).
- **Write**: `HDFSOutputDoFn` writes partitioned Avro data grouped by partition key (event_source, date, hour, event_type). Runs are idempotent — existing output is overwritten.

---

### Deal Performance PostgreSQL (`continuumDealPerformancePostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL 13 |
| Architecture ref | `continuumDealPerformancePostgres` |
| Purpose | Stores aggregated hourly and daily deal performance aggregates; serves deal-performance-api-v2 |
| Ownership | shared (GDS-managed; database `deal_perf_v2_prod` in production) |
| Migrations path | `src/main/resources/db/sql/up/` (V1–V6 migration scripts) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deal_performance_hourly` | Hourly aggregated deal performance counts | `batch_id`, `event_source`, `date_value`, `hour_value`, `event_type`, `time_bucket`, `deal_id`, `brand`, `platform`, `deal_option_id`, `gender`, `age`, `distance`, `purchaser_division_id`, `activation`, `campaign_id`, `experiment_id`, `count_type`, `dedup_hash`, `count_value` |
| `deal_performance_daily` | Daily aggregated deal performance counts | Same schema as hourly table |
| `deal_performance_hourly_batch` | Tracks batch IDs for hourly export runs | `event_source`, `date_value`, `hour_value`, `batch_id` |
| `deal_performance_daily_batch` | Tracks batch IDs for daily export runs | `event_source`, `date_value`, `hour_value`, `batch_id` |

#### Access Patterns

- **Read**: The DB cleaner reads batch IDs to identify and delete stale rows. The API layer (deal-performance-api-v2) reads by `deal_id` and time range.
- **Write**: `DealPerformanceJDBCWriteTransform` calls stored function `insert_or_ignore_deal_performance_hourly` / `insert_or_ignore_deal_performance_daily` — insert-or-ignore semantics using PostgreSQL unique constraint on `(deal_id, time_bucket, dedup_hash)`. `DealPerformanceExportPipeline` also upserts batch IDs after each successful export run and deletes rows from older batches.
- **Indexes**: Unique index on `(deal_id, time_bucket, dedup_hash)` for deduplication; index on `(date_value, hour_value)` for time-range queries; index on `(deal_id, time_bucket)` for deal lookups.

## Caches

> No evidence found in codebase. This service does not use a cache layer.

## Data Flows

1. Upstream instance store writes raw deal event Avro files to GCS (`dps/events`).
2. `UserDealBucketingPipeline` reads events, joins experiment data, buckets by user dimension, writes `AvroDealPerformance` Avro files to GCS (`dps/time_granularity=hourly/...`).
3. `DealPerformanceExportPipeline` reads the bucketed Avro files from GCS, aggregates by time granularity, and writes rows to `deal_performance_hourly` / `deal_performance_daily` in PostgreSQL.
4. `DealPerformanceDBCleaner` deletes rows from PostgreSQL older than a configured retention date.
5. Downstream Spark ranking jobs read bucketed Avro files directly from GCS; `deal-performance-api-v2` serves data from PostgreSQL via REST.
