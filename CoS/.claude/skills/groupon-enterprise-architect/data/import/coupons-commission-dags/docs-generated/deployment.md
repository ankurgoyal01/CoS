---
service: "coupons-commission-dags"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["dev", "stable", "production"]
---

# Deployment

## Overview

coupons-commission-dags is deployed as DAG files to GCP Cloud Composer (managed Airflow) using a custom `deploybot_gcs` deployment image. The CI/CD pipeline is Jenkins-based, using a shared pipeline library. DAG files are pushed to a GCS bucket from which Cloud Composer automatically syncs them into the Airflow environment. The Dataproc clusters used at runtime are ephemeral — created per DAG run and deleted after job completion. The DAGs themselves run within the Cloud Composer Kubernetes environment.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (`deploybot_gcs:v3.0.0`) | `docker.groupondev.com/dnd_gcp_migration_tooling/deploybot_gcs:v3.0.0` — deployment image only |
| Orchestration | Kubernetes (GCP GKE via Cloud Composer) | Kubernetes clusters `gcp-stable-us-central1` (staging) and `gcp-production-us-central1` (prod) |
| DAG delivery | GCS bucket sync | Composer DAGs bucket, synced automatically by Cloud Composer |
| Compute (runtime) | GCP Dataproc (ephemeral) | Cluster created per run, `n1-standard-8` × 3 nodes, deleted after job completion |
| Load balancer | Not applicable | No inbound network traffic |
| CDN | Not applicable | |

## Environments

| Environment | Purpose | Region | GCP Project |
|-------------|---------|--------|-------------|
| dev | Development / ad-hoc testing | us-central1 | `prj-grp-consumer-dev-14a6` |
| stable (staging) | Pre-production integration | us-central1 | `prj-grp-c-common-stable-c036` |
| production | Live commission reporting | us-central1 | `prj-grp-c-common-prod-ff2b` |

### Deployment targets (from `.deploy_bot.yml`)

| Target | Environment | Kubernetes Cluster | Composer DAG Bucket | Namespace |
|--------|-------------|-------------------|---------------------|-----------|
| `staging-us-central1` | staging | `gcp-stable-us-central1` | `us-central1-grp-shared-comp-03dba3de-bucket` | `coupons-commission-reporting-staging` |
| `production-us-central1` | production | `gcp-production-us-central1` | `us-central1-grp-shared-comp-9260309b-bucket` | `coupons-commission-reporting-production` |

Staging promotes automatically to production (`promote_to: production-us-central1`).

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (shared library `java-pipeline-dsl@dpgm-1396-pipeline-cicd`, `dataPipeline` DSL)
- **Trigger**: Push to main branch (automatic); deploy initially targets `staging-us-central1`
- **Slack notifications**: `mis-deployment` channel on `anyStart` and `anyFail`
- **Commit author ping**: Enabled (`pingCommitAuthor: 'true'`)

### Pipeline Stages

1. **Build**: Shared pipeline library validates and packages DAG files
2. **Deploy to staging**: Uploads DAG files to staging Composer GCS bucket in namespace `coupons-commission-reporting-staging`
3. **Promote to production**: After staging deployment succeeds, promotes automatically to `production-us-central1` GCS bucket in namespace `coupons-commission-reporting-production`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Dataproc master | Fixed per run | 1 × `n1-standard-8`, 500 GB pd-standard |
| Dataproc workers | Fixed per run | 2 × `n1-standard-8`, 500 GB pd-standard |
| Dynamic allocation | Disabled | `spark.dynamicAllocation.enabled=false` |
| Airflow workers | Managed by Cloud Composer | No evidence of custom scaling config in this repo |

## Resource Requirements

| Resource | Dataproc Master | Dataproc Worker (×2) |
|----------|-----------------|----------------------|
| CPU | 8 vCPUs (n1-standard-8) | 8 vCPUs each |
| Memory | 30 GB (n1-standard-8) | 30 GB each |
| Disk | 500 GB pd-standard | 500 GB pd-standard each |

> Airflow worker resource requirements are managed by the Cloud Composer environment configuration, not by this repository.
