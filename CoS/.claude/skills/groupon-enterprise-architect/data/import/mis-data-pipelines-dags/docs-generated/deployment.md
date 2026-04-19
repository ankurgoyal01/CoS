---
service: "mis-data-pipelines-dags"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging", "production"]
---

# Deployment

## Overview

`mis-data-pipelines-dags` is deployed as a collection of Python DAG files and supporting scripts uploaded to a GCS bucket that is mounted by GCP Cloud Composer (managed Apache Airflow). DeployBot handles the deployment process using a Docker-based deployment image (`deploybot_gcs:v3.0.0`) that copies the artifact archive from the Jenkins build into the Composer DAGs bucket. The service runs exclusively in GCP `us-central1`. Deployments flow from staging to production via a promotion step configured in DeployBot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (deployment only) | DeployBot image `docker.groupondev.com/dnd_gcp_migration_tooling/deploybot_gcs:v3.0.0` — used for deployment, not runtime |
| Orchestration | GCP Cloud Composer (Kubernetes) | Staging: `gcp-stable-us-central1`; Production: `gcp-production-us-central1` |
| DAG runtime | GCP Cloud Composer 2 | Airflow 2.x; DAG files deployed to Composer GCS bucket |
| Compute | GCP Dataproc | Ephemeral clusters per pipeline; persistent MDS Feeds cluster; Zombie Runner clusters for archival |
| Load balancer | Not applicable | No inbound HTTP traffic |
| CDN | Not applicable | No static assets served |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation; mirrors production pipeline configs | us-central1 | GCP Cloud Composer UI (staging Composer environment) |
| production | Live data pipelines processing real deal and performance data | us-central1 | `https://91c76cae09ac40609460f5e26460e6e8-dot-us-central1.composer.googleusercontent.com/` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (uses shared library `java-pipeline-dsl@dpgm-1396-pipeline-cicd`)
- **Trigger**: On push / PR merge; manual dispatch via DeployBot at `https://deploybot.groupondev.com/MIS/mis-data-pipelines-dags`

### Pipeline Stages

1. **Build**: Jenkins `dataPipeline` step packages the artifact including `mds-archive/**` and `orchestrator/**` directories
2. **Deploy to Staging**: DeployBot uploads artifact to Composer DAGs bucket `us-central1-grp-shared-comp-03dba3de-bucket` in Kubernetes namespace `mis-data-pipelines-staging` on cluster `gcp-stable-us-central1`
3. **Promote to Production**: DeployBot promotes from staging to production target `production-us-central1`; uploads to Composer DAGs bucket `us-central1-grp-shared-comp-9260309b-bucket` in namespace `mis-data-pipelines-production` on cluster `gcp-production-us-central1`
4. **Notify**: Slack notifications sent to `mis-deployment` channel and `grim---pit` channel on start, complete, and override events

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (Janus Spark) | Autoscaling via GCP Dataproc autoscaling policy | Policy `mds-janus-autoscaling-policy`; initial 2 workers (`e2-standard-8`), 27 Spark executor instances |
| Horizontal (MDS Feeds) | Autoscaling via GCP Dataproc autoscaling policy | Policy `mds-feeds-autoscaling-policy`; initial 5 workers (`n1-highmem-16`), master `n1-highmem-32` |
| Horizontal (Deals Cluster) | Manual (fixed worker count) | 8 workers (`e2-highmem-8`) for main job; 2 workers for ILS job |
| Horizontal (DPS pipeline) | Fixed (no autoscaling) | 3 workers (`e2-standard-8`), 8 Spark executor instances |
| Horizontal (Backfill) | Fixed (no autoscaling) | 2 workers (`e2-standard-8`), 6 Spark executor instances |
| Horizontal (Deal Attribute) | Fixed (no autoscaling) | 2 workers (`e2-standard-8`), 8 Spark executor instances |

## Resource Requirements

### Janus Spark Streaming Cluster

| Resource | Per Executor | Total (27 executors) |
|----------|-------------|---------------------|
| CPU cores | 5 | 135 |
| Memory | 2g | 54g |
| Master machine | e2-standard-8 | 500GB boot disk |
| Worker machine | e2-standard-8 | 500GB boot disk (secondary: 750GB) |

### MDS Feeds Persistent Cluster

| Resource | Master | Per Worker (5) |
|----------|--------|---------------|
| Machine type | n1-highmem-32 | n1-highmem-16 |
| Boot disk | 500GB pd-standard | 750GB pd-standard |

### MDS Archive Zombie Runner Clusters

| Cluster | Workers | Notes |
|---------|---------|-------|
| `mds-archive-archival-na-zombie-cluster` | 0 (single-node) | GCE image `zombie-runner-dev`; max idle 12h |
| `mds-archive-archival-emea-zombie-cluster` | 0 (single-node) | Same image; max idle 12h |
| `mds-archive-archival-apac-zombie-cluster` | 0 (single-node) | Same image; max idle 12h |
| `mds-archive-cleanup-zombie-cluster` | 0 (single-node) | Same image; max idle 12h |
| `mds-archive-tableau-zombie-cluster` | 0 (single-node) | Same image; max idle 12h |

All clusters use subnet `sub-vpc-prod-sharedvpc01-us-central1-private` (shared VPC `prj-grp-shared-vpc-prod-2511`) with `internal_ip_only: true` and tag `allow-iap-ssh` for SSH access via GCP IAP.
