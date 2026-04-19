---
service: "pre_task_tracker"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumPreTaskTrackerAirflowDb"
    type: "postgresql"
    purpose: "Airflow pipeline metadata (task states, DAG run history)"
  - id: "continuumPreTaskTrackerMysqlDb"
    type: "mysql"
    purpose: "PRE tracking tables, runbook mappings, and table limit configs"
  - id: "megatronDb"
    type: "mysql"
    purpose: "Megatron ETL process status (running instance checks)"
  - id: "dwhManageDb"
    type: "mysql"
    purpose: "table_limits_view for data freshness SLA enforcement"
  - id: "ckodDb"
    type: "mysql"
    purpose: "EDW and RM SLA job detail and definition tables"
  - id: "teradataDb"
    type: "teradata"
    purpose: "Source table freshness metrics via dwh_manage.table_limits_view"
  - id: "gcsDagBucket"
    type: "gcs"
    purpose: "DAG Python file storage managed and cleaned by dag_cleanup DAG"
---

# Data Stores

## Overview

`pre_task_tracker` reads from and writes to multiple data stores. The primary read source is the Airflow PostgreSQL metadata database (pipeline execution state). The primary write destinations are the PRE Monitoring MySQL database (tracking tables and runbook mappings) and the CKOD MySQL database (SLA entries). The service also queries Megatron MySQL, DWH Manage MySQL, and Teradata for data freshness information, and reads/deletes files from GCS.

## Stores

### Airflow Metadata Database (`continuumPreTaskTrackerAirflowDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumPreTaskTrackerAirflowDb` |
| Purpose | Stores Airflow DAG definitions, task instance states, and DAG run history; queried to detect failed, running, queued, and skipped tasks |
| Ownership | shared |
| Migrations path | Managed by Apache Airflow internally |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `task_instance` | Current and historical task execution state | `state`, `task_id`, `dag_id`, `start_date`, `end_date`, `run_id`, `operator`, `try_number`, `queued_dttm` |
| `dag_run` | DAG execution run records | `dag_id`, `run_id`, `state`, `execution_date`, `start_date`, `queued_at` |
| `dag` | DAG definitions and metadata | `dag_id`, `fileloc`, `is_paused` |
| `import_error` | DAGs that failed to import (parse errors) | `filename`, `timestamp` |

#### Access Patterns

- **Read**: Queries `task_instance` joined to `dag_run` and `dag` to find failed, running, queued, and consecutively-skipped tasks scoped by org file path pattern
- **Write**: No direct writes; Airflow framework manages all state writes
- **Indexes**: Standard Airflow indexes on `dag_id`, `run_id`, `state`

---

### PRE Monitoring Database (`continuumPreTaskTrackerMysqlDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumPreTaskTrackerMysqlDb` |
| Purpose | Stores PRE-managed tracking tables for errored/paused DAG cleanup, runbook URL-to-DAG mappings, and Teradata table limit configurations |
| Ownership | owned |
| Migrations path | DDL maintained in code comments within `dag_cleanup.py` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `pre_import_error_tracker` | Tracks DAG files with persistent import errors for cleanup | `dag_id`, `last_updated`, `to_be_deleted_on`, `instance_name` |
| `pre_paused_dag_tracker` | Tracks paused DAG files scheduled for deletion after 30 days | `dag_id`, `last_updated`, `to_be_deleted_on`, `instance_name` |
| `pre_runbook_dag_mapping` | Maps pipeline DAG IDs to their Google Drive runbook URLs | `pipeline`, `runbook_url`, `project_id`, `orchestrator_type` |
| `td_table_limits` | Teradata table monitoring configuration (table name, content group, delay minutes, EOD jobs) | `table_name`, `content_group`, `delay_minutes`, `eod_jobs` |

#### Access Patterns

- **Read**: `dag_cleanup.py` reads existing tracker entries to avoid duplicate inserts; `hooks.py` reads `td_table_limits` to get table monitoring configuration
- **Write**: Insert new errored/paused DAG tracker entries; delete resolved entries; insert runbook URL mappings; commit changes via `MySqlHook`
- **Indexes**: No evidence found in codebase for explicit index definitions

---

### Megatron ETL Database (`megatronDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `edw` |
| Purpose | Queried to check whether a Megatron load process is currently running for a given table, to avoid false-positive lag alerts |
| Ownership | external |
| Migrations path | Managed by Megatron team |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `etl_process_status` | Current Megatron ETL process run status | `service_name`, `target_table_name`, `process_type`, `status`, `start_time` |

#### Access Patterns

- **Read**: `check_running_instance()` in `megatron_check.py` queries `etl_process_status` filtered by `service_name`, `target_table_name`, `process_type`, and `status = 'RUNNING'`

---

### DWH Manage Database (`dwhManageDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `edw` |
| Purpose | Provides `table_limits_view` which contains the `consistent_before_hard` timestamp used for data freshness SLA evaluation |
| Ownership | external |
| Migrations path | Managed by Data Warehouse team |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `dwh_manage.table_limits` | Raw table limits for content groups | `content_group`, `schema_name`, `table_name`, `consistent_before_hard` |
| `dwh_manage.table_limits_view` | View of table limits with freshness timestamps | `schema_name`, `content_group`, `table_name`, `consistent_before_hard`, `measured_at` |

#### Access Patterns

- **Read**: `fetch_max_data_available()` queries `consistent_before_hard` from `table_limits` filtered by `content_group`, `schema_name`, `table_name`; `hooks.py` `TeradataHook` queries `table_limits_view`

---

### CKOD Database (`ckodDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumPreTaskTrackerMysqlDb` |
| Purpose | Stores EDW and RM SLA job detail entries and SLA definitions used to populate the EDW/RM SLA dashboards |
| Ownership | shared |
| Migrations path | Managed externally by the CKOD team |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `EDW_SLA_JOB_DETAIL` | Individual job run SLA status records for pipelines | `JOB_DETAIL_KEY`, `JOB_NAME`, `SLA_UTC`, `run_id`, `state`, `start_date`, `end_date`, `sla_status`, `delay_time` |
| `RM_SLA_JOB_DETAIL` | Revenue Management job SLA status records | same schema as `EDW_SLA_JOB_DETAIL` |
| `EDW_SLA_DEFINITION` | SLA target definitions keyed by job | `SLA_DEFINITION_KEY`, `SUBJECT_AREA`, `JOB_NAME`, `SLA_UTC` |
| `RM_SLA_DEFINITION` | RM SLA definitions | same schema as `EDW_SLA_DEFINITION` |
| `keboola_runbook_flow_mapping` | Maps Keboola flow IDs to Google Drive runbook URLs | `runbook_url`, `flow_id`, `project_id` |

#### Access Patterns

- **Read**: `fetch_all_qualified_incomplete_edw_sla_entries()` reads incomplete SLA entries for today's date; `fetch_sla_definitions()` reads all active SLA definitions
- **Write**: Inserts new SLA entries for the day; updates entries with `running`, `success`, `failed`, or `missing` status and delay time

---

### GCS DAG Bucket (`gcsDagBucket`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `cloudPlatform` |
| Purpose | Storage for Airflow DAG Python files across Composer environments; the `dag_cleanup.py` DAG reads file metadata and deletes stale errored/paused DAG files |
| Ownership | shared |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: `get_last_update_time_for_file()` retrieves GCS blob `updated` timestamp to determine DAG file staleness
- **Write (delete)**: `delete_dags()` deletes DAG file blobs from the bucket; only executes in non-production environments

## Caches

> No evidence found in codebase. This service does not use any caching layer.

## Data Flows

- **Airflow metadata -> monitoring logic**: `PRE_TASK_TRACKER3` reads `task_instance` and `dag_run` from PostgreSQL to find anomalous tasks, then writes JSM alerts via HTTP
- **DWH Manage / Megatron MySQL -> Megatron monitoring**: EOD and lag DAGs read `consistent_before_hard` and `etl_process_status` to determine delay, then write JSM alerts
- **CKOD MySQL -> SLA Updater**: SLA updater reads `EDW_SLA_DEFINITION` to discover jobs, reads `dag_run` states from Airflow PostgreSQL, and writes results back to `EDW_SLA_JOB_DETAIL`
- **PRE Monitoring MySQL -> DAG cleanup**: `dag_cleanup.py` reads and writes tracker tables, then deletes corresponding GCS files
- **Jira -> Google Drive**: `update_runbooks.py` reads resolved Jira tickets and writes generated runbook HTML documents to Google Drive, then records the Drive URL in `pre_runbook_dag_mapping`
