---
service: "megatron-gcp"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["dev", "staging", "production"]
---

# Deployment

## Overview

Megatron GCP is deployed as a Docker container via a Jenkins CI/CD pipeline using the `dataPipeline` DSL. The container runs the DAG generator scripts (`megatron_dag_generator.py`, `utils.py`, validation generators) and writes generated Airflow DAG Python files to the Composer DAGs GCS bucket. The generated DAGs are then picked up by Apache Airflow running on GCP Cloud Composer in `us-central1`. Kubernetes is used only for the deploy bot container orchestration (`deploybot_gcs`); the actual pipeline workload runs on GCP Dataproc clusters created ephemerally per DAG run.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; base image `docker.groupondev.com/python:3.8.12` |
| Orchestration | Kubernetes (deploy bot) | Deploy bot image `docker.groupondev.com/dnd_gcp_migration_tooling/deploybot_gcs:v3.0.0` |
| DAG runtime | GCP Cloud Composer (managed Airflow) | Composer 2.x, region `us-central1` |
| Data compute | GCP Dataproc | Ephemeral clusters created per DAG run, region `us-central1`, max age 12h, max idle 1h |
| Load balancer | Not applicable — batch pipeline service | — |
| CDN | Not applicable | — |

## Environments

| Environment | Purpose | Region | Kubernetes Cluster |
|-------------|---------|--------|--------------------|
| dev | Development and integration testing | us-central1 | `gcp-stable-us-central1` |
| staging | Pre-production validation | us-central1 | `gcp-stable-us-central1` |
| production | Live data ingestion | us-central1 | `gcp-production-us-central1` |

### Composer DAGs Buckets

| Environment | Bucket |
|-------------|--------|
| dev | `us-central1-grp-ingestion-c-1530da7e-bucket` |
| staging | `us-central1-grp-ingestion-c-d45d2aa7-bucket` |
| production | `us-central1-grp-ingestion-c-5afcb1da-bucket` |

### Kubernetes Namespaces

| Environment | Namespace |
|-------------|-----------|
| dev | `megatron-gcp-dev` |
| staging | `megatron-gcp-staging` |
| production | `megatron-gcp-production` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: on push to any branch (non-tag), or on release tags
- **Slack notifications**: `#dnd-ingestion-ops` on start and failure; commit author pinged on failure

### Pipeline Stages

1. **Build**: Docker image is built from the repo root `Dockerfile`
2. **Optional build step**: Runs the DAG generator container (`docker run -v pwd/orchestrator:/app/orchestrator --rm $(docker build -q .)`) to generate DAG files into the `orchestrator/` directory
3. **Deploy to dev-us-central1**: Deploy bot (`deploybot_gcs`) uploads generated DAGs to the dev Composer bucket; promotes to staging
4. **Deploy to staging-us-central1**: Deploy bot uploads to staging Composer bucket; promotes to production (requires manual approval)
5. **Deploy to production-us-central1**: Manual gate; deploy bot uploads to production Composer bucket; notifies `#dnd-ingestion` Slack channel

### Promotion Chain

```
dev-us-central1 -> staging-us-central1 -> production-us-central1 (manual)
```

## Dataproc Cluster Configuration

Clusters are created dynamically by each DAG run. Key parameters:

| Parameter | Value |
|-----------|-------|
| Region | `us-central1` |
| Subnet | `projects/{shared-vpc-project}/regions/us-central1/subnetworks/sub-vpc-{env}-sharedvpc01-us-central1-private` |
| Max idle | 1 hour |
| Max age | 12 hours |
| Network tags | `allow-iap-ssh`, `dataproc-vm` |
| Dataproc Metastore (SOX) | `projects/{dl-secure-project}/locations/us-central1/services/grp-dpms-{env}-metastore-etl` |
| Dataproc Metastore (non-SOX) | `projects/{datalake-project}/locations/us-central1/services/grpn-dpms-{env}-pipelines` |

### Cluster Size Codes (MySQL config)

| Code | Workers | Use case |
|------|---------|---------|
| ES | 1 | Extra-small single-node |
| S | 2 | Small |
| M | 4 | Medium |
| L | 8 | Large |
| XL | 12 | Extra-large |

### Machine Types by Mode

| Mode | Master | Worker |
|------|--------|--------|
| sqoop | e2-standard-4 | e2-standard-4 |
| load | e2-standard-2 | e2-standard-4 |
| full_load | e2-standard-8 | e2-standard-8 |
| merge | e2-standard-8 | e2-standard-8 |
| audit | n2-standard-4 | n2-standard-4 |
| cleanup | e2-standard-2 | e2-standard-2 |

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (cluster workers) | YAML-defined per service/partition/mode; overridable at DAG run time | ES/S/M/L/XL codes in `dag_config/*.yaml` |
| Peak overrides | Airflow Variables set peak machine types and worker counts | `MEGATRON_NUM_WORKERS_PEAK`, `MEGATRON_MASTER_MACHINE_TYPE_PEAK`, `MEGATRON_WORKER_MACHINE_TYPE_PEAK` |
| DAG concurrency | Per-DAG Airflow setting | `DEFAULT_CONCURRENCY: 2`, `AUDIT_CONCURRENCY: 4` |
| Max concurrent DAG runs | 1 per DAG | `max_active_runs = 1` |

## Resource Requirements

> Deployment configuration managed by GCP Cloud Composer and the deploy bot; no static K8s resource manifests in this repository.
