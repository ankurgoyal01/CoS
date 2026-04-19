---
service: "magneto-gcp"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [airflow-variables, gcp-secret-manager, config-files, env-vars]
---

# Configuration

## Overview

magneto-gcp is configured through four layers: (1) YAML config files baked into the Docker image at build time, (2) Apache Airflow Variables set in Google Cloud Composer, (3) GCP Secret Manager secrets fetched at Dataproc cluster startup, and (4) environment variables injected by the DeployBot deployment system. The two YAML files — `config.yaml` (GCS bucket paths and project IDs) and `dag_factory_config.yaml` (per-table ETL parameters and cluster sizing) — are the primary source of truth for pipeline behavior. Secrets are never stored in code or config files.

---

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `COMPOSER_DAGS_BUCKET` | GCS bucket where generated DAG files are deployed by DeployBot | yes | none | DeployBot / `.deploy_bot.yml` env_vars |
| `KUBERNETES_NAMESPACE` | Kubernetes namespace for the deploy job | yes | none | DeployBot / `.deploy_bot.yml` env_vars |
| `GCS_BUCKET` | Composer DAGs GCS bucket used by orchestrator tasks to locate DAG source files on cluster nodes | yes | none | Cloud Composer runtime |
| `ZOMBIERC` | Path to zombie_runner credentials file on cluster node | no | `~/.zombierc` | Cluster node shell |
| `ODBCINI` | Path to ODBC config file (fallback) | no | `/home/airflow/gcs/dags/magneto/odbc.ini` | Cluster node shell |

---

## Airflow Variables

| Variable | Purpose | Required | Default |
|----------|---------|----------|---------|
| `env` | Deployment environment (`dev`, `stable`, `prod`) — governs which GCP project IDs, buckets, and schedules are used | yes | none |
| `MAGNETO_NUM_WORKERS_PEAK` | Override Dataproc worker count for peak-load ingestion runs | no | table config / `--single-node` |
| `MAGNETO_MASTER_MACHINE_TYPE_PEAK` | Override Dataproc master machine type for peak-load runs | no | `e2-highmem-4` |
| `MAGNETO_WORKER_MACHINE_TYPE_PEAK` | Override Dataproc worker machine type for peak-load runs | no | `e2-highmem-4` |
| `MAGNETO_AUDIT_NUM_WORKERS_PEAK` | Override worker count for audit/validation Dataproc clusters | no | `2` |
| `MAGNETO_AUDIT_MASTER_MACHINE_TYPE_PEAK` | Override master machine type for audit clusters | no | `e2-highmem-4` |
| `MAGNETO_AUDIT_WORKER_MACHINE_TYPE_PEAK` | Override worker machine type for audit clusters | no | `e2-highmem-4` |
| `magneto-salesforce` | Salesforce credentials YAML (Airflow Variable, loaded from Secret Manager) | yes | none |
| `magneto-odbc` | ODBC INI config for MySQL table_limits connection | yes | none |

---

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `orchestrator/magneto/config/config.yaml` | YAML | GCS bucket paths, Hive table locations, Dataproc region, project IDs, metrics gateway endpoints |
| `orchestrator/magneto/config/dag_factory_config.yaml` | YAML | Per-table ETL parameters (schedule, extract slots, compliance, predicates, cluster sizing, Airflow variable IDs, project IDs) |
| `orchestrator/magneto/zr/extract/extract.yml` | YAML | `zombie_runner` extract task graph template (FetchSalesforceTask, ScriptTask, HiveTask) |
| `orchestrator/magneto/zr/load/load.yml` | YAML | `zombie_runner` load task graph template (Hive staging, merge, table_limits update, job_instances insert) |
| `orchestrator/magneto/zr/load_stg/load_stg.yml` | YAML | `zombie_runner` load-to-staging task graph for simple_salesforce mode |
| `orchestrator/validation_magneto/zr/extract/extract_count_task.yml` | YAML | `zombie_runner` extract count task for validation runs |

---

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `magneto-zrc2` | zombie_runner ZRC2 credentials for Dataproc cluster (fetched to `~/.zrc2`) | GCP Secret Manager |
| `magneto-odbc` (as `airflow-variables-magneto-odbc`) | ODBC INI config for MySQL `table_limits` connection (fetched to `~/.odbc.ini`) | GCP Secret Manager |
| `magneto-salesforce` (as `airflow-variables-magneto-salesforce`) | Salesforce login credentials YAML (fetched to `~/.salesforce`) | GCP Secret Manager |
| `megatron-odbc` | ODBC config for audit DAG MySQL connection | GCP Secret Manager |

> Secret values are NEVER documented. Only names and rotation policies.

---

## Per-Environment Overrides

Configuration varies by the `env` Airflow Variable (`dev`, `stable`, `prod`):

| Setting | dev | stable | prod |
|---------|-----|--------|------|
| GCP Ingestion Project | `prj-grp-ingestion-dev-f4fa` | `prj-grp-ingestion-stable-dc79` | `prj-grp-ingestion-prod-59d0` |
| GCP DL-Secure Project | `prj-grp-dl-secure-dev-4c50` | `prj-grp-dl-secure-stable-550e` | `prj-grp-dl-secure-prod-3255` |
| GCP Datalake Project | `prj-grp-datalake-dev-8876` | `prj-grp-datalake-stable-dcf6` | `prj-grp-datalake-prod-8a19` |
| GCP Pipelines Project | `prj-grp-pipelines-dev-7536` | `prj-grp-pipelines-stable-19fd` | `prj-grp-pipelines-prod-bb85` |
| Composer DAGs Bucket | `us-central1-grp-ingestion-c-1530da7e-bucket` | `us-central1-grp-ingestion-c-d45d2aa7-bucket` | `us-central1-grp-ingestion-c-5afcb1da-bucket` |
| Kubernetes Namespace | `magneto-gcp-dev` | `magneto-gcp-staging` | `magneto-gcp-production` |
| Kubernetes Cluster | `gcp-stable-us-central1` | `gcp-stable-us-central1` | `gcp-production-us-central1` |
| DAG Schedule | Per table config `schedule` field | Per table config `stable_schedule` field | Per table config `schedule` field |
| Metrics gateway | `telegraf.general.sandbox.gcp.groupondev.com` | `telegraf.us-central1.conveyor.stable.gcp.groupondev.com` | `telegraf.us-central1.conveyor.prod.gcp.groupondev.com` |
| SOX Dataproc Metastore | `grp-dpms-<env>-metastore-etl` | | |
| NON-SOX Dataproc Metastore | `grpn-dpms-<env>-pipelines` | | |
| Staging Bucket | `grpn-dnd-ingestion-magneto-dev-dataproc-staging` | `grpn-dnd-ingestion-magneto-stable-dataproc-staging` | `grpn-dnd-ingestion-magneto-prod-dataproc-staging` |
| Production deploy | Automatic | Automatic | Manual (`.deploy_bot.yml: manual: true`) |

### Cluster sizing defaults (all environments)

| Parameter | Default value |
|-----------|--------------|
| Master machine type | `e2-highmem-4` |
| Worker machine type | `e2-highmem-4` |
| Max idle time | `1h` |
| Default cluster size labels | ES=1, S=2, M=4, L=6, XL=8, XXL=16 nodes |
| Default extract slots | 1 (configurable per table in `dag_factory_config.yaml`) |
| Max extract slots | 8 |
| DAG timeout | 12 hours |
| DAG catchup | false (ingestion); true (validation) |
| Default start date | 2020-03-01 |
