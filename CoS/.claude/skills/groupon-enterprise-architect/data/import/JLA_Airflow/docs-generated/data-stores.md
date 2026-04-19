---
service: "JLA_Airflow"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumJlaAirflowMetadataDb"
    type: "postgresql"
    purpose: "Airflow scheduler and DAG run state"
  - id: "teradata-dwh_fsa_prd"
    type: "teradata"
    purpose: "JLA data mart — primary ETL target and source"
  - id: "bigQueryWarehouse"
    type: "bigquery"
    purpose: "Analytics dataset publication"
  - id: "gcs-composer-bucket"
    type: "gcs"
    purpose: "DAG file storage and Kyriba download staging"
---

# Data Stores

## Overview

JLA Airflow interacts with four data stores: a Composer-managed PostgreSQL instance for Airflow internal state, the Teradata data warehouse (`dwh_fsa_prd`) as both source and primary ETL target, BigQuery for analytics dataset publication, and Google Cloud Storage (GCS) buckets managed by Google Cloud Composer for DAG files and transient file staging (Kyriba downloads, PSP files).

## Stores

### Airflow Metadata Store (`continuumJlaAirflowMetadataDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumJlaAirflowMetadataDb` |
| Purpose | Stores DAG run state, task instance metadata, XCom values, Variables, Connections, and scheduler bookkeeping |
| Ownership | owned (Composer-managed) |
| Migrations path | Managed by Airflow/Composer internally |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `dag_run` | Records each DAG execution | `dag_id`, `run_id`, `run_type`, `state`, `conf` |
| `task_instance` | Records each task execution within a DAG run | `dag_id`, `task_id`, `state`, `execution_date` |
| `xcom` | Passes values between tasks within a run | `dag_id`, `task_id`, `key`, `value` |
| `variable` | Stores runtime configuration variables | `key`, `val` |
| `connection` | Stores external connection credentials | `conn_id`, `host`, `login` |

#### Access Patterns

- **Read**: Scheduler reads task state and XCom values per DAG run
- **Write**: Tasks push XCom values (`process_id`, `process_status`, `start_date`); scheduler writes run state transitions
- **Indexes**: Managed by Airflow/Composer internally

---

### Teradata Data Warehouse (`dwh_fsa_prd`)

| Property | Value |
|----------|-------|
| Type | teradata |
| Architecture ref | `unknown_teradata_platform` (stub in local model) |
| Purpose | Primary ETL source and target for JLA data mart tables; also serves DB Gatekeeper/Watchman governance |
| Ownership | shared (FSA schemas within corporate Teradata) |
| Migrations path | Managed via DB Gatekeeper DAG (`db-gatekeeper`) using raw Git URL scripts |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `acct_jla_run_process` | ETL pipeline run tracking | `id` (process UUID), `start_dt`, `status` |
| `acct_jla_proc_id_parm_tmp` | Temporary parameter table for process UUID propagation | `run_process_id` |
| `acct_jla_ads_billing` | Raw ads billing data | billing records |
| `acct_jla_invoice_audit` | Invoice audit records | audit trail |
| `acct_jla_invoice` / `acct_jla_invoice_item` | Staged invoices for NetSuite | invoice header and line items |
| `acct_jla_customer_staging` / `acct_jla_customer` | Staged and confirmed customer records for NetSuite AR | customer identity, staging status |
| `acct_jla_eba_rulesets` | Event-based accounting rule definitions | ruleset ID, active flag |
| `acct_jla_eba_options` | EBA configuration options | options per ruleset |
| `meta_db_gatekeeper_log` | DB Gatekeeper execution audit log | `gk_id`, `file_name`, `process_id` |
| `meta_db_gatekeeper_log_query` | Per-query execution log within a Gatekeeper run | `gk_id`, `q_id`, `start_dt`, `end_dt` |
| `meta_db_watchman_object` | Historicized database object inventory (SCD) | `object_id`, `db`, `name`, `kind`, `valid_flag` |
| `meta_db_watchman_object_show` | DDL show output for changed objects | `object_id`, `show_chunk`, `show_result` |
| `meta_db_watchman_object_index` | Index metadata per object | `object_id`, `indexnumber` |
| `meta_db_watchman_object_stats` | Optimizer statistics per object | `object_id`, `id` |
| `meta_db_watchman_object_usage` | Table/object usage history | `object_id`, usage date |
| `meta_db_watchman_roles` | Database role and access right inventory (SCD) | `username`, `rolename`, `accessright` |
| `meta_db_watchman_alerts` | Watchman alert log | `alert_name`, `alert_message`, `created_at` |
| `acct_jla_ns_payment_update_stats` | Kyriba payment clearing statistics view | payment stats |
| `acct_jla_ns_payment_update_failure` | Kyriba payment clearing failure view | failure records |

#### Access Patterns

- **Read**: ETL DAGs query source tables (orders, campaigns, opportunities, customer data) via `TeradataOperator` and `TeradataEngine`
- **Write**: ETL steps INSERT/DELETE into JLA mart tables; DB Watchman inserts SCD records; DB Gatekeeper executes arbitrary DDL/DML
- **Indexes**: DB Watchman (`retrieve_object_index`) tracks index changes via SCD type-2 logic

---

### BigQuery Analytics Warehouse (`bigQueryWarehouse`)

| Property | Value |
|----------|-------|
| Type | bigquery |
| Architecture ref | `bigQueryWarehouse` |
| Purpose | Target for published JLA analytics datasets; read in some pipeline steps |
| Ownership | shared (Groupon analytics platform) |
| Migrations path | No evidence found in codebase |

#### Access Patterns

- **Read**: Certain DAGs read analytics source data from BigQuery via `BigQueryEngine`
- **Write**: Final ETL step (8.1) publishes JLA dataset to BigQuery

---

### GCS Composer Bucket (transient file store)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | Deployed as `COMPOSER_DAGS_BUCKET` per environment |
| Purpose | Hosts DAG Python files; staging area for Kyriba payment clearing downloads; PSP settlement file staging |
| Ownership | owned (per-environment Composer bucket) |
| Migrations path | Not applicable |

#### Access Patterns

- **Write**: Deploybot copies DAG files from Git to `COMPOSER_DAGS_BUCKET` on deployment
- **Read/Write**: Kyriba DAG downloads SFTP files to `/home/airflow/gcs/data/kyriba/downloads/` and archives to `/home/airflow/gcs/data/kyriba/archive/`

## Caches

> No evidence found in codebase of any cache layer (Redis, Memcached, or in-memory cache).

## Data Flows

- ETL pipeline steps 1–8.1 run sequentially; each step reads from Teradata source schemas and writes transformed records into `dwh_fsa_prd` JLA mart tables.
- Step 8.1 (publish) conditionally writes the finalised dataset to BigQuery based on `origin_run_type` (scheduled vs. manual).
- Kyriba SFTP files are downloaded to GCS, processed into Teradata, and archived within GCS.
- DB Watchman runs nightly to harvest database object metadata into SCD tracking tables in Teradata.
