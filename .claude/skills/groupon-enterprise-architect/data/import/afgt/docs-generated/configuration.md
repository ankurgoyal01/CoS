---
service: "afgt"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, airflow-variables, vault]
---

# Configuration

## Overview

AFGT is configured through a combination of Airflow Variables (resolved at runtime), JSON config files bundled with the pipeline artifact, and environment variables injected into the Dataproc cluster via the `setup_var.sh` initialization script. Secrets (Teradata credentials) are retrieved from Google Secret Manager at cluster startup via the `CopySecretOperator` and placed on the cluster filesystem. The active GCP project, region, cluster config, and GCS bucket paths all vary by environment and are resolved from `orchestrator/config/rm_afgt_connex_config.json` keyed by the Airflow Variable `env`.

## Environment Variables

The following variables are set on the Dataproc cluster nodes by `scripts/setup_var.sh` at job start:

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `HOME` | Sets home directory to pipeline artifact path | yes | `/home/app/artifacts` | `setup_var.sh` |
| `zr_job_folder_rev` | Path to ZombieRunner job folder | yes | `/home/app/artifacts/afgt_zr` | `setup_var.sh` |
| `ZOMBIERC` | Path to ZombieRunner config file | yes | `/home/app/artifacts/afgt_zr/zrc2` | `setup_var.sh` |
| `ODBCINI` | Path to ODBC configuration file | yes | `/home/app/artifacts/afgt_zr/odbc.ini` | `setup_var.sh` |
| `DEFAULT_DB` | Default Teradata database for BTEQ queries | yes | `sb_rmaprod` | `setup_var.sh` |
| `USER_TD` | Teradata service account username | yes | `ub_ma_emea` | `setup_var.sh` |
| `TD_DSN_NAME` | Teradata DSN / hostname | yes | `teradata.groupondev.com` | `setup_var.sh` |
| `USER_TD_PASS` | Teradata service account password | yes | (from secret file) | Google Secret Manager via `CopySecretOperator` |
| `HIVE_DEFAULT_DB` | Default Hive database used by Sqoop script | yes | `ima` | `scripts/td_to_hive.sh` |
| `STAGING_TABLE` | Hive staging table name used by Sqoop script | yes | `analytics_fgt_tmp_zo` | `scripts/td_to_hive.sh` |
| `PIPELINE_ARTIFACT_VERSION` | Version string used to construct artifact download URL | yes | (injected by deploybot) | DeployBot / Kubernetes |

The following are set in the Dataproc cluster node metadata (`gce_cluster_config.metadata`):

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `artifact_urls` | Path to pipeline ZIP artifact in Artifactory | yes | `/com/groupon/dnd-bia-data-engg/afgt/{version}/afgt-{version}.zip` | `orchestrator/afgt_td.py` |

The following are set per-environment in `.deploy_bot.yml`:

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `COMPOSER_DAGS_BUCKET` | GCS bucket for Cloud Composer DAG deployment | yes | varies by env | `.deploy_bot.yml` |
| `KUBERNETES_NAMESPACE` | Kubernetes namespace for deploybot deploy job | yes | varies by env | `.deploy_bot.yml` |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found — AFGT does not use feature flags. The `afgt_zr` DAG (`afgt_zr.py`) is fully commented out and not deployed, representing a legacy ZombieRunner path that has been superseded by the current Dataproc-based flow.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `orchestrator/config/rm_afgt_connex_config.json` | JSON | Per-environment GCP project ID, region, cluster config (machine type, disk, network, service account, metastore), and IMA/common GCS bucket paths. Keyed by `dev`, `sandbox`, `stable`, `prod`. |
| `orchestrator/config/afgt_vars.json` | JSON | Pipeline metadata: email recipients, secret references, Optimus Prime URL, Google Chat webhook URL, service name, owner name, pipeline repo name |
| `orchestrator/config/afgt_zr_vars.json` | JSON | Legacy ZombieRunner variant config (same structure as `afgt_vars.json`); currently unused as `afgt_zr.py` is commented out |
| `afgt_zr/odbc.ini` | INI | ODBC DSN configuration for ZombieRunner Teradata connection; password injected at runtime by `setup_var.sh` |
| `afgt_zr/zrc2` | text | ZombieRunner control file (legacy path) |
| `afgt_zr/load_cb_afgt.yml` | YAML | Legacy ZombieRunner task definition for Cerebro-based Teradata extract and Hive load |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `ub_ma_emea_password_file` | Teradata service account password for `ub_ma_emea` user; copied to `/home/app/artifacts/ub_ma_emea_password_file.txt` on cluster | Google Secret Manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Configuration differs between environments through the `rm_afgt_connex_config.json` file, resolved at DAG runtime using the Airflow Variable `env`:

| Environment | GCP Project | Cluster Config | IMA Bucket | Notes |
|-------------|-------------|---------------|------------|-------|
| `dev` | `prj-grp-consumer-dev-14a6` | 1 master + 4 workers, `n1-standard-16`, 500GB PD | `gs://grpn-dnd-dev-analytics-grp-ima` | `idle_delete_ttl: 1800s` |
| `sandbox` | `prj-grp-general-sandbox-7f70` | 1 master + 0 workers, `n1-standard-8`, 500GB PD | (no IMA bucket configured) | `idleDeleteTtl: 45m`, `autoDeleteTtl: 2d` |
| `stable` | `prj-grp-revmgmt-stable-d4c2` | 1 master + 4 workers, `n1-standard-16`, 500GB PD | `gs://grpn-dnd-stable-analytics-grp-ima` | `idle_delete_ttl: 1800s` |
| `prod` | `prj-grp-revmgmt-prod-ef0c` | 1 master + 2 primary workers + 2 preemptible secondary workers, `n1-standard-16` | `gs://grpn-dnd-prod-analytics-grp-ima` | `idle_delete_ttl: 3600s`; manual promotion required |

Dataproc is deployed to `us-central1` in all environments. Production Kubernetes cluster is `gcp-production-us-central1`; staging and dev use `gcp-stable-us-central1`.
