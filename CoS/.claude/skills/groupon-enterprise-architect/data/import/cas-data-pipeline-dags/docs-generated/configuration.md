---
service: "cas-data-pipeline-dags"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["airflow-variables", "json-config-files", "gcp-secrets-manager", "deploy-bot-env-vars"]
---

# Configuration

## Overview

Configuration is layered across three mechanisms. At the Airflow level, variables (e.g., `env`) are stored in the Cloud Composer Airflow Variables store and retrieved at DAG parse time via `Variable.get("env")`. At the DAG config level, JSON files under `orchestrator/config/` and `orchestrator/vars/` provide pipeline-specific and environment-specific settings; the `ConfigLoader` class merges these and performs `@variable` substitution before the DAG executes. At the cluster level, GCP secret manager secrets (referenced by `secret_name` in GCE metadata) are injected via Dataproc cluster init scripts for TLS keystores.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `env` | Airflow environment identifier (`dev`, `staging`, `production`); selects the `vars/{env}/common_vars.json` file | yes | none | Airflow Variable store (`Variable.get("env")`) |
| `COMPOSER_DAGS_BUCKET` | GCS bucket name where DAG files are deployed; read by deploy-bot during deployment | yes | none | deploy-bot environment variable (`.deploy_bot.yml`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flags are used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `orchestrator/vars/{env}/common_vars.json` | JSON | Environment-specific base variables: `project_id`, `region`, `zone_uri`, `subnetwork_uri`, `service_account`, `worker_num_instances`, `dataproc_metastore_service`, `artifact_base_path`, `artifact_version` |
| `orchestrator/vars/arbitration_machine_learning.json` | JSON | Pipeline-specific variable overrides for arbitration ML DAGs |
| `orchestrator/vars/arbitration_sto.json` | JSON | Variable overrides for STO (Send Time Optimisation) DAGs |
| `orchestrator/vars/arbitration_reporting.json` | JSON | Variable overrides for reporting pipeline DAGs |
| `orchestrator/config/arbitration-machine-learning/*.json` | JSON | Per-DAG job configuration: cluster config, job definitions, task connections for each ML pipeline |
| `orchestrator/config/reporting-pipeline/*.json` | JSON | Per-DAG job configuration for NA and EMEA reporting pipelines |
| `orchestrator/config/create_cluster_config.json` | JSON | Standalone cluster creation config (used by `create_cluster.py`) |
| `orchestrator/config/dev/common_cluster_config.json` | JSON | Dev environment cluster configuration override |
| `.deploy_bot.yml` | YAML | Deploy-bot targets (`dev-us-central1`, `staging-us-central1`, `production-us-central1`) with `COMPOSER_DAGS_BUCKET` per environment |
| `Jenkinsfile` | Groovy DSL | CI pipeline config: `slackChannel`, `deployTarget`, `artifactIncludePattern`, `releasableBranches` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `tls--push-cas-data-pipelines` | TLS keystore for mTLS communication with arbitration-service and AMS APIs from Dataproc cluster; also used by Janus-YATI for Kafka SSL | GCP Secret Manager (injected via `init_secret_script` Dataproc init action) |
| `@service_account` | GCP service account email used by Dataproc GCE cluster | Airflow Variable / common_vars.json |
| `@init_secret_script` | GCS URI of the cluster init script that fetches the TLS keystore from Secret Manager | Airflow Variable / common_vars.json |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Three deploy-bot targets correspond to three Airflow environments:

| Environment | `COMPOSER_DAGS_BUCKET` | Kubernetes context |
|-------------|----------------------|-------------------|
| `dev-us-central1` | `us-central1-grp-shared-comp-155675d0-bucket` | `arbitration-service-dev-us-west-2` |
| `staging-us-central1` | `us-central1-grp-shared-comp-03dba3de-bucket` | `arbitration-service-staging-us-west-2` |
| `production-us-central1` | `us-central1-grp-shared-comp-155675d0-bucket` | `arbitration-service-production-us-west-2` |

All DAG configs use the `@variable` substitution pattern; values for `project_id`, `region`, `zone_uri`, `subnetwork_uri`, `service_account`, `worker_num_instances`, `dataproc_metastore_service`, `artifact_base_path`, and `artifact_version` are resolved from `orchestrator/vars/{env}/common_vars.json` at runtime. All DAGs are created with `is_paused_upon_creation=True` and `schedule_interval=None`, meaning they require manual triggering or external orchestration after initial deployment.
