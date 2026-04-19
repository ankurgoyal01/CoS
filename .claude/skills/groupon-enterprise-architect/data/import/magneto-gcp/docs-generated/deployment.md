---
service: "magneto-gcp"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev-us-central1, staging-us-central1, production-us-central1]
---

# Deployment

## Overview

magneto-gcp is containerized as a Docker image and deployed to Kubernetes via Groupon's DeployBot system. The primary deployment artifact is the Docker image, which contains the DAG Generator Python scripts. At deploy time, the container runs three generator scripts that produce Airflow DAG Python files and writes them to the Composer DAGs GCS bucket (`COMPOSER_DAGS_BUCKET`), making the generated DAGs available to Cloud Composer. The deployment pipeline is managed by Jenkins using the `dataPipeline` DSL shared library. Promotion flows from `dev-us-central1` to `staging-us-central1` to `production-us-central1` (production is manual-gate).

---

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repository root; base image `docker.groupondev.com/python:3.8.12` |
| Orchestration | Kubernetes (GKE) | DeployBot deploys to GKE clusters via `deploybot_gcs:v3.0.0` deployment image |
| DAG Deployment | GCS (`gsutil`) | DeployBot copies generated DAG files to `COMPOSER_DAGS_BUCKET` for Cloud Composer pickup |
| ETL Compute | Google Cloud Dataproc | Ephemeral clusters provisioned per DAG run; not part of base deployment |
| Load balancer | Not applicable | No inbound HTTP traffic |
| CDN | Not applicable | No frontend |

---

## Environments

| Environment | Purpose | Region | Kubernetes Cluster |
|-------------|---------|--------|-------------------|
| `dev-us-central1` | Development / integration testing | us-central1 | `gcp-stable-us-central1` |
| `staging-us-central1` | Pre-production validation | us-central1 | `gcp-stable-us-central1` |
| `production-us-central1` | Production ingestion (manual gate) | us-central1 | `gcp-production-us-central1` |

### Environment-specific Composer DAGs Buckets

| Environment | COMPOSER_DAGS_BUCKET | Kubernetes Namespace |
|-------------|---------------------|---------------------|
| dev | `us-central1-grp-ingestion-c-1530da7e-bucket` | `magneto-gcp-dev` |
| staging | `us-central1-grp-ingestion-c-d45d2aa7-bucket` | `magneto-gcp-staging` |
| production | `us-central1-grp-ingestion-c-5afcb1da-bucket` | `magneto-gcp-production` |

---

## CI/CD Pipeline

- **Tool**: Jenkins (shared library `java-pipeline-dsl@dpgm-1396-pipeline-cicd`)
- **Config**: `Jenkinsfile` at repository root
- **Trigger**: Push to any branch or tag; Slack notification to `#dnd-ingestion-ops` on start and failure; commit author pinged on failure

### Pipeline Stages

1. **Build Docker image**: Builds the Docker image from `Dockerfile`; installs Python 3.8 dependencies from `dag_generator/requirements.txt` constrained to Airflow 2.10.5
2. **Optional build step (pre-validation)**: Runs `docker run ... $(docker build -q .)` to execute the orchestrator scripts inside the image — validates DAG generation succeeds before deploy
3. **Deploy to dev-us-central1**: DeployBot pushes image and runs DAG generator; writes DAGs to dev Composer bucket; promotes automatically to staging
4. **Deploy to staging-us-central1**: Automatic promotion from dev; writes DAGs to staging Composer bucket; promotes automatically to production gate
5. **Deploy to production-us-central1**: Manual approval gate; DeployBot writes DAGs to production Composer bucket; `notify_events: start, complete, override`

---

## Scaling

Magneto-gcp's scaling model is per-table Dataproc cluster sizing, not Kubernetes pod scaling. The deploy container is a one-shot DAG generator job.

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Dataproc cluster (horizontal) | Per-table node count in `dag_factory_config.yaml` | ES=1, S=2, M=4, L=6, XL=8, XXL=16 nodes |
| Dataproc machine type | `e2-highmem-4` master and worker (overridable via Airflow Variables) | `MAGNETO_NUM_WORKERS_PEAK`, `MAGNETO_MASTER_MACHINE_TYPE_PEAK`, `MAGNETO_WORKER_MACHINE_TYPE_PEAK` |
| Extract parallelism | Per-table `extract_slot` config (1–8 parallel extract parts) | `DEFUALT_EXTRACT_SLOT=1`, `max_extract_slot=8` |
| DAG concurrency | `max_active_runs=1` per DAG (one cluster per table at a time) | Hardcoded in DAG template |

---

## Resource Requirements

> No evidence found in codebase for Kubernetes pod resource requests/limits. The Kubernetes deploy job is a short-lived container that generates DAG files and exits. Compute-intensive work runs on Dataproc, not on Kubernetes pods.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not configured | Not configured |
| Memory | Not configured | Not configured |
| Disk | Not configured | Not configured |
