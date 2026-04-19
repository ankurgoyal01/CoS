---
service: "magneto-gcp"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumMagnetoConfigStorage"
    type: "gcs"
    purpose: "Extract/load YAML config staging and raw Salesforce data files"
  - id: "tableLimitsMySQL"
    type: "mysql"
    purpose: "Watermark / table-limits state store and GDPR column registry"
  - id: "hiveOnDataproc"
    type: "hive"
    purpose: "Target analytical tables for Salesforce data"
---

# Data Stores

## Overview

magneto-gcp interacts with three categories of data stores. Google Cloud Storage acts as the shared staging layer between DAG steps: generated YAML configs and raw extracted Salesforce data files land here. A MySQL database (`table_limits` / `dwh_manage`) provides watermark state — the `consistent_before_soft` timestamp that defines the incremental extraction window — and also holds GDPR field exclusion metadata. The ultimate write destination is Apache Hive running on Google Cloud Dataproc, where Salesforce objects are represented as partitioned Hive tables.

---

## Stores

### GCS Config and Staging Storage (`continuumMagnetoConfigStorage`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Storage (GCS) |
| Architecture ref | `continuumMagnetoConfigStorage` |
| Purpose | Stage generated extract/load YAML configs and raw Salesforce extract files between Airflow tasks |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `gs://grpn-dnd-%s-etl-salesforce/config/<table>/extract_g<N>.yml` | Per-part extract config (SOX path) | `columns`, `sf_table`, `where`, `target_table`, `hive_db`, `delimiter` |
| `gs://grpn-dnd-%s-pipelines-salesforce/config/<table>/extract_g<N>.yml` | Per-part extract config (NON-SOX path) | `columns`, `sf_table`, `where`, `target_table`, `hive_db`, `delimiter` |
| `gs://grpn-dnd-%s-etl-salesforce/config/<table>/load.yml` | Load merge config | `wrk_table`, `tgt_table`, `inc_table`, `timestamp_col`, `merge_query` |
| `gs://<config_bucket>/config/<table>/<table><N>.txt` | Raw extracted Salesforce records (delimited text) | Salesforce object fields |
| `grpn-dnd-ingestion-magneto-%s-dataproc-staging` | Dataproc staging bucket | Dataproc job artifacts |
| `grpn-dnd-ingestion-magneto-%s-dataproc-temp` | Dataproc temp bucket | Dataproc job temp files |
| Composer DAGs bucket (`COMPOSER_DAGS_BUCKET`) | Airflow DAG source files for each environment | Generated Python DAG files |

#### Access Patterns

- **Read**: Orchestrator reads YAML extract configs per table/part during Dataproc Pig job execution via `zombie_runner`; `salesforce_simple.py` reads extract YAML to build SOQL queries.
- **Write**: ETL Compiler writes YAML configs; `salesforce_simple.py` writes paginated Salesforce records as delimited text blobs (up to 5,000 rows per page, composed via GCS multi-compose).
- **Indexes**: Not applicable (GCS object store).

---

### Table Limits MySQL (`tableLimitsMySQL`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `unknown_dwhmanagetablelimitsmysql_bab098d9` (stub in DSL) |
| Purpose | Watermark state for incremental load windows; GDPR field exclusion registry |
| Ownership | shared (owned by `dwh_manage` / `megatron`) |
| Migrations path | Not applicable (owned externally) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `dwh_manage.table_limits` | Tracks load watermarks per table | `table_name`, `schema_name`, `consistent_before_soft`, `consistent_before_hard`, `min_partition_id`, `max_partition_id`, `content_group` |
| `gdpr_field_info` | Lists GDPR-excluded columns per Salesforce source | `table_name`, `source_name`, `field_name` |
| `megatron_validation_params` | Validation run config per table | `id`, `source_table_id`, `service_name`, `table_name`, `is_executable` |
| `megatron_validation_stats` | Stores validation row counts | `table_id`, `record_count`, `created_at` |
| `job_instances` | Tracks completed ETL job runs | `job_identifier`, `started_at`, `stopped_at`, `source_name`, `partition_id` |

#### Access Patterns

- **Read**: Replicator reads `consistent_before_soft` to compute the extraction start window; reads `gdpr_field_info` to exclude GDPR columns; Validation Runner reads `megatron_validation_params`.
- **Write**: Load phase (`update_tl` step) updates `table_limits.consistent_before_soft` and `consistent_before_hard`; inserts into `job_instances`; Validation Runner inserts into `megatron_validation_stats`.
- **Connection**: ODBC-style config retrieved from GCP Secret Manager (secret `magneto-odbc`), DSN key `table_limits`.

---

### Hive on Dataproc (`hiveOnDataproc`)

| Property | Value |
|----------|-------|
| Type | Apache Hive (on Google Cloud Dataproc) |
| Architecture ref | `cloudPlatform` (external — managed GCP) |
| Purpose | Target analytical store for incremental Salesforce object data |
| Ownership | shared (managed by GCP Dataproc Metastore) |
| Migrations path | Automatic: ETL Compiler issues `ALTER TABLE ... ADD COLUMNS CASCADE` for schema drift |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `salesforce.<table>` | Primary Hive target table per Salesforce object | All Salesforce object fields, `partition_id` (bigint), `dwh_active` (int) |
| `salesforce.<table>_inc` | Incremental/audit table for each load | `id`, `dwh_valid_from`, `dwh_valid_before`, `dwh_created_at`, all data fields |
| `salesforce.<table>_stg<N>` | Staging tables per extract part (transient) | Subset of columns for a given extract part |
| `salesforce.stg_<table>` | Work table for merge (external, partitioned) | Full column set with `partition_id`, `dwh_active` partitions |

#### Access Patterns

- **Read**: Hive ETL Compiler reads current table DDL via `gcloud dataproc jobs submit hive ... DESC <table>` to detect schema drift.
- **Write**: `LOAD DATA INPATH` loads raw extracted text into staging tables; `INSERT OVERWRITE ... SELECT ... INNER JOIN` builds work tables; `FULL OUTER JOIN` merge populates the target table at partition 19450509.
- **Indexes**: Hive partitions by `partition_id` (bigint, timestamp-derived) and `dwh_active` (int). SOX tables use `grp-dpms-*-metastore-etl`; NON-SOX use `grpn-dpms-*-pipelines`.

---

## Caches

> No evidence found in codebase. magneto-gcp does not use Redis, Memcached, or any explicit in-process cache layer.

## Data Flows

1. ETL Compiler writes extract YAML configs to GCS (`config_bucket/config/<table>/extract_g<N>.yml`).
2. Dataproc Pig job runs `zombie_runner extract` (or `salesforce_simple.py` for simple-Salesforce mode), pulling from Salesforce and writing delimited text to GCS.
3. Dataproc Pig job runs `zombie_runner load`, executing Hive `LOAD DATA INPATH` to move GCS files into staging Hive tables.
4. Merge SQL (`FULL OUTER JOIN`) writes final records into the target partitioned Hive table.
5. `table_limits.consistent_before_soft` is updated via `update_tl` SQL step.
6. Metrics on table lag are read from `dwh_manage.table_limits` and pushed to InfluxDB every 30 minutes.
