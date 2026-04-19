---
service: "pre_task_tracker"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "Google Cloud Composer (managed Airflow)"
environments: ["dev", "staging", "production"]
---

# Deployment

## Overview

`pre_task_tracker` is deployed as a Python DAG package (not a containerized application) to Google Cloud Composer, Google's managed Apache Airflow service. DAG files are copied to GCS buckets associated with each Composer environment using a custom `deploybot_gcs` deployment image. The service deploys to three separate Composer environments (pipelines, composer/shared, and ingestion), each targeting dev, staging, and production GCP projects. Production deployments require manual approval (`manual: true`).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Python DAG files deployed directly to GCS; no Docker image built for the application itself |
| Orchestration | Google Cloud Composer (managed Airflow) | DAG files uploaded to Composer GCS bucket; Airflow scheduler picks them up automatically |
| Deployment tool | `deploybot_gcs:v3.1.0` | `docker.groupondev.com/dnd_gcp_migration_tooling/deploybot_gcs:v3.1.0` image copies DAG files to the target GCS bucket |
| CI pipeline | Jenkins | `Jenkinsfile` uses `dataPipeline` shared library (`java-pipeline-dsl@dpgm-1396-pipeline-cicd`) |
| Notification | Slack | `#google-groupon-pipelines-pod`, `#rma-pipeline-notifications`, `#dnd-ingestion-ops`, `#grim---pit` |

## Environments

| Environment | Purpose | Cluster | GCS Bucket |
|-------------|---------|---------|------------|
| `dev-gcp-pipelines-us-central1` | Development — Pipelines Composer | `gcp-stable-us-central1` | `us-central1-grp-pre-compose-d632f1c8-bucket` |
| `staging-gcp-pipelines-us-central1` | Staging — Pipelines Composer | `gcp-stable-us-central1` | `us-central1-grp-pre-compose-9cdc6404-bucket` |
| `production-gcp-pipelines-us-central1` | Production — Pipelines Composer | `gcp-production-us-central1` | `us-central1-grp-pre-compose-52d3a0bc-bucket` |
| `dev-gcp-composer-us-central1` | Development — Shared Composer | `gcp-stable-us-central1` | `us-central1-grp-shared-comp-155675d0-bucket` |
| `staging-gcp-composer-us-central1` | Staging — Shared Composer | `gcp-stable-us-central1` | `us-central1-grp-shared-comp-03dba3de-bucket` |
| `production-gcp-composer-us-central1` | Production — Shared Composer | `gcp-production-us-central1` | `us-central1-grp-shared-comp-9260309b-bucket` |
| `dev-gcp-ingestion-us-central1` | Development — Ingestion Composer | `gcp-stable-us-central1` | `us-central1-grp-ingestion-c-1530da7e-bucket` |
| `staging-gcp-ingestion-us-central1` | Staging — Ingestion Composer | `gcp-stable-us-central1` | `us-central1-grp-ingestion-c-d45d2aa7-bucket` |
| `production-gcp-ingestion-us-central1` | Production — Ingestion Composer | `gcp-production-us-central1` | `us-central1-grp-ingestion-c-5afcb1da-bucket` |

All environments target the `us-central1` region.

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push / PR merge (configured via `dataPipeline` shared library)
- **Notify on**: Any start, any failure; pings commit author

### Pipeline Stages

1. **Build**: Jenkins runs the `dataPipeline` DSL; no compile step for Python DAGs
2. **Deploy to dev**: `deploybot_gcs:v3.1.0` copies DAG files to dev GCS buckets for all three Composer environments (pipelines, composer, ingestion) simultaneously; notifies `#google-groupon-pipelines-pod`
3. **Promote to staging**: Automatic promotion after dev succeeds; copies to staging buckets
4. **Promote to production**: Manual approval required; copies to production GCS buckets; production cluster `gcp-production-us-central1`

### Kubernetes Namespaces

Each deployment target uses a dedicated Kubernetes namespace for the `deploybot` deployment pod:

| Environment | Namespace |
|-------------|-----------|
| dev | `pre-airflow-monitoring-dev` |
| staging | `pre-airflow-monitoring-staging` |
| production | `pre-airflow-monitoring-production` |

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Managed by Cloud Composer / Airflow scheduler | `max_active_runs=1` on monitoring DAGs prevents concurrent runs |
| Memory | Managed by Cloud Composer | Composer environment sizing; not configured in this repo |
| CPU | Managed by Cloud Composer | Composer environment sizing; not configured in this repo |

## Resource Requirements

> Deployment configuration managed externally. Resource limits are controlled by the Cloud Composer environment configuration, which is not defined in this repository.
