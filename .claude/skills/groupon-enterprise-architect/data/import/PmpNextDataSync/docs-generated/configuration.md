---
service: "PmpNextDataSync"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources:
  - config-files
  - github-api
  - airflow-variables
  - secrets-file
---

# Configuration

## Overview

PmpNextDataSync configuration operates at two levels. The Spark application (`DataSyncCore`) reads its application-level config from YAML files (`application-local.yaml` or `application-prod.yaml`, selected by the `local_mode` argument) via pureconfig. Per-flow sync job definitions are loaded at runtime from GitHub Enterprise (`DataSyncConfig/<folder>/<flow_name>.yaml`). Airflow DAG configs are stored as JSON files in `orchestrator/config/<env>/` and loaded at DAG parse time. The Airflow `env` variable controls which config directory is used.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `env` | Selects the Airflow config directory (`prod` or `stable`) | yes | — | Airflow Variable |
| `COMPOSER_DAGS_BUCKET` | GCS bucket where Airflow DAGs are deployed | yes | — | deploy_bot env var |
| `KUBERNETES_NAMESPACE` | Kubernetes namespace for staging/production deployments | yes | — | deploy_bot env var |
| `spark.executorEnv.env` | Environment tag passed to Spark executors | yes | `prod` | Dataproc job config |
| `spark.yarn.appMasterEnv.env` | Environment tag passed to YARN AppMaster | yes | `prod` | Dataproc job config |

## Feature Flags

> No evidence found in codebase. No feature flags are implemented.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `DataSyncCore/src/main/resources/application-prod.yaml` | YAML | Production app config (git URI, GCS path, project ID, secret ID) |
| `DataSyncCore/src/main/resources/application-local.yaml` | YAML | Local dev app config (uses `/tmp/hudi/hudi-wh` as Hudi base path) |
| `DataSyncCore/src/main/resources/secrets.json` | JSON | Database credentials map keyed by `gcp_secret_credentials_key` |
| `DataSyncCore/src/main/resources/log4j.properties` | Properties | Log4j logging configuration for Spark application |
| `DataSyncConfig/na-prod/cm_sync_na.yaml` | YAML | NA campaign management sync flow config |
| `DataSyncConfig/na-prod/gss_sync_na.yaml` | YAML | NA global subscription service sync flow config |
| `DataSyncConfig/na-prod/arbitration_sync_na.yaml` | YAML | NA arbitration service sync flow config |
| `DataSyncConfig/na-prod/pts_sync_na.yaml` | YAML | NA push token service sync flow config |
| `DataSyncConfig/emea-prod/cm_sync_emea.yaml` | YAML | EMEA campaign management sync flow config |
| `DataSyncConfig/emea-prod/gss_sync_emea.yaml` | YAML | EMEA global subscription service sync flow config |
| `DataSyncConfig/emea-prod/arbitration_sync_emea.yaml` | YAML | EMEA arbitration service sync flow config |
| `DataSyncConfig/emea-prod/pts_sync_emea.yaml` | YAML | EMEA push token service sync flow config |
| `orchestrator/config/prod/na/dispatcher-na-config.json` | JSON | Airflow DAG config for NA dispatcher (cluster, jobs, Spark props) |
| `orchestrator/config/prod/na/enricher-na-producer-config.json` | JSON | Airflow DAG config for NA enricher producer |
| `orchestrator/config/prod/na/rapi-consumer-na-config.json` | JSON | Airflow DAG config for NA RAPI consumer |
| `orchestrator/config/prod/na/pmp-medallion-config.json` | JSON | Airflow DAG config for NA medallion pipeline (bronze+silver+gold) |
| `orchestrator/config/prod/na/re-calc-processor-na-config.json` | JSON | Airflow DAG config for NA re-calc processor |
| `orchestrator/config/prod/emea/dispatcher-emea-config.json` | JSON | Airflow DAG config for EMEA dispatcher |
| `orchestrator/config/prod/emea/pmp-medallion-config.json` | JSON | Airflow DAG config for EMEA medallion pipeline |

### ApplicationConfig Fields (from YAML)

| Field | Purpose | Example (prod) |
|-------|---------|---------------|
| `git_base_uri` | GitHub Enterprise API base URL | `https://api.github.groupondev.com/repos` |
| `git_config_folder_path` | Config folder path inside repo (`na-prod` or `emea-prod`) | `emea-prod` |
| `git_token` | GitHub API bearer token for config fetching | (secret — see Secrets section) |
| `hudi_base_path` | GCS root path for all Hudi tables | `gs://dataproc-staging-us-central1-810031506929-r0jh1mub/pmp/data/hudi-wh/bronze` |
| `checkpoint_table_name` | Name of the Hudi checkpoint tracking table | `hudi__checkpoint_table` |
| `project_id` | GCP project ID | `prj-grp-mktg-eng-prod-e034` |
| `secret_id` | GCP Secret Manager secret ID (for future use) | `pmp-db-credentials` |
| `target_service_account` | GCP service account for impersonation (for future use) | `grpn-sa-terraform-mktg-eng@prj-grp-central-sa-prod-0b25.iam.gserviceaccount.com` |

### Flow Config YAML Fields

| Field | Purpose | Required |
|-------|---------|----------|
| `flow_name` | Unique identifier for the sync flow | yes |
| `trigger.frequency` | How often this flow runs (informational) | yes |
| `trigger.initial_load` | Whether this is an initial full load | yes |
| `optimization.max_parallel_jobs` | Thread pool size for parallel job execution | no (default: 4) |
| `sync_jobs[].source.type` | Source reader type (currently only `postgres`) | yes |
| `sync_jobs[].source.jdbc_url` | JDBC connection URL for source database | yes |
| `sync_jobs[].source.table` | Fully qualified source table name | yes |
| `sync_jobs[].source.columns` | Column list or `['*']` | yes |
| `sync_jobs[].source.gcp_secret_credentials_key` | Key into secrets.json for DB credentials | yes |
| `sync_jobs[].source.read_checkpoint_column` | Timestamp column used for incremental reads | required unless `full_load: true` |
| `sync_jobs[].source.batch_size` | JDBC fetch size | no (default: 5000) |
| `sync_jobs[].source.full_load` | Skip checkpoint for full table scan | no (default: false) |
| `sync_jobs[].source.partition_column` | Column for JDBC partition parallelism | no |
| `sync_jobs[].source.num_partitions` | Number of JDBC partitions | no (default: 10) |
| `sync_jobs[].source.filters` | Static filter conditions applied in WHERE clause | no |
| `sync_jobs[].sink.type` | Sink type (must be `hudi`) | yes |
| `sync_jobs[].sink.table_name` | Target Hudi table name | yes |
| `sync_jobs[].sink.record_key` | Hudi record key field(s) | yes |
| `sync_jobs[].sink.precombine_key` | Hudi precombine field for deduplication | yes |
| `sync_jobs[].sink.partition_field` | Hudi partition field | no |
| `sync_jobs[].sink.operation` | Hudi write operation (upsert, insert_overwrite_table, etc.) | yes |
| `sync_jobs[].sink.hudi_options` | Additional Hudi write options map | no |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `secrets.json` (file) | Map of database credentials (`username`, `password`) keyed by `gcp_secret_credentials_key` | File bundled in JAR (`/secrets.json` classpath resource) |
| `pmp-db-credentials` | GCP Secret Manager ID (configured but not yet active — currently using file-based approach) | GCP Secret Manager (`prj-grp-mktg-eng-prod-e034`) |
| `git_token` | GitHub Enterprise API bearer token for config file fetching | `application-prod.yaml` / Airflow config JSON |
| `tls--crm-audience-data-workflows` | TLS keystore secret for Dataproc cluster initialisation | GCP Secret Manager (referenced in Dataproc cluster metadata) |
| `pmp-medallion-dag` | Secret for medallion DAG cluster TLS initialisation | GCP Secret Manager (referenced in Dataproc cluster metadata) |

> Secret values are never documented here. Only names and purposes are listed.

## Per-Environment Overrides

| Setting | Local | Staging | Production |
|---------|-------|---------|------------|
| Hudi base path | `/tmp/hudi/hudi-wh` | — | `gs://dataproc-staging-us-central1-810031506929-r0jh1mub/pmp/data/hudi-wh/bronze` |
| Git config folder path | `emea-prod` (same in local) | `emea-prod` / `na-prod` | `emea-prod` / `na-prod` |
| Spark master | `local[2]` | Dataproc cluster | Dataproc cluster |
| GCS connector | Configured but reads local FS | Dataproc native | Dataproc native |
| Airflow config dir | `stable/` | `stable/` | `prod/` |
| Kubernetes namespace | — | `pmp-datasync-staging` | `pmp-datasync-production` |
| Dataproc cluster (medallion NA) | — | — | `pmp-medallion-cluster-na` (18 workers, n2-standard-32) |
| Dataproc cluster (dispatcher NA) | — | — | `pmp-dispatcher-cluster-na` (15 workers, n2-standard-16) |
