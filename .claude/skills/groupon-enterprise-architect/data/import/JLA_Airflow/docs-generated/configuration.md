---
service: "JLA_Airflow"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["airflow-variables", "airflow-connections", "env-vars", "deploy_bot.yml"]
---

# Configuration

## Overview

JLA Airflow is configured through three mechanisms: Airflow Variables (runtime configuration accessible via `Variable.get()`), Airflow Connections (credentials and endpoint URLs for external systems), and environment variables injected by the Deploybot CI/CD system. Per-environment differences are primarily controlled by the `COMPOSER_DAGS_BUCKET` and `KUBERNETES_NAMESPACE` env vars set in `.deploy_bot.yml`, and by the `Env.replace()` utility which substitutes environment-specific database schema names.

## Environment Variables

The following environment variables are injected by the Deploybot deployment system per environment (defined in `.deploy_bot.yml`):

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `COMPOSER_DAGS_BUCKET` | GCS bucket where DAG files are deployed | yes | None | `.deploy_bot.yml` per environment |
| `KUBERNETES_NAMESPACE` | Kubernetes namespace for the Composer environment | yes | None | `.deploy_bot.yml` per environment |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

The following Airflow Variables are used as runtime feature flags and configuration:

| Flag / Variable | Purpose | Default | Scope |
|-----------------|---------|---------|-------|
| `etl_schedule` | Cron schedule for `jla-mart-etl-1-startup` DAG | `"30 9 * * *"` | global |
| `eba_schedule` | Cron schedule for `jla-eba-rules-exec` DAG | None (required Variable) | global |
| `eba_offset_start` | Day offset for EBA start date (days before today) | `0` | global |
| `eba_offset_end` | Day offset for EBA end date (days before today) | `0` | global |
| `db_summoner` | Redirects Teradata connections to sandbox host when `"True"` | `"False"` | global |
| `GChatSpaces.ENGINEERING_ALERTS` | Webhook token for FSA engineering alerts Google Chat space | None (required Variable) | global |
| `GChatSpaces.JLA_ALERTS` | Webhook token for JLA operations Google Chat space | None (required Variable) | global |
| `GChatSpaces.STAKEHOLDER_ALERTS` | Webhook token for stakeholder notifications Google Chat space | None (required Variable) | global |

## DAG-Level Runtime Parameters

DAGs accept `conf` parameters at trigger time to control behaviour:

| Parameter | DAGs | Purpose | Default |
|-----------|------|---------|---------|
| `manual-run-NO-update-dataset` | ETL steps 1–8 | Prevents final BigQuery dataset publication on manual reruns | `False` |
| `manual-run-update-dataset` | ETL step 1 | Forces BigQuery dataset publication even on manual runs | `False` |
| `origin_run_type` | ETL chain (propagated) | Distinguishes scheduled vs. manual run for publication logic | Derived from DAG run type |
| `script_list` | `db-gatekeeper` | List of raw GitHub URLs for SQL scripts to execute | `['list','of','url','strings']` |
| `show_DDL_diff` | `db-gatekeeper` | When `True`, runs DDL diff comparison instead of executing | `False` |
| `start_date` / `end_date` | `jla-eba-rules-exec` | Override EBA processing date range | Computed from `eba_offset_*` Variables |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.deploy_bot.yml` | YAML | Deploybot deployment configuration; defines target environments, GCS buckets, Kubernetes clusters and namespaces, and deployment image |
| `Jenkinsfile` | Groovy (Jenkins DSL) | CI/CD pipeline; loads `fsa-pipeline-dsl@latest-2` shared library; selects deploy target by branch |
| `.service.yml` | YAML | Service metadata (`name: fsa-data-pipelines`) |
| `orchestrator/.vscode/requirements-lint.txt` | pip requirements | Linting dependencies for local development |
| `orchestrator/.vscode/.flake8` | INI | Flake8 linting configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `teradata` (Airflow Connection) | Teradata hostname, username, and password for `dwh_fsa_prd` | Airflow Connections (Composer-managed) |
| `kyriba_sftp` (Airflow Connection) | Kyriba SFTP host, credentials | Airflow Connections |
| `http_jla_services_root` (Airflow Connection) | JLA EBA and NetSuite service base URL | Airflow Connections |
| `http_jla_app` (Airflow Connection) | JLA application base URL | Airflow Connections |
| `gchat_spaces` (Airflow Connection) | Google Chat webhook base connection | Airflow Connections |
| `jira_api` (Airflow Connection) | Jira API host, username, password | Airflow Connections |
| `http_snaplogic_sftons` (Airflow Connection) | SnapLogic pipeline endpoint | Airflow Connections |
| `bigquery_default` (Airflow Connection) | BigQuery project and service account keyfile | Airflow Connections |
| `zing` (Airflow Connection) | SSH connection for SFTP Mover DAG | Airflow Connections |
| `AWS-SFTP` (Airflow Connection) | AWS SFTP connection for file migration | Airflow Connections |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Environment | `COMPOSER_DAGS_BUCKET` | `KUBERNETES_NAMESPACE` | Cluster |
|-------------|----------------------|----------------------|---------|
| dev | `us-central1-grp-finance-com-97e41a79-bucket` | `fsa-data-pipelines-dev` | `gcp-stable-us-central1` |
| staging (uat) | `us-central1-grp-finance-com-d4d70566-bucket` | `fsa-data-pipelines-staging` | `gcp-stable-us-central1` |
| production | `us-central1-grp-finance-com-60c1a386-bucket` | `fsa-data-pipelines-production` | `gcp-production-us-central1` |

The `Env.replace('Teradata', schema)` utility function substitutes environment-specific schema names in SQL (e.g., `dwh_fsa_prd` → `dwh_fsa_dev` in dev). The `db_summoner` Airflow Variable additionally redirects Teradata host to a sandbox environment when enabled.
