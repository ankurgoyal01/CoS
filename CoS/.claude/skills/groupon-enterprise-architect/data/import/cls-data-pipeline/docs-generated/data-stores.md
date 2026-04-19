---
service: "cls-data-pipeline"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumClsRealtimeHive"
    type: "hive-orc"
    purpose: "Persistent partitioned storage for normalized location event history and prediction outputs"
  - id: "continuumClsModelArtifactStore"
    type: "hdfs"
    purpose: "Storage for trained RandomForest model binaries used by prediction jobs"
---

# Data Stores

## Overview

The CLS Data Pipeline writes exclusively to HDFS-backed Hive tables and HDFS file paths. All output tables reside in the `grp_gdoop_cls_db` Hive database (production) or `cls_staging` (staging). Tables are stored in ORC format and partitioned by `record_date` (yyyy-MM-dd). Trained ML model binaries are persisted directly to HDFS paths. The pipeline does not own a relational database, cache, or blob storage outside of HDFS/Hive.

## Stores

### CLS Realtime Hive Tables (`continuumClsRealtimeHive`)

| Property | Value |
|----------|-------|
| Type | Hive / ORC (HDFS-backed) |
| Architecture ref | `continuumClsRealtimeHive` |
| Purpose | Persistent partitioned storage for normalized PTS, Proximity, GSS location events and ML prediction outputs |
| Ownership | owned |
| Migrations path | No migration files; DDL executed inline in streaming jobs via Spark SQL `CREATE TABLE IF NOT EXISTS` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `grp_gdoop_cls_db.pts_history_na_v2` | Stores normalized PTS events for the NA region | `consumer_id`, `device_id`, `device_token`, `clientrole`, `created`, `modified`, `event`, `rounded_latitude`, `rounded_longitude`, `entry_time`, `country_code`; partition: `record_date` |
| `grp_gdoop_cls_db.pts_history_emea_v2` | Stores normalized PTS events for the EMEA region | Same schema as `pts_history_na_v2`; partition: `record_date` |
| `grp_gdoop_cls_db.proximity_history_na` | Stores normalized Proximity geofence events for NA | `consumer_id`, `device_id`, `detect_time`, `country_code`, `rounded_latitude`, `rounded_longitude`, `entry_time`; partition: `record_date` |
| `grp_gdoop_cls_db.proximity_history_emea` | Stores normalized Proximity geofence events for EMEA | Same schema as `proximity_history_na`; partition: `record_date` |
| `grp_gdoop_cls_db.gss_history_na` | Stores normalized GSS division subscription events for NA | `consumer_id`, `event`, `device_id`, `division`, `country_code`, `brand`, `event_time`, `entry_time`; partition: `record_date` |
| `grp_gdoop_cls_db.gss_history_emea` | Stores normalized GSS subscription events for EMEA | Same schema as `gss_history_na`; partition: `record_date` |
| `grp_gdoop_cls_db.pipeline_monitoring_table` | Records active Spark job names, YARN application IDs, and registration timestamps | `job_time`, `job_name`, `job_app_id`; stored as ORC; overwritten per pipeline registration |
| `grp_gdoop_cls_db.pipeline_monitoring_temp_table` | Temporary staging table used during pipeline_monitoring_table upsert | Same schema as `pipeline_monitoring_table` |
| `grp_gdoop_cls_db.cls_prediction_test` | Output table for prediction job test runs | `device_id`, `consumer_id`, `predicted_lat`, `predicted_lng`, `ranking_version`, `tod`, `prediction_time`, `dow` |
| `grp_gdoop_cls_db.coalesce_data_es_stg3` | Upstream coalesced input table read by prediction jobs | `consumer_id`, `device_id`, `event_time`, `country_code`, `rounded_latitude`, `rounded_longitude`, `source_type`, `record_date`, `geohash4`, `geohash6`, `dow` |

#### Access Patterns

- **Read**: Batch prediction jobs (`PredictionJobV4`, `TrainModelV2`) query `grp_gdoop_cls_db.coalesce_data_es_stg3` via Spark SQL with date-range filters and `datediff` predicates. `PipelineMonitorJob` reads `pipeline_monitoring_table` to retrieve active job IDs.
- **Write**: Each streaming micro-batch (60-second intervals) appends a partition-keyed insert into the appropriate history table via `spark.sparkSession.sql("insert into ... PARTITION (record_date='$currentDate') select ...")`. Pipeline monitoring uses `SaveMode.Overwrite` on the temp table followed by `insertInto` on the main monitoring table.
- **Indexes**: Hive partitioning on `record_date` is the primary access optimization. `spark.hadoop.hive.enforce.bucketing=false` and `spark.hadoop.hive.enforce.sorting=false` are set at job submission time.

---

### CLS Model Artifact Store (`continuumClsModelArtifactStore`)

| Property | Value |
|----------|-------|
| Type | HDFS |
| Architecture ref | `continuumClsModelArtifactStore` |
| Purpose | Persistent storage of trained RandomForest regression model binaries for latitude and longitude prediction |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `/user/grp_gdoop_cls/rdfV2ModelLat` | Trained RandomForest regressor for latitude prediction | Spark MLlib `RandomForestModel` binary saved via `model.save(sparkContext, path)` |
| `/user/grp_gdoop_cls/rdfV2ModelLng` | Trained RandomForest regressor for longitude prediction | Spark MLlib `RandomForestModel` binary saved via `model.save(sparkContext, path)` |

#### Access Patterns

- **Read**: Prediction jobs load model binaries from HDFS using `RandomForestModel.load(sparkContext, path)` at job initialization.
- **Write**: `TrainModelV2` deletes existing model paths with `fs.delete(new Path(...), true)` before saving updated model binaries, effectively replacing the model in place.
- **Indexes**: Not applicable (binary file storage).

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `LookupStore` (configurable) | in-memory (LRU via `concurrentlinkedhashmap`) | Device/consumer lookup caching for enrichment operations | Configurable via `--cacheTtlInSeconds` (default: 259200 seconds / 3 days); 404 TTL: 300 seconds |

Note: The `LookupStore` abstraction supports a `DummyLookupStore` (no-op) and a Redis-backed implementation configured via `--redis_host` (default: `redis://redis-11798.snc1.raas-shared2-staging.grpn:11798`). Redis usage is optional and disabled by default in production spark-submit commands found in `OWNERS_MANUAL.md`.

## Data Flows

Raw Kafka events arrive per 60-second micro-batch window. Each streaming job filters and transforms records into normalized DataFrames, which are then written as Hive partition inserts. Concurrently, if `--enableKafkaOutput` is set, the `KafkaWriter` component publishes the same normalized records to the `cls_coalesce_pts_na` Kafka topic. A separate scheduled batch job reads from `coalesce_data_es_stg3` (written by the Optimus coalescing layer), trains or applies a RandomForest model, and writes predictions back to Hive. The `PipelineMonitorJob` runs independently to check YARN job health and alert on non-running pipelines.
