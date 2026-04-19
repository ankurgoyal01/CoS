---
service: "logs-extractor-job"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging", "production"]
---

# Deployment

## Overview

The Log Extractor Job runs as a containerized Kubernetes CronJob in GCP `us-central1`. Two CronJob components are deployed: `cron-job` (the primary job using the default dataset) and `cron-job2` (a secondary job that writes to `log_processor_v2`). Both are deployed under the `orders` service namespace using the Raptor deployment platform (deploy_bot) with Helm. The Docker image is built and published to the internal Conveyor registry via Jenkins on every push to the main branch.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; base image `docker-dev.groupondev.com/node:20` |
| Orchestration | Kubernetes CronJob | Helm chart `cmf-generic-cron-job` v3.90.1; deployed via `krane`; manifests in `.meta/deployment/cloud/` |
| Registry | Conveyor (internal) | Image published as `docker-conveyor.groupondev.com/orders/logs-extractor-job` |
| CI/CD | Jenkins | `Jenkinsfile` uses `dockerBuildPipeline` shared library; deploy target `staging-us-central1_cron2` |
| Service account | GCP IAM | Google Cloud service account JSON mounted as a Kubernetes Secret volume for BigQuery auth |

## Environments

| Environment | Purpose | Region | Cloud Provider |
|-------------|---------|--------|---------------|
| staging | Pre-production validation | GCP us-central1 | GCP (VPC: stable) |
| production | Live log extraction | GCP us-central1 | GCP (VPC: prod) |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: On push to main branch (via `dockerBuildPipeline`)

### Pipeline Stages

1. **Build**: Docker image built from repo root `Dockerfile` using `npm ci --omit=dev`
2. **Publish**: Image pushed to `docker-conveyor.groupondev.com/orders/logs-extractor-job` with the parsed version tag
3. **Deploy**: `deploy_cron2.sh` runs `helm3 template` + `krane deploy` against the `orders-{env}` namespace in the configured Kubernetes context

## CronJob Components

| Component | Schedule | Dataset | Environments |
|-----------|----------|---------|--------------|
| `cron-job` | `1 * * * *` (every hour at minute 1) | Default (`BQ_DATASET_ID`) | staging, (not deployed to production per Jenkinsfile) |
| `cron-job2` | `1 * * * *` (every hour at minute 1) | `log_processor_v2` (via `--bq_dataset` CLI arg) | staging, production |

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Not applicable (CronJob, not a long-running service) | One pod per scheduled execution |
| Memory | Fixed request/limit | Request: 500Mi, Limit: 4Gi |
| CPU | Fixed request | Request: 300m (staging/production), 1000m (common.yml default) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 300m (staging/production) | No explicit limit |
| Memory | 500Mi | 4Gi |
| Disk | Not configured | Not configured |

## Kubernetes Pod Configuration

- **Container command**: `/bin/bash -c`
- **cron-job container args**: `trap "touch /tmp/signals/terminated" EXIT; node src/index.js`
- **cron-job2 container args**: `trap 'touch /tmp/signals/terminated' EXIT; node src/index.js --bq_dataset log_processor_v2`
- **Restart policy**: `OnFailure`
- **Probes**: Liveness and readiness both use `exec: [echo, hi]` (no-op probes for CronJob)
- **Log source type**: `orders_cron-job` (default)
