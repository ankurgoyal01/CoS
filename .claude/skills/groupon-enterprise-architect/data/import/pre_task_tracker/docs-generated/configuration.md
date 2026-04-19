---
service: "pre_task_tracker"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "airflow-variables", "config-files", "gcp-secret-manager", "airflow-connections"]
---

# Configuration

## Overview

`pre_task_tracker` is configured through a combination of Airflow Variables (runtime key-value store), GCP environment variables injected by Cloud Composer, GCP Secret Manager (for all credentials), Airflow Connections (for database and Google Drive access), and a static YAML config file (`orchestrator/config.yml`) that defines Megatron table monitoring parameters. No Helm values, Consul, or Vault are used.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `GCP_PROJECT` | Current GCP project ID; used to determine Composer instance context (pipelines vs. composer vs. ingestion) | yes | — | Cloud Composer environment |
| `AIRFLOW__WEBSERVER__BASE_URL` | Base URL of the Airflow webserver; used when constructing DAG links in Dataproc cluster alerts | yes | — | Cloud Composer environment |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Airflow Variables

| Variable | Purpose | Required | Default |
|----------|---------|----------|---------|
| `ENV` | Current deployment environment string (e.g., `prod`, `stable`, `dev`); controls JSM test-mode and deletion guards | yes | — |
| `env` | Lowercase environment name; used by `TeradataHook` for DAG link construction | yes | — |
| `queue_threshold` | Minutes a DAG or task may remain in `QUEUED` state before alerting | no | `3` |
| `DAG_BUCKET` | GCS bucket name for Composer DAG files; used by `dag_cleanup.py` for file deletion | yes | — |
| `PROJECT_ID` | GCP project ID for Teradata secret retrieval | yes | — |
| `PREUTILS_CONFIG` | JSON config for `preutils` library (overrides `secret_id`, `track`, `alert` flags) | no | `{"secret_id": "pre_secrets", "track": true, "alert": true}` |
| `DRIVE_KEBOOLA` | Google Drive folder ID for Keboola runbooks | yes (for runbook DAG) | — |
| `DRIVE_PIPELINES` | Google Drive folder ID for pipeline runbooks | yes (for runbook DAG) | — |
| `DRIVE_RM` | Google Drive folder ID for Revenue Management runbooks | yes (for runbook DAG) | — |

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `cfg.track` | When `false`, `update_runbooks.py` skips all Jira and Drive operations | `true` | global |
| `cfg.alert` | Controls whether `preutils` emits JSM alerts | `true` | global |
| `IS_PIPELINES_ENV` | Determines whether `mbus_backlog_monitor` DAG is created; only active in PIPELINES Composer instances | derived from `GCP_PROJECT` | per-instance |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `orchestrator/config.yml` | YAML | Defines all Megatron table monitoring entries: content groups (`groupon_orders_vis`, `groupon_orders`, `groupon_orders_snc1`, `deal_catalog`, `accounting`), table names, load types (`load`, `merge`, `sqoop`), `eod_time`, `delay_threshold` (hours), `target_table`, `schema_name`, and `schedule_group` |

### config.yml Structure

```yaml
<content_group>:
  <table_name>:
    <load_type>:           # load | merge | sqoop
      eod_time: "HH:MM"   # UTC time by which the table must be loaded
      delay_threshold: N   # Hours of lag before alerting
      target_table: name   # Teradata or Hive target table name
      schema_name: name    # snc1_teradata | snc1_hive | snc1_gdoop_teradata
      content_group: name  # Content group identifier for table_limits lookup
      schedule_group: name # Schedule group label (critical_sla, prod, sla, etc.)
```

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `pre_secrets` | Master secret bundle containing `jsm.api_key`, `jira.basic_auth`, `jira.server` | GCP Secret Manager |
| `pd_conn_id` | Teradata connection details (`host`, `user`, `password`) stored as YAML | GCP Secret Manager |
| `grafana_secrets` | Grafana configuration (`GRAFANA_URL`, `GRAFANA_TOKEN`, `DATASOURCE_UID`) for MBUS Prometheus queries | GCP Secret Manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Airflow Connections

| Connection ID | Type | Purpose |
|--------------|------|---------|
| `airflow_db` | PostgreSQL | Airflow metadata database; used by `PRE_TASK_TRACKER3` for task state queries |
| `vw_conn_id` | MySQL | PRE Monitoring Database; stores tracker tables, runbook mappings, `td_table_limits` |
| `megatron` | MySQL | Megatron ETL database; queried for `etl_process_status` |
| `dwh_manage` | MySQL | DWH Manage database; queried for `table_limits` freshness timestamps |
| `ckod_conn_rw` | MySQL | CKOD SLA database; read/write SLA definitions and job detail entries |
| `google_to_drive` | Google (OAuth2) | Google Drive API access; `keyfile_dict` in connection extras |

## Per-Environment Overrides

The service uses Airflow Variable `ENV` and environment variable `GCP_PROJECT` to gate behavior:

- **Production** (`ENV=prod`): JSM alerts route to real on-call teams (`test=False`); automated DAG file deletion is disabled (`env != prod` guard in `dag_cleanup.py`); `mbus_backlog_monitor` runs on schedule `0 * * * *`
- **Staging** (`ENV=stable`): JSM alerts route to test JSM instance; automated DAG deletion is active; `mbus_backlog_monitor` schedule is `None` (manual trigger only)
- **Dev** (`ENV=dev`): Same as staging; JSM test mode; full deletion enabled

Composer instance name (`AIRFLOW__WEBSERVER__INSTANCE_NAME`) additionally controls:
- Which GCP projects are monitored by `PRE_CLUSTER_TRACKER` (PIPELINES, CONSUMER, or INGESTION project sets)
- Which SLA tables are used by the SLA Updater (`EDW_SLA_*` vs. `RM_SLA_*`)
- Which monitoring organizations are active in `PRE_TASK_TRACKER3` (all three orgs are always active)
