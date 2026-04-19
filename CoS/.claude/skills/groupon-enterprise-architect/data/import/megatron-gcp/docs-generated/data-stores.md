---
service: "megatron-gcp"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "etl_process_status_db"
    type: "mysql"
    purpose: "ETL run tracking and status management"
  - id: "gcs_staging"
    type: "gcs"
    purpose: "Dataproc staging artifacts, config, and DAG files"
  - id: "bigquery"
    type: "bigquery"
    purpose: "Ingestion destination and data-quality validation target"
  - id: "teradata"
    type: "teradata"
    purpose: "Final ingestion destination for analytics (via tungsten_merge)"
---

# Data Stores

## Overview

Megatron GCP is primarily an orchestration service and does not own a primary operational database. It reads and writes across four storage systems: a relational ETL-status database for run tracking, GCS buckets for Dataproc staging and config distribution, BigQuery as an ingestion target and data-quality comparison surface, and Teradata as the final analytics destination. Source data is always external (MySQL or PostgreSQL on-prem OLTP databases).

## Stores

### ETL Process Status Database (`etl_process_status_db`)

| Property | Value |
|----------|-------|
| Type | MySQL (Airflow connection `megatron_etl_process_status`) |
| Architecture ref | `continuumMegatronIngestionOrchestrator` |
| Purpose | Tracks per-table, per-run ingestion status; used by `check_status` and `final_status` tasks |
| Ownership | shared |
| Migrations path | Not managed in this repository |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `etl_process_status` | Records the state of each ingestion job run | `run_id`, `status` (`RUNNING`, `SUCCESS`, `FAILED`, `NOT_NEEDED`, `ALREADY_RUNNING`), `process_type`, `service_name`, `table_name`, `start_time` |
| `megatron_validation_params` | Stores per-table validation configuration for audit DAGs | `service_name`, `table_group_id`, `adapter_name`, `validation_column`, `is_executable` |

#### Access Patterns

- **Read**: `check_status` tasks query for `NOT_NEEDED` or `ALREADY_RUNNING` status to skip redundant runs; `full_load_check` compares sqoop vs full_load timestamps to decide whether a cluster is needed
- **Write**: `check_status` tasks update status to `FAILED` on job failure; pipeline sets status to `RUNNING` at job start and `SUCCESS` on completion via `tungsten_merge`
- **Indexes**: Not visible in this repository

---

### GCS Staging Buckets (`gcs_staging`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Storage |
| Architecture ref | `continuumMegatronGcp` |
| Purpose | Holds Dataproc staging artifacts, temporary job data, and service config files distributed to cluster nodes |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `grpn-dnd-ingestion-megatron-{env}-dataproc-staging` | Dataproc staging bucket (BUCKET) | Per-environment (dev/stable/prod) |
| `grpn-dnd-ingestion-megatron-{env}-dataproc-temp` | Dataproc temp bucket (TEMP_BUCKET) | Per-environment |
| `gs://{GCS_BUCKET}/dags/sox-inscope/megatron-gcp/megatron/{service}/` | Per-service config files (`tung.yml`, db conf YAML) distributed to clusters | Per-service |
| `gs://{GCS_BUCKET}/dags/sox-inscope/megatron-gcp/validation_megatron/validation_scripts/` | Audit validation Python scripts copied to Dataproc nodes | Shared |

#### Access Patterns

- **Read**: `copy_secrets_config` Pig jobs on Dataproc use `gsutil cp -r` to pull service configs and `tung.yml` to cluster nodes
- **Write**: CI/CD pipeline publishes generated DAG files and config to the Composer DAGs bucket (`COMPOSER_DAGS_BUCKET`)
- **Indexes**: Not applicable

---

### BigQuery (`bigquery`)

| Property | Value |
|----------|-------|
| Type | BigQuery |
| Architecture ref | `bigQuery` |
| Purpose | Ingestion destination (via datastream/CDC) and data-quality comparison surface |
| Ownership | external |
| Migrations path | Not managed in this repository |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `rt_vis_na_groupon_production.unit_price_summaries` | Example datastream destination table for data-quality validation | `id`, `updated_at` |
| `rt_vis_na_groupon_production.unit_price_summaries_backfill_test` | Example backfill table compared against datastream table | `id`, `updated_at` |

#### Access Patterns

- **Read**: BigQuery validation jobs (`bigquery_val`) query row counts and sample records for data-quality comparison; `table_comparison_framework.py` reads both datastream and backfill tables
- **Write**: CDC datastream jobs write ingested records; backfill jobs load historical data
- **Indexes**: Not applicable (BigQuery uses partitioning and clustering)

---

### Teradata (`teradata`)

| Property | Value |
|----------|-------|
| Type | Teradata |
| Architecture ref | `continuumMegatronIngestionOrchestrator` |
| Purpose | Final analytics destination for ingested MySQL/Postgres data (staging and final schemas) |
| Ownership | external |
| Migrations path | Not managed in this repository |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Staging schema (e.g., `staging`, `dev1_staging`, `gstg_staging`) | Intermediate landing zone during merge | Per-service, per-partition |
| Final schema (e.g., `meg_grp_prod`, `dev1_meg_grp_gcp`, `gstg_meg_grp_prod`) | Production analytics tables | Per-service |

#### Access Patterns

- **Read**: `td_val` audit jobs query row counts in Teradata via `validation_daily_td` script
- **Write**: `tungsten_merge` module writes merged and loaded records from Dataproc into staging then final Teradata schemas via `--stg_td_schema` and `--fin_td_schema` parameters
- **Indexes**: Not visible in this repository

## Caches

> No evidence found in codebase. No in-memory, Redis, or Memcached caches are used.

## Data Flows

Source OLTP data moves through the following stages:

1. **Sqoop extract**: `tungsten_merge` on Dataproc sqoop-extracts delta rows from MySQL/PostgreSQL into GCS staging
2. **Load**: Staged data is loaded from GCS into Teradata staging schema
3. **Merge**: Delta rows are merged into Teradata final schema
4. **Full load**: Periodic full-table reload into Teradata for schema-change recovery
5. **BigQuery CDC**: Parallel datastream pipeline (managed externally) continuously replicates to BigQuery
6. **Validation**: Audit DAGs cross-check counts across Hive (on Dataproc), MySQL/Postgres source, BigQuery, and Teradata to confirm consistency
