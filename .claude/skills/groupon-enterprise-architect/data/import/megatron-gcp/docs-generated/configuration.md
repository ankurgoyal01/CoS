---
service: "megatron-gcp"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["airflow-variables", "yaml-config-files", "gcp-secret-manager", "env-vars"]
---

# Configuration

## Overview

Megatron GCP configuration is split across three layers: Airflow Variables (runtime overrides resolved at DAG parse time), YAML factory config files (static service and cluster definitions committed to the repository), and GCP Secret Manager (credentials distributed to Dataproc nodes at cluster startup). A small number of environment variables are injected by the CI/CD deploy bot and Airflow Composer environment.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `GCS_BUCKET` | Composer DAGs GCS bucket name used to locate service configs and audit scripts | yes | none | Airflow Composer env |
| `ENV` | Runtime environment identifier (`dev`, `stable`, `prod`) | yes | none | Airflow Variable `env` |
| `METRIC_ENDPOINT` | Telegraf push endpoint for pipeline telemetry | yes | Derived from `ENV` | YAML config (`PROD-METRIC-ENDPOINT`, `STAGE-METRIC-ENDPOINT`, `SANDBOX-METRIC-ENDPOINT`) |
| `ZOMBIERC` | Path to ZRC2 credentials file on Dataproc node | yes | `/root/.zrc2` | Set by `copy_secrets_config` Pig job |
| `HOME` | Home directory on Dataproc node for Python module resolution | yes | `/root` | Set in Pig job shell |
| `PYTHONPATH` | Python path for `zombie_runner` module on Dataproc node | yes | `/usr/local/lib/python2.7/dist-packages/zombie_runner/` | Set in Pig job shell |
| `COMPOSER_DAGS_BUCKET` | GCS bucket where generated DAG files are deployed | yes | Per-environment (see deploy bot config) | `.deploy_bot.yml` environment_vars |
| `KUBERNETES_NAMESPACE` | K8s namespace for deploy bot operations | yes | Per-environment | `.deploy_bot.yml` environment_vars |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `force` (DAG run conf or YAML `force: true`) | Forces full re-ingestion of tables regardless of ETL status | `false` | per-partition (YAML) or per-dag-run (Airflow conf) |
| `validate_parallel` | Enables parallel MySQL validation task groups (one per `table_group_id`) instead of a single serial audit task | `false` | per-service in YAML |
| `num_workers` (DAG run conf) | Overrides the cluster worker node count for a single run | Derived from YAML `num_workers` map | per-dag-run |
| `master_machine_type` (DAG run conf) | Overrides master node machine type for a single run | Derived from YAML `MAIN` map | per-dag-run |
| `worker_machine_type` (DAG run conf) | Overrides worker node machine type for a single run | Derived from YAML `WORKER` map | per-dag-run |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `orchestrator/megatron/dag_config/mysql_dag_factory_config.yaml` | YAML | Defines all MySQL service partitions, table lists, cron schedules, cluster sizes, machine types, and compliance classification (SOX/NON_SOX) |
| `orchestrator/megatron/dag_config/postgres_dag_factory_config.yaml` | YAML | Same as above for PostgreSQL services (BRS, ILS, SPOG, and others) |
| `orchestrator/bigquery_data_quality/table_comparison_config.yaml` | YAML | Configures BigQuery datastream vs backfill table comparison checks (project ID, table refs, tolerances, enabled checks) |
| `dag_generator/requirements.txt` | text | Python dependencies for the DAG generator container (`pyyaml`, `apache-airflow`, `apache-airflow-providers-google`) |
| `Dockerfile` | Dockerfile | Builds the DAG generator image (Python 3.8.12 base, Airflow 2.10.5 constraints) |
| `.deploy_bot.yml` | YAML | Deploy bot targets: dev, staging, production in `us-central1`; Composer bucket and K8s namespace per env |
| `Jenkinsfile` | Groovy | CI/CD pipeline: `dataPipeline` DSL with optional build step running the DAG generator container |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `megatron-zrc2` (`ZRC2_SECRET`) | ZRC2 authentication credentials for `zombie_runner` module on Dataproc | GCP Secret Manager |
| `megatron-odbc` (`ODBCINI_SECRET`) | ODBC INI file for MySQL/Postgres source database connectivity on Dataproc | GCP Secret Manager |
| `grpn-sa-kbc-bq-ds-ingestion-key` (`GRPN_SA_KBC_BQ_DS_INGESTION_KEY_SECRET`) | BigQuery service account key for datastream ingestion and validation | GCP Secret Manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Config Key | Dev | Stable | Production |
|------------|-----|--------|------------|
| Ingestion project | `prj-grp-ingestion-dev-f4fa` | `prj-grp-ingestion-stable-dc79` | `prj-grp-ingestion-prod-59d0` |
| DL Secure project | `prj-grp-dl-secure-dev-4c50` | `prj-grp-dl-secure-stable-550e` | `prj-grp-dl-secure-prod-3255` |
| Datalake project | `prj-grp-datalake-dev-8876` | `prj-grp-datalake-stable-dcf6` | `prj-grp-datalake-prod-8a19` |
| Shared VPC project | `prj-grp-shared-vpc-dev-d89e` | `prj-grp-shared-vpc-stable-134f` | `prj-grp-shared-vpc-prod-2511` |
| Pipelines project | `prj-grp-pipelines-dev-7536` | `prj-grp-pipelines-stable-19fd` | `prj-grp-pipelines-prod-bb85` |
| Compute project | `prj-grp-data-compute-dev-2c47` | `prj-grp-data-compute-dev-2c47` | `prj-grp-data-compute-dev-2c47` |
| Teradata final schema | `dev1_meg_grp_gcp` | `gstg_meg_grp_prod` | `meg_grp_prod` |
| Teradata staging schema | `dev1_staging` | `gstg_staging` | `staging` |
| Metric endpoint | `telegraf.general.sandbox.gcp.groupondev.com` | `telegraf.us-central1.conveyor.stable.gcp.groupondev.com` | `telegraf.us-central1.conveyor.prod.gcp.groupondev.com` |
| Composer DAGs bucket | `us-central1-grp-ingestion-c-1530da7e-bucket` | `us-central1-grp-ingestion-c-d45d2aa7-bucket` | `us-central1-grp-ingestion-c-5afcb1da-bucket` |
| K8s namespace | `megatron-gcp-dev` | `megatron-gcp-staging` | `megatron-gcp-production` |
| Dataproc image | `megatron-test-{cdc}` | `megatron-test-{cdc}` | `megatron-{cdc}` (prod image) |
| Deploy to production | automatic (after staging) | automatic (after dev) | manual approval required |

## Airflow Variables

The following Airflow Variables are read at DAG parse time and may be set in the Cloud Composer Airflow UI:

| Variable | Purpose | Optional |
|----------|---------|----------|
| `env` | Runtime environment tag (`dev`, `stable`, `prod`) | no |
| `MEGATRON_NUM_WORKERS_PEAK` | Peak-load override for worker count (ingestion DAGs) | yes |
| `MEGATRON_MASTER_MACHINE_TYPE_PEAK` | Peak-load override for master machine type | yes |
| `MEGATRON_WORKER_MACHINE_TYPE_PEAK` | Peak-load override for worker machine type | yes |
| `MEGATRON_AUDIT_NUM_WORKERS_PEAK` | Peak-load override for audit DAG worker count | yes |
| `MEGATRON_AUDIT_MASTER_MACHINE_TYPE_PEAK` | Peak-load override for audit DAG master machine type | yes |
| `MEGATRON_AUDIT_WORKER_MACHINE_TYPE_PEAK` | Peak-load override for audit DAG worker machine type | yes |
