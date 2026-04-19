---
service: "sem-gcp-pipelines"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "gcp-composer"
environments: ["dev", "stable", "prod"]
---

# Deployment

## Overview

sem-gcp-pipelines is deployed as Airflow DAG files and a Python ZIP artifact to GCP Composer (managed Airflow). It does not run as a long-lived container service — pipeline execution happens on ephemeral GCP Dataproc clusters that are created per DAG run and deleted on completion (or after 30 minutes of idle time). The deployment is managed by Conveyor's deploy-bot, which copies DAG files to the GCP Composer GCS bucket and manages Kubernetes-namespaced metadata in `us-central1`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Docker container; deployed as Python files to GCS |
| Orchestration | GCP Composer (managed Airflow) | DAGs deployed to Composer-managed GCS DAGs bucket |
| Compute | GCP Dataproc (ephemeral) | Clusters created per pipeline run; `n1-highmem-4` master node; auto-deleted after 30 min idle |
| Artifact storage | GCS + Artifactory | ZIP artifact published to Artifactory, referenced at cluster init |
| Deploy tool | Conveyor deploy-bot (`docker.groupondev.com/dnd_gcp_migration_tooling/deploybot_gcs:v3.0.0`) | Deploys DAG files to Composer bucket |
| Secret management | GCP Secret Manager + Terrabase | Secrets applied via Terrabase HCL config |

## Environments

| Environment | Purpose | Region | Composer URL |
|-------------|---------|--------|-------------|
| dev | Development and testing | us-central1 | `https://d134c969a7dc418dba6e877f8f4fa5b0-dot-us-central1.composer.googleusercontent.com` |
| stable | Pre-production validation | us-central1 | `https://4952faa6ee0242268293dfe488980af0-dot-us-central1.composer.googleusercontent.com` |
| prod | Production traffic | us-central1 | `https://91c76cae09ac40609460f5e26460e6e8-dot-us-central1.composer.googleusercontent.com` |

### GCS Buckets per Environment

| Environment | DAGs Bucket | Data Bucket | Dataproc Project |
|-------------|------------|------------|-----------------|
| dev | `us-central1-grp-shared-comp-155675d0-bucket` | `grpn-dnd-dev-analytics-grp-sem-group` | `prj-grp-consumer-dev-14a6` |
| stable | `us-central1-grp-shared-comp-03dba3de-bucket` | `grpn-dnd-stable-analytics-grp-sem-group` | `prj-grp-c-common-stable-c036` |
| prod | `us-central1-grp-shared-comp-9260309b-bucket` | `grpn-dnd-prod-analytics-grp-sem-group` | `prj-grp-c-common-prod-ff2b` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (uses `@Library("java-pipeline-dsl@dpgm-1396-pipeline-cicd") _` — `dataPipeline` DSL)
- **Trigger**: Push to `main` branch (also `sa360-fix` branch configured as releasable)
- **Deploy target**: `staging-us-central1` (auto-promotes to `production-us-central1`)
- **Artifact**: `orchestrator/**` directory packaged as ZIP, published to Artifactory at `releases/com/groupon/transam/sem-gcp-pipelines/{VERSION}/`

### Pipeline Stages

1. **Build**: Jenkins packages `orchestrator/**` as a versioned ZIP artifact
2. **Publish to Artifactory**: ZIP artifact uploaded to `https://artifactory.groupondev.com/artifactory/releases/com/groupon/transam/sem-gcp-pipelines/`
3. **Deploy to staging**: deploy-bot copies DAG Python files to `COMPOSER_DAGS_BUCKET` in the stable Composer environment
4. **Promote to production**: On successful staging deploy, deploy-bot promotes to production Composer bucket
5. **Secret sync (manual)**: Secrets updated separately via Terrabase — `git submodule update` on `sem-gcp-pipelines-secrets`, then `terrabase apply envs/prod`

### Access Requirements

To deploy, users must be members of Conveyor cloud groups:
- `grp_conveyor_stable_sem-gcp-pipelines`
- `grp_conveyor_production_sem-gcp-pipelines`

(Requested via `https://arq.groupondev.com/ra/ad_subservices/sem-gcp-pipelines`)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Dataproc cluster | Ephemeral per DAG run | Master: `n1-highmem-4`; workers: configured per pipeline in cluster_config |
| Airflow scheduler | GCP Composer managed | No manual scaling — managed by GCP |
| Dataproc parallelism | Spark partition-level | `repartition(kws_df.country)` for keyword submission; `mapred.reduce.tasks: 503` |
| Max active runs | `max_active_runs: 1` per DAG | Prevents concurrent runs of the same DAG |

## Resource Requirements

| Resource | Dataproc Master | Notes |
|----------|----------------|-------|
| Machine type | `n1-highmem-4` | 4 vCPUs, 26 GB RAM |
| Boot disk | `pd-standard`, 20 GB | Standard persistent disk |
| Network | Internal IP only | Uses `sub-vpc-prod-sharedvpc01-us-central1-private` subnet |
| IAP SSH | Enabled (`allow-iap-ssh` tag) | For operator access |
| Idle TTL | 1800 seconds (30 min) | Cluster auto-deleted after idle |
