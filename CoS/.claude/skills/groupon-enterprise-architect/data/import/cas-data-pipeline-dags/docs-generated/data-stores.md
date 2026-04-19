---
service: "cas-data-pipeline-dags"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "hiveWarehouse"
    type: "hive"
    purpose: "Primary analytical store — arbitration feature tables and raw engagement data"
  - id: "arbitrationPostgres"
    type: "postgresql"
    purpose: "Ranking and ML model upload target — receives processed arbitration scores and cadence outputs"
  - id: "gcpGcsBucket"
    type: "gcs"
    purpose: "Artifact repository (JAR files), audience path CSV outputs, Janus-YATI streaming output, Spark checkpoints"
---

# Data Stores

## Overview

`cas-data-pipeline-dags` uses three distinct data stores. Hive (via Dataproc Metastore) is the primary read/write store for raw engagement datasets and computed ML features. PostgreSQL (`arbitrationPostgres`) is the write target for arbitration ranking scores, send-time optimisation scores, and cadence decile uploads that feed real-time arbitration decisions. GCS buckets serve as the artifact repository for Spark assembly JARs, the landing zone for audience path CSV files, and the checkpoint/output location for Janus-YATI streaming.

---

## Stores

### Hive Warehouse (`hiveWarehouse`)

| Property | Value |
|----------|-------|
| Type | hive |
| Architecture ref | `hiveWarehouse` |
| Purpose | Read and write arbitration and reporting Hive tables containing raw engagement data and computed feature sets |
| Ownership | shared |
| Migrations path | Not applicable — table DDL managed outside this repo |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| NA email engagement tables | Stores sends, opens, clicks, orders, unsubscribes for NA email channel | user_id, campaign_id, business_group_id, event_date |
| EMEA email engagement tables | Stores sends, opens, clicks, orders, nob (dollars) for EMEA email | user_id, campaign_id, business_group_id, event_date |
| NA mobile engagement tables | Stores sends, clicks, orders, aggregated scores for NA mobile push | user_id, campaign_id, business_group_id, event_date |
| Feature tables (campaign / user / segment) | Intermediate ML feature outputs: campaign features, user BG-CG features, RF/CT segment features | campaign_id, user_id, segment_id, feature_date |
| BG-CG mapping tables | Business-group to campaign-group mapping tables used across pipelines | business_group_id, campaign_group_id |

#### Access Patterns

- **Read**: Spark jobs use `spark.sql` and HiveContext to read raw engagement data partitioned by date; earlier pipeline steps' output tables are read by downstream steps in the same DAG execution
- **Write**: Each Spark job writes results as Hive-managed or external tables partitioned by date using `df.write.mode("overwrite").saveAsTable(...)` patterns
- **Indexes**: Hive partition pruning on `event_date` / `startDate` arguments passed to each job

---

### Arbitration PostgreSQL (`arbitrationPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `arbitrationPostgres` |
| Purpose | Receives arbitration ranking scores, send-time optimisation scores, and cadence decile uploads for real-time serving by arbitration-service |
| Ownership | shared |
| Migrations path | Not applicable — schema managed outside this repo |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| NA mobile send time (STO) scores | Per-user send-time optimisation scores for mobile push | user_id, send_time_score, score_date |
| NA mobile cadence decile | Mobile push cadence decile rankings per user | user_id, cadence_decile, score_date |
| NA/EMEA STO email scores | Email send-time optimisation per user | user_id, send_time_score, score_date |
| NA/EMEA model ranking scores | Final ML model ranking output per user-campaign pair | user_id, campaign_id, rank_score, score_date |

#### Access Patterns

- **Read**: `DownloadAudiencePaths` Spark job reads audience config and path data via JDBC
- **Write**: Upload Spark jobs (`UploadNaMobileSendTimePG`, `UploadNaMobileCadenceDecilePG`, `ArbitrationUploadPipeline`) write via JDBC using `org.postgresql:postgresql:42.2.6`
- **Indexes**: Not discoverable from this repo

---

### GCS Bucket (`gcpGcsBucket`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `gcpGcsBucket` |
| Purpose | Hosts Spark assembly JAR artifacts, audience path CSV outputs, Janus-YATI Kafka streaming output, and Spark Structured Streaming checkpoints |
| Ownership | shared |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `gs://grpn-dnd-stable-analytics-grp-push-platform/user/janus-yati/` | Janus-YATI Muncher-format output from `arbitration_log` Kafka topic | partition by trigger batch |
| `gs://grpn-dnd-stable-analytics-grp-push-platform/mezzanine_checkpoint/region=na/source=arbitration_log` | Spark Structured Streaming checkpoint location for Janus-YATI | checkpoint offset metadata |
| `COMPOSER_DAGS_BUCKET` (env-specific) | GCS bucket where DAG files are stored and read by Cloud Composer | DAG Python files, config JSON files |
| Spark JAR artifact path (`artifact_base_path`) | Assembly JAR resolved by `@{artifact_base_path}/com/groupon/cas-data-pipelines-dags_2-4-8_2.12/...` | versioned JAR artifacts |

#### Access Patterns

- **Read**: Dataproc cluster init scripts, Spark assembly JARs, and audience path input files are read from GCS at cluster startup and job submission
- **Write**: Janus-YATI streaming job writes batched `arbitration_log` records in Muncher format to the `janus-yati/` prefix; audience path download job writes CSV outputs to GCS paths
- **Indexes**: Not applicable (object storage)

---

## Caches

> No evidence found in codebase. No caching layer is used.

## Data Flows

1. Raw engagement logs (email/mobile) land in Hive tables (ingested by upstream processes outside this repo).
2. Data pipeline DAGs read raw Hive tables, transform and aggregate data, and write intermediate feature tables back to Hive.
3. Feature pipeline DAGs read intermediate Hive feature tables and compute final ML features.
4. Upload pipeline DAGs read final features from Hive and write ranking/STO scores to `arbitrationPostgres` via JDBC.
5. Audience path download pipeline reads audience configs from arbitration-service and AMS APIs, then writes CSV outputs to GCS.
6. Janus-YATI DAG reads the `arbitration_log` Kafka topic as a Spark Structured Streaming job and writes Muncher-format records to a GCS bucket for downstream analytics.
