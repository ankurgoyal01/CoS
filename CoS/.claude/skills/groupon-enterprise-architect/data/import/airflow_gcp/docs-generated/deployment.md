---
service: "airflow_gcp"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "Google Cloud Composer (managed Airflow)"
environments: [development, staging, production]
---

# Deployment

## Overview

The Airflow GCP SFDC ETL service is deployed as a Python DAG package to Google Cloud Composer, which is a managed Apache Airflow service on GCP. There is no Docker container to build or Kubernetes manifest to manage directly — deployment consists of pushing Python DAG files to the shared Composer GCS bucket under the path `salesforce/airflow_gcp`. The CI/CD pipeline is run by Cloud Jenkins using the `dataPipeline` shared library. Deploybot manages environment promotion and rollback.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None (no Docker image) | DAG files deployed directly as Python source to GCS bucket |
| Orchestration | Google Cloud Composer (managed Airflow) | Shared Composer instance; DAGs land at `us-central1-grp-shared-comp-9260309b-bucket/dags/salesforce/airflow_gcp` |
| DAG staging bucket (prod) | Google Cloud Storage | `grpn-us-central1-airflow-sfdc-etl-production` |
| DAG staging bucket (staging) | Google Cloud Storage | `grpn-us-central1-airflow-sfdc-etl-staging` |
| DAG staging bucket (dev) | Google Cloud Storage | `test-sfdc-etl-bucket` |
| CI/CD | Cloud Jenkins | https://cloud-jenkins.groupondev.com/job/salesforce/job/airflow_gcp |
| Release management | Deploybot | https://deploybot.groupondev.com/salesforce/airflow_gcp |

## Environments

| Environment | Purpose | Region | Airflow UI URL |
|-------------|---------|--------|----------------|
| development (dev) | Development and testing of new DAGs | us-central1 | https://d134c969a7dc418dba6e877f8f4fa5b0-dot-us-central1.composer.googleusercontent.com/home |
| staging (stable) | Pre-production validation | us-central1 | https://4952faa6ee0242268293dfe488980af0-dot-us-central1.composer.googleusercontent.com/home |
| production (prod) | Live Salesforce data sync | us-central1 | https://91c76cae09ac40609460f5e26460e6e8-dot-us-central1.composer.googleusercontent.com/home |

## CI/CD Pipeline

- **Tool**: Cloud Jenkins (shared library `java-pipeline-dsl@dpgm-1396-pipeline-cicd`)
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: Push to `release` or `main` branch; deploy target: `dev-us-central1`

### Pipeline Stages

1. **Build**: Jenkins `dataPipeline` shared library validates the DAG package
2. **Deploy to dev**: Copies DAG files to development Composer bucket path `salesforce/airflow_gcp`
3. **Deploybot promotion**: Engineers use Deploybot to promote the build to staging and production environments
4. **Validation**: DAGs appear in Airflow UI; engineers verify in the DAGs UI before enabling

## Rollback

Rollback is performed through Deploybot by reverting to a previous successful commit. The DAG files in the Composer bucket are overwritten with the previous version. Individual DAGs can also be paused via the Airflow DAGs UI toggle without a full rollback.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Managed by Cloud Composer (Airflow worker pool) | Controlled by Composer environment configuration — not managed in this repo |
| Memory | Managed by Cloud Composer | Controlled by Composer environment configuration |
| CPU | Managed by Cloud Composer | Controlled by Composer environment configuration |

## Resource Requirements

> Deployment configuration managed externally. Resource sizing is controlled by the shared Cloud Composer environment configuration, not by this repository.

## DAG Deployment Path

After a successful production deployment, DAG files are available at:

```
us-central1-grp-shared-comp-9260309b-bucket/dags/salesforce/airflow_gcp
```

Access to Cloud Composer environments requires GCP IAM permissions. See: https://groupondev.atlassian.net/wiki/spaces/DPM/pages/80728621209/Shared+Composer
