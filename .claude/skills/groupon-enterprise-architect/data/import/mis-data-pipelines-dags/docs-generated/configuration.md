---
service: "mis-data-pipelines-dags"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["airflow-variables", "config-files", "gcp-secret-manager", "deploy-bot-env-vars"]
---

# Configuration

## Overview

`mis-data-pipelines-dags` uses a layered configuration approach. Environment selection is driven by a single Airflow Variable (`env`) that controls which environment-specific JSON config directory is loaded at DAG startup. Per-pipeline cluster and job parameters are stored as JSON files under `orchestrator/config/{env}/`. Archival workflow runtime context is stored in Zombie Runner configuration files (`.zrc2`). Secrets (TLS certificates) are fetched at Dataproc cluster initialization from GCP Secret Manager. Deployment targets are configured in `.deploy_bot.yml` with GCS bucket names and Kubernetes namespaces injected as environment variables.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `env` | Airflow Variable — selects which config directory to load (`dev`, `stable`, `prod`) | yes | none | Airflow Variable store |
| `COMPOSER_DAGS_BUCKET` | GCS bucket where DAG files are deployed by DeployBot | yes | none | DeployBot env var |
| `KUBERNETES_NAMESPACE` | Kubernetes namespace for DeployBot deployment job | yes | none | DeployBot env var |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flag system detected.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `orchestrator/config/{env}/mds_janus_config.json` | JSON | Janus Spark Streaming cluster and job parameters (cluster name, machine types, Spark executor config, Kafka consumer group) |
| `orchestrator/config/{env}/mds_backfill_job_config.json` | JSON | MDS Backfill Spark cluster and job parameters (cluster name, schedule `0 2,14,18 * * *`, machine types, Spark config) |
| `orchestrator/config/{env}/mds_archive_cluster_and_jobs_config.json` | JSON | MDS archival Zombie Runner cluster names, region schedules, country lists (NA: US,CA; EMEA: UK,NL,DE,FR,PL,IT,AE,BE,IE,ES; APAC: AU), data quality check job config, retention metadata |
| `orchestrator/config/{env}/deals_cluster_job_config.json` | JSON | Deals Cluster Spark job config (schedule `0 9 * * *` for main, `0 1 * * *` for ILS, machine types, exclude/include rules) |
| `orchestrator/config/{env}/dps_pipeline_job_config.json` | JSON | Deal Performance Service cluster and job config (data ingestion, bucketing `UserDealBucketingPipeline`, export hourly `DealPerformanceExportPipeline`) |
| `orchestrator/config/{env}/dps_daily_export_today.json` | JSON | Deal performance daily export (today) Spark cluster and job config |
| `orchestrator/config/{env}/dps_daily_export_yesterday.json` | JSON | Deal performance daily export (yesterday) Spark cluster and job config |
| `orchestrator/config/{env}/deal_performance_service.json` | JSON | Deal performance pre-prod cluster and bucketing/export job config |
| `orchestrator/config/{env}/deal_performance_cleanup.json` | JSON | Deal performance data cleanup job config |
| `orchestrator/config/{env}/deal_attribute_data_ingestion.json` | JSON | Deal attribute aggregation Spark job config (schedule not in config; cluster `dataproc-cluster-deal-attribute`) |
| `orchestrator/config/{env}/deal_attribute_data_cleanup.json` | JSON | Deal attribute data cleanup job config |
| `orchestrator/config/{env}/mds_feeds_cluster_lifecycle.json` | JSON | MDS Feeds persistent cluster config (image `2.2.51-debian12`, Livy URL, autoscaling policy, 5 workers `n1-highmem-16`, idle TTL 12h) |
| `orchestrator/config/{env}/mds_feeds_auto_scaling_config.json` | JSON | Autoscaling policy name for MDS Feeds cluster |
| `orchestrator/config/{env}/mds_feeds_auto_scaling_policy.yaml` | YAML | Autoscaling policy parameters for MDS Feeds cluster |
| `orchestrator/config/{env}/mds_janus_auto_scaling_config.json` | JSON | Autoscaling policy name for Janus cluster |
| `orchestrator/config/{env}/mds_janus_auto_scaling_policy.yaml` | YAML | Autoscaling policy parameters for Janus cluster |
| `orchestrator/config/{env}/top_clusters_job_config.json` | JSON | Top clusters job config |
| `orchestrator/config/{env}/delete_cluster.json` | JSON | Cluster deletion job config |
| `orchestrator/config/{env}/bloomreach_sem_cdp_feeds_cleanup.json` | JSON | Bloomreach SEM/CDP feeds GCS cleanup config (bucket `grpn-dnd-prod-analytics-bloomreach-sem-cdp-feeds`, retention 2 days, 13 countries, 3 feed types) |
| `mds-archive/production.zrc2` | YAML (Zombie Runner) | Archival workflow runtime context (MDS URL, host header, GCS bucket/paths, Hive DB/table names, retention days: flat 92, archive 732, DPS ingestion 7, DPS bucketing 30) |
| `mds-archive/staging.zrc2` | YAML (Zombie Runner) | Staging environment archival runtime context |
| `mds-archive/dev.zrc2` | YAML (Zombie Runner) | Dev environment archival runtime context |
| `mds-archive/data-quality-checks/config/{env}/archival_na.conf` | HOCON | NA data quality check metric collection and threshold config (US, CA deal count day-over-day ±5%) |
| `mds-archive/data-quality-checks/config/{env}/archival_emea.conf` | HOCON | EMEA data quality check config |
| `mds-archive/data-quality-checks/config/{env}/archival_apac.conf` | HOCON | APAC data quality check config |
| `.deploy_bot.yml` | YAML | DeployBot deployment targets, Kubernetes clusters, and GCS bucket env vars for staging and production |
| `Jenkinsfile` | Groovy DSL | Jenkins pipeline config (shared library, Slack channel `mis-deployment`, deploy target `staging-us-central1`, artifact patterns) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `tls--mis-mis-data-pipelines` | Metadata key for TLS secret retrieval in GCE metadata; used by Dataproc cluster init to load keystore name | GCP instance metadata (references GCP Secret Manager) |
| `mis_certificate` | MIS TLS client certificate (dev and Janus prod projects) | GCP Secret Manager |
| `mis_certificate_chain` | MIS TLS certificate chain | GCP Secret Manager |
| `mis_private_key` | MIS TLS private key | GCP Secret Manager |
| `certificate_msi` | MIS TLS client certificate (stable project) | GCP Secret Manager |
| `certificate_chain` | TLS certificate chain (stable project) | GCP Secret Manager |
| `private_key_mis` | MIS TLS private key (stable project) | GCP Secret Manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Configuration differs between environments (`dev`, `stable`, `prod`) primarily through the JSON config files in `orchestrator/config/{env}/`:

- **dev**: Points to dev GCP project (`prj-grp-consumer-dev-14a6`), uses dev Composer bucket `us-central1-grp-shared-comp-03dba3de-bucket`, Kubernetes namespace `mis-data-pipelines-staging`
- **stable**: Points to stable GCP project (`prj-grp-mktg-eng-stable-29d2`), uses stable secret names (`certificate_msi`, `private_key_mis`)
- **prod**: GCP project `prj-grp-mktg-eng-prod-e034`, region `us-central1`, Composer bucket `us-central1-grp-shared-comp-9260309b-bucket`, Kubernetes namespace `mis-data-pipelines-production`, Janus project `prj-grp-janus-prod-0808`

Archival zombie runner config selects environment via `env: production` / `env: dev` context keys in `.zrc2` files, which expand into the corresponding GCS path suffixes (`mds_flat_production`, `mds_archive_production`).

MDS archival schedules (in `mds_archive_cluster_and_jobs_config.json`):
- NA archival: `10 1-23/3 * * *` (every 3 hours from 01:10)
- EMEA archival: `20 0-23/3 * * *` (every 3 hours from 00:20)
- APAC archival: `40 2-23/3 * * *` (every 3 hours from 02:40)
- Archival cleanup: `0 9 * * *` (daily at 09:00)
- Tableau stats refresh: `45 1 * * *` (daily at 01:45)
- Bloomreach SEM/CDP cleanup: `0 6 * * *` (daily at 06:00 UTC)
- Deals Cluster job: `0 9 * * *` (daily at 09:00)
- Deals Cluster ILS job: `0 1 * * *` (daily at 01:00)
- MDS Backfill job: `0 2,14,18 * * *` (three times daily)
