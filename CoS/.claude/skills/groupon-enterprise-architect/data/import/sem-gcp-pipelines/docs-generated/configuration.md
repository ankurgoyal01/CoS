---
service: "sem-gcp-pipelines"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["airflow-variables", "config-files", "gcp-secret-manager"]
---

# Configuration

## Overview

sem-gcp-pipelines uses three configuration sources: (1) Airflow Variables for environment-level settings, (2) per-pipeline YAML (`global_variables_*.yml`) and JSON (`cluster_config_*.json`) config files stored in the repository and deployed with the DAGs, and (3) GCP Secret Manager for sensitive credentials accessed at job runtime via `gcloud secrets versions access`. Configuration is environment-specific (dev / stable / prod) with files named by environment suffix.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `env` | Airflow Variable — identifies current environment (`dev`, `stable`, `prod`) used by all DAGs to select config files | yes | none | Airflow Variable store |
| `COMPOSER_DAGS_BUCKET` | GCS bucket where DAG files are deployed by deploy-bot | yes | none | deploy-bot environment config |
| `KUBERNETES_NAMESPACE` | Kubernetes namespace for deploy-bot deployment | yes | none | deploy-bot environment config |
| `PIPELINE_ARTIFACT_VERSION` | Version string of the sem-gcp-pipelines ZIP artifact fetched from Artifactory at cluster init | yes | none | Jenkins CI injection |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flag system is used. Pipeline enabling/disabling is controlled by DAG `schedule_interval` — set to `None` in non-prod environments for most DAGs.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `orchestrator/cluster/config/cluster_config_{env}.json` | JSON | GCP project ID, region, cluster name, GCE config (machine type, subnet, service account, scopes), Dataproc software config (image version, pip packages), Hive settings, metastore reference |
| `orchestrator/{pipeline}/config/cluster_config_{env}.json` | JSON | Per-pipeline Dataproc cluster config overrides |
| `orchestrator/{pipeline}/config/global_variables_{env}.yml` | YAML | Per-pipeline job definitions (name, job_class, schedule_interval, countries) and notification emails |
| `orchestrator/google_things_todo/config/{env}/cluster_config.json` | JSON | GTTD-specific cluster config |
| `orchestrator/google_things_todo/config/{env}/global_variables.yml` | YAML | GTTD MDS feed host, feed UUID, SFTP user, rows per file, notification emails, schedule interval |

### Key Config File Fields

**cluster_config_prod.json** (shared cluster):
- `project_id`: `prj-grp-c-common-prod-ff2b`
- `region`: `us-central1`
- `cluster_name`: `dataproc-cluster-sem-eng-prod`
- `cluster_config.gce_cluster_config.service_account`: `loc-sa-c-sem-dataproc@prj-grp-c-common-prod-ff2b.iam.gserviceaccount.com`
- `cluster_config.software_config.image_version`: `1.5-debian10`
- `cluster_config.software_config.properties.dataproc:pip.packages`: `stomp.py==8.1.0,thrift==0.16.0`
- `cluster_config.lifecycle_config.idle_delete_ttl.seconds`: `1800` (30-minute idle auto-delete)

**google_things_todo/config/prod/global_variables.yml**:
- `MDS.FEED_HOST`: `mds-feed.production.service`
- `MDS.FEED_UUID`: `a537b6c9-7819-4571-a332-9c8ab323274e`
- `GOOGLE.SFTP_USER`: `feeds-zk06ag`
- `GOOGLE.ROWS_PER_FILE`: `5000`
- `INTERVAL`: `0 8,18 * * *`

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `sem_dnkw_postgres_pass` | PostgreSQL password for DNKW database | GCP Secret Manager |
| `sem_dnkw_postgres_user` | PostgreSQL username for DNKW database | GCP Secret Manager |
| `sem_common_jobs` | Credentials bundle used by all `sem-common-jobs` Java Spark jobs (Google Ads, Facebook, CSS, etc.) | GCP Secret Manager |
| `{country}.KEY_NAME` (per Databreakers account) | Per-country HMAC signing key for Databreakers API | GCP Secret Manager |

Secrets are accessed at runtime via `gcloud secrets versions access latest --project={project_id} --secret={secret_key}`. On Dataproc clusters, the `sem_common_jobs` secret is loaded via a Pig job step (`load_secrets` task) that writes credentials to `/tmp/credentials` before the Spark job executes.

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | dev | stable | prod |
|---------|-----|--------|------|
| `project_id` | `prj-grp-consumer-dev-14a6` | `prj-grp-c-common-stable-c036` | `prj-grp-c-common-prod-ff2b` |
| `cluster_name` | `dataproc-cluster-sem-eng-dev` | `dataproc-cluster-sem-eng-stable` | `dataproc-cluster-sem-eng-prod` |
| DAG schedule_interval | `None` (all DAGs paused) | `None` (all DAGs paused) | Enabled per YAML config |
| Composer bucket | `us-central1-grp-shared-comp-155675d0-bucket` | `us-central1-grp-shared-comp-03dba3de-bucket` | `us-central1-grp-shared-comp-9260309b-bucket` |
| Data bucket | `grpn-dnd-dev-analytics-grp-sem-group` | `grpn-dnd-stable-analytics-grp-sem-group` | `grpn-dnd-prod-analytics-grp-sem-group` |
| Kubernetes namespace | — | `sem-gcp-pipelines-staging` | `sem-gcp-pipelines-production` |
| Kubernetes cluster | — | `gcp-stable-us-central1` | `gcp-production-us-central1` |
