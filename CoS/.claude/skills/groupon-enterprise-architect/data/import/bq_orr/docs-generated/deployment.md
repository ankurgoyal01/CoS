---
service: "bq_orr"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

The BigQuery Orchestration Service deploys DAG artifact files to GCS-backed Cloud Composer environments using the `deploybot_gcs` Docker image running on Kubernetes. The pipeline is defined in `Jenkinsfile` using a shared library (`java-pipeline-dsl@dpgm-1396-pipeline-cicd`) and follows a linear promotion chain: dev → staging → production. Production deployments require manual approval. The service itself is not a long-running process — deployment consists of uploading Python DAG files to the target Composer bucket so the Airflow scheduler can pick them up.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `docker.groupondev.com/dnd_gcp_migration_tooling/deploybot_gcs:v3.0.0` |
| Orchestration | Kubernetes | Clusters `gcp-stable-us-central1` (dev/staging) and `gcp-production-us-central1` (production) |
| DAG runtime | Google Cloud Composer | Shared Composer environments; DAGs loaded from GCS buckets |
| Data warehouse | Google BigQuery | Serverless, managed by Google Cloud Platform |
| Load balancer | None | Service has no inbound HTTP traffic |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev-gcp-composer-us-central1 | Development and initial CI validation | us-central1 (GCP) | Not applicable — no HTTP endpoint |
| staging-gcp-composer-us-central1 | Pre-production validation | us-central1 (GCP) | Not applicable — no HTTP endpoint |
| production-gcp-composer-us-central1 | Production data warehouse orchestration | us-central1 (GCP) | https://status.cloud.google.com/ (GCP status) |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to repository (automated); manual dispatch for production promotion
- **Shared library**: `java-pipeline-dsl@dpgm-1396-pipeline-cicd`

### Pipeline Stages

1. **Build and package**: Jenkins invokes the `dataPipeline` shared library step; all files matching `**/*` are included as the deployment artifact.
2. **Deploy to dev**: `deploybot_gcs` uploads DAG files to `us-central1-grp-shared-comp-155675d0-bucket` in the `bigquery-dev` Kubernetes namespace on `gcp-stable-us-central1`. Slack notification posted to `rma-pipeline-notifications`.
3. **Promote to staging**: On successful dev deployment, `deploybot_gcs` uploads DAG files to `us-central1-grp-shared-comp-03dba3de-bucket` in the `bigquery-staging` namespace. Slack notification posted to `grim---pit`.
4. **Promote to production**: Requires manual approval (`manual: true`). On approval, `deploybot_gcs` uploads DAG files to `us-central1-grp-shared-comp-9260309b-bucket` in the `bigquery-production` namespace on `gcp-production-us-central1`. Slack notification posted to `grim---pit`.
5. **Composer pickup**: Cloud Composer detects new/updated DAG files in the GCS bucket and loads them into the Airflow scheduler automatically.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Not applicable — serverless BigQuery; Composer scaling managed by GCP | Not configured in this repo |
| Memory | Not applicable — no long-running service process | Not configured in this repo |
| CPU | Not applicable — no long-running service process | Not configured in this repo |

## Resource Requirements

> Deployment configuration managed externally.

Resource requirements for the `deploybot_gcs` deployment job are managed by the shared deployment tooling. Resource requirements for DAG task execution are managed by the Cloud Composer environment configuration, which is outside the scope of this repository.
