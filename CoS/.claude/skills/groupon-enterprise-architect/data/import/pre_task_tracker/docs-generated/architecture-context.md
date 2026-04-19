---
service: "pre_task_tracker"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumPreTaskTracker"
  containers:
    - "continuumPreTaskTracker"
    - "continuumPreTaskTrackerAirflowDb"
    - "continuumPreTaskTrackerMysqlDb"
---

# Architecture Context

## System Context

`pre_task_tracker` sits within Groupon's **Continuum** platform as a reliability operations service for the data engineering ecosystem. It runs as a set of Apache Airflow DAGs deployed to Google Cloud Composer and acts as an observability layer above all data pipeline DAGs. It reads pipeline execution state from the Airflow metadata PostgreSQL database, queries data warehouse MySQL databases for SLA and table limit information, monitors Dataproc cluster state via `gcloud` CLI, and sends alerts to Jira Service Management and Google Chat. It has no inbound HTTP API surface; all interactions are driven by Airflow scheduling.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| pre_task_tracker DAG Package | `continuumPreTaskTracker` | Backend | Python, Apache Airflow | 2.x | Apache Airflow DAG package that monitors Megatron delays/failures, updates SLA tracking data, and manages runbook and operational workflows |
| Airflow Metadata Database | `continuumPreTaskTrackerAirflowDb` | Database | PostgreSQL | — | Stores DAG definitions, run state, and task metadata queried by monitoring DAGs |
| PRE Monitoring Database | `continuumPreTaskTrackerMysqlDb` | Database | MySQL | — | Stores `td_table_limits`, runbook mappings (`pre_runbook_dag_mapping`), and DAG tracker tables (`pre_import_error_tracker`, `pre_paused_dag_tracker`) |

## Components by Container

### pre_task_tracker DAG Package (`continuumPreTaskTracker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| DAG Definitions | Airflow DAG entrypoints that schedule monitoring, cleanup, and updater workflows (`PRE_TASK_TRACKER3`, `PRE_CLUSTER_TRACKER`, `pre_check_megatron_eod`, `pre_resolve_megatron_eod`, `pre_check_megatron_lag`, `pre_resolve_megatron_lag`, `pre_composer_dag_cleanup`, `mbus_backlog_monitor`, `update_runbooks`, `PRE-CKOD-EDW-SLA-UPDATER`) | Python |
| Monitoring Logic | Detects Megatron delay/failure conditions, table limits drift (Teradata), Dataproc image expiry, and MBUS queue backlog breaches | Python |
| SLA Updater | Calculates SLA status from DAG runs and updates `EDW_SLA_JOB_DETAIL` / `RM_SLA_JOB_DETAIL` tracker records in the CKOD database | Python |
| Integration Hooks | Shared hooks and utilities for Airflow DB access, MySQL, Teradata, Jira, GCP Secret Manager, and Google APIs | Python |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumPreTaskTracker` | `continuumPreTaskTrackerAirflowDb` | Reads/writes DAG and DAG run metadata (`task_instance`, `dag_run`, `dag`) | PostgreSQL |
| `continuumPreTaskTracker` | `continuumPreTaskTrackerMysqlDb` | Reads/writes tracking tables, runbook mappings, and operational state | MySQL |
| `continuumPreTaskTracker` | `edw` | Queries source table freshness (`dwh_manage.table_limits_view`, `etl_process_status`) and delay metrics | MySQL / Teradata SQL |
| `continuumPreTaskTracker` | `continuumJiraService` | Reads open Jira tickets in `GPROD` project; updates issue labels and ticket metadata via JIRA SDK | HTTPS / JIRA REST API |
| `continuumPreTaskTracker` | `cloudPlatform` | Retrieves integration credentials from GCP Secret Manager (`pre_secrets`, `jsm.api_key`, `pd_conn_id`) | GCP SDK |
| `continuumPreTaskTracker` | `cloudPlatform` | Creates and updates runbook documents in Google Drive via Drive API v3 | HTTPS / Google Drive API |
| `continuumPreTaskTracker` | `cloudPlatform` | Reads/deletes DAG Python files from GCS DAG bucket | GCP SDK / GCS |
| `continuumPreTaskTracker` | `cloudPlatform` | Checks Dataproc cluster and job status via `gcloud` CLI | gcloud CLI |
| `continuumPreTaskTracker` | `googleChat` | Posts monitoring and expiry alerts via incoming webhook | HTTPS Webhook |

## Architecture Diagram References

- System context: `contexts-preTaskTracker`
- Container: `containers-preTaskTracker`
- Component: `components-preTaskTracker`
- Dynamic (SLA update flow): `dynamic-pre-task-tracker-sla-update-flow`
