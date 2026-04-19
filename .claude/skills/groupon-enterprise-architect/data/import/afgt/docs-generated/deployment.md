---
service: "afgt"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

AFGT is deployed as a containerized data pipeline using DeployBot on Kubernetes (GCP). The deployment image is `docker.groupondev.com/dnd_gcp_migration_tooling/deploybot_gcs:v3.0.0`. The deployment process copies the pipeline DAG Python files and artifact ZIP to Cloud Composer (Apache Airflow) DAG buckets on GCS. The actual compute runs ephemerally on Google Cloud Dataproc clusters, which are created and deleted per pipeline run. Production deployment is a manual promotion step from staging. CI/CD is managed by Jenkins using the `java-pipeline-dsl` shared library.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `docker.groupondev.com/dnd_gcp_migration_tooling/deploybot_gcs:v3.0.0` |
| Orchestration | Kubernetes | Namespaces: `dnd-bia-data-engineering-{env}` |
| DAG hosting | Google Cloud Composer (Airflow) | DAGs deployed to `COMPOSER_DAGS_BUCKET` per environment |
| Compute | Google Cloud Dataproc (ephemeral) | Cluster `afgt-sb-td` created per run, deleted after completion |
| Artifact store | GCS / Artifactory | Pipeline ZIP artifact at `/com/groupon/dnd-bia-data-engg/afgt/{version}/afgt-{version}.zip` |
| Networking | GCP Shared VPC | Internal IP only; subnetwork per environment; tags `allow-iap-ssh`, `dataproc-vm`, `allow-google-apis` |
| Notifications | Slack | Channel `rma-pipeline-notifications` for deploy events and pipeline failures |

## Environments

| Environment | Purpose | Region | Kubernetes Cluster |
|-------------|---------|--------|-------------------|
| `dev` | Development and integration testing | us-central1 | `gcp-stable-us-central1` |
| `staging` | Pre-production validation | us-central1 | `gcp-stable-us-central1` |
| `production` | Live revenue analytics pipeline | us-central1 | `gcp-production-us-central1` |

Cloud Composer DAG buckets per environment:
- **dev**: `us-central1-grp-shared-comp-155675d0-bucket`
- **staging**: `us-central1-grp-shared-comp-03dba3de-bucket`
- **production**: `us-central1-grp-shared-comp-9260309b-bucket`

## CI/CD Pipeline

- **Tool**: Jenkins (`java-pipeline-dsl@dpgm-1396-pipeline-cicd` shared library)
- **Config**: `Jenkinsfile`
- **Trigger**: Release tags only (`onlyReleaseTags: true`) on branches `release` or `main`

### Pipeline Stages

1. **Build**: Jenkins `dataPipeline` step packages the pipeline artifact ZIP
2. **Deploy to dev**: Automatic deployment to `dev-us-central1` target on release tag; notifies `rma-pipeline-notifications` Slack channel on start and completion
3. **Promote to staging**: Automatic promotion from dev to `staging-us-central1`
4. **Promote to production**: Manual promotion from staging to `production-us-central1`; requires manual approval (`manual: true`)

Failure and start notifications are sent to Slack channel `rma-pipeline-notifications`. Commit author is pinged on failure (`pingCommitAuthor: true`).

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Dataproc cluster — dev/stable | Fixed size | 1 master + 4 workers, `n1-standard-16`, 500GB PD |
| Dataproc cluster — production | Fixed size with preemptibles | 1 master + 2 primary workers + 2 preemptible secondary workers, `n1-standard-16` |
| Dataproc cluster — sandbox | Single node | 1 master + 0 workers, `n1-standard-8`, 500GB PD |
| Sqoop parallelism | Fixed mappers | `--num-mappers 20` in `td_to_hive.sh` |
| Airflow DAG | `max_active_runs: 1` | Only one concurrent run allowed; `catchup: False` |

## Resource Requirements

| Resource | Configuration | Notes |
|----------|--------------|-------|
| Master node | `n1-standard-16` (16 vCPU, 60 GB RAM), 500 GB PD | Per `rm_afgt_connex_config.json` (dev/stable/prod) |
| Worker nodes | `n1-standard-16` (16 vCPU, 60 GB RAM), 500 GB PD | 4 workers (dev/stable), 2+2 preemptible (prod), 0 (sandbox) |
| Cluster image | `zombie-runner-dev` family | `projects/prj-grp-data-compute-dev-2c47/global/images/family/zombie-runner-dev` |
| Idle timeout | 1800s (dev/stable), 3600s (prod), 45m (sandbox) | Cluster auto-deletes after idle |
| Service account scopes | `https://www.googleapis.com/auth/cloud-platform` | Full GCP platform access scoped to project |

> Deployment configuration for the Kubernetes deploy job (resource requests/limits) is managed by the DeployBot platform externally to this repository.
