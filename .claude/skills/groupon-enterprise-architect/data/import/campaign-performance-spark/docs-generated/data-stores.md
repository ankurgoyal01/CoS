---
service: "campaign-performance-spark"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumCampaignPerformanceDb"
    type: "postgresql"
    purpose: "Stores raw and aggregated real-time campaign performance metrics and Kafka consumer offsets"
  - id: "hdfsStorage"
    type: "hdfs-gcs"
    purpose: "Stores Spark structured streaming checkpoints, app status marker, and dedup cache Parquet files"
---

# Data Stores

## Overview

The service owns one PostgreSQL database (`continuumCampaignPerformanceDb`) for persistent metric storage and offset tracking, and uses HDFS/GCS distributed storage for three operational file sets: Spark streaming checkpoints, application status markers, and the dedup cache. The PostgreSQL database is managed by the GDS team with automated backups; HDFS/GCS paths are managed by the `grp_gdoop_pmp` Hadoop/GCS group.

## Stores

### Campaign Performance Postgres (`continuumCampaignPerformanceDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumCampaignPerformanceDb` |
| Purpose | Stores raw and aggregated real-time campaign performance metrics and Kafka consumer offsets |
| Ownership | owned |
| Migrations path | `src/main/resources/db/up/` (V1–V4) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `raw_rt_campaign_metrics` | Raw per-batch metric events before aggregation; deduplicated by batch | `metric_date`, `batch_key`, `campaign`, `metric_name`, `metric_value`, `created_at` |
| `rt_campaign_metrics` | Aggregated real-time campaign metrics (upserted via trigger) | `metric_date`, `campaign`, `email_sends`, `email_clicks`, `email_opens`, `push_sends`, `push_clicks` |
| `kafka_offsets` | Stores the last processed Kafka offsets per topic (JSONB); used for lag computation and DB-offset recovery | `topic`, `end_offset` (JSONB), `created_at` |

#### Access Patterns

- **Read**: `kafka_offsets` is queried by `KafkaLagChecker` to retrieve processed offsets; optionally read at startup with `use-offset=true` flag to resume from stored offsets instead of Spark checkpoints
- **Write**: `raw_rt_campaign_metrics` receives bulk inserts per micro-batch via `CampaignPerformanceDAO.addMetrics()`; a PostgreSQL trigger (`aggregate_raw_rt_campaign_metrics_trigger`) atomically upserts corresponding rows in `rt_campaign_metrics`; `DBCleaner` issues batched `DELETE` on `raw_rt_campaign_metrics` rows older than 7 days (1,000 rows per iteration, hourly)
- **Indexes**: Unique index on `raw_rt_campaign_metrics (metric_date, campaign, metric_name, batch_key)` for idempotent inserts; unique index on `rt_campaign_metrics (campaign, metric_date)`; secondary index on `raw_rt_campaign_metrics (created_at)` for retention cleanup; unique index on `kafka_offsets (topic)`

#### PostgreSQL Trigger Logic

Inserting a row into `raw_rt_campaign_metrics` fires `aggregate_raw_rt_campaign_metrics_trigger`, which performs an upsert loop on `rt_campaign_metrics`, incrementing the appropriate metric counter (`email_clicks`, `email_opens`, `push_clicks`, `email_sends`, `push_sends`) for the matching `(metric_date, campaign)` pair.

### HDFS / GCS Distributed Storage (`hdfsStorage`)

| Property | Value |
|----------|-------|
| Type | hdfs / google-cloud-storage |
| Architecture ref | `hdfsStorage` |
| Purpose | Spark streaming checkpoints, app status marker, and dedup cache Parquet files |
| Ownership | shared (managed by `grp_gdoop_pmp` group) |
| Migrations path | Not applicable |

#### Key Path Sets

| Path (production on-prem) | Purpose |
|--------------------------|---------|
| `hdfs://cerebro-namenode/user/grp_gdoop_pmp/campaign-perf-spark-outs/spark_checkpoint/` | Spark structured streaming checkpoint directory |
| `hdfs://cerebro-namenode/user/grp_gdoop_pmp/campaign-perf-spark-outs/app_status` | Status marker file containing Spark application ID; absence triggers graceful shutdown |
| `hdfs://cerebro-namenode/user/grp_gdoop_pmp/campaign-perf-spark-outs/dedup_cache` | Active dedup cache (Parquet, partitioned by `retention=long/short` and `writetime=<millis>`) |
| `hdfs://cerebro-namenode/user/grp_gdoop_pmp/campaign-perf-spark-outs/temp_dedup_cache` | Temporary write buffer; atomically renamed into `dedup_cache` on cache refresh |

| Path (GCP production) | Purpose |
|----------------------|---------|
| `gs://grpn-dnd-prod-analytics-grp-pmp/user/grp_gdoop_pmp/campaign-perf-spark-outs-staging/spark_checkpoint` | GCS checkpoint (GCP prod) |
| `gs://grpn-dnd-prod-analytics-grp-pmp/user/grp_gdoop_pmp/campaign-perf-spark-outs-staging/dedup_cache` | GCS dedup cache (GCP prod) |

#### Access Patterns

- **Read**: Dedup cache is read at every `CACHE_REFRESH_BATCH_INTERVAL` (every 10 batches) via `FileBackedDedupCacheManager.readDedupCache()`; Parquet files are filtered by `writetime` and `retention` partition values to apply TTL
- **Write**: `addToCache()` writes new `CampaignMetric` records to `temp_dedup_cache` in Parquet append mode, coalesced to 1 file per call; `syncCache()` atomically renames `temp_dedup_cache` to a timestamped partition under `dedup_cache`

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `dedup_cache` (HDFS/GCS Parquet) | Distributed file-backed | Deduplicates `(campaign, metric, user)` tuples across time windows to prevent double-counting | 24 hours for `emailClick`, `emailOpen`, `pushClick` (`long` retention); 10 minutes for `emailSend`, `pushSend` (`short` retention) |
| In-memory Spark Dataset cache | Spark in-memory RDD/Dataset persist | Holds loaded `dedup_cache` Dataset in Spark executor memory between batches to avoid repeated HDFS reads | Refreshed every 10 micro-batches (`CACHE_REFRESH_BATCH_INTERVAL = 10`) |

## Data Flows

1. Janus Kafka events arrive as Avro bytes on `janus-all`.
2. Spark reads and transforms events into `CampaignMetric` records.
3. `StreamingBatchProcessor` deduplicates the batch Dataset against the in-memory dedup cache (left-anti join).
4. Deduplicated records are written to `raw_rt_campaign_metrics` (JDBC); the PostgreSQL trigger upserts `rt_campaign_metrics`.
5. Deduplicated records are also appended to `temp_dedup_cache` (Parquet on HDFS/GCS).
6. Every 10 batches, `temp_dedup_cache` is promoted to a new timestamped partition in `dedup_cache`; the in-memory cache is reloaded from `dedup_cache` with TTL filtering applied.
7. `DBCleaner` periodically deletes `raw_rt_campaign_metrics` rows beyond the 7-day retention window.
