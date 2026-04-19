---
service: "n8n"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

n8n is deployed as a set of domain-scoped instances on Google Kubernetes Engine (GKE) in `us-central1`. Each instance consists of a StatefulSet-based main worker pod and a horizontally scalable queue-worker Deployment. Deployments are managed by Groupon's Conveyor Cloud platform using Kustomize overlays and per-component YAML configuration files. The n8n application image is pulled from `docker-conveyor.groupondev.com/n8nio/n8n` via a pull-through cache; no custom n8n application image is built. A custom task runner image (`n8n-runner`) is built from `Dockerfile.runners` via GitHub Actions on changes to that file.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container runtime | Docker | Pull-through cache image: `docker-conveyor.groupondev.com/n8nio/n8n` |
| Task runner image | Docker (custom) | Built from `Dockerfile.runners`; pushed to `docker-conveyor.groupondev.com/conveyor-cloud/n8n-runner:<version>` |
| Orchestration | Kubernetes (GKE) | StatefulSet for main worker pods; Deployment for queue-worker pods |
| Manifests | Kustomize | Base at `.meta/kustomize/base/`; overlays at `.meta/kustomize/overlays/<component>/<env>/` |
| Autoscaler | KEDA | Scales queue-worker pods based on Bull queue depth |
| Load balancer | GKE Ingress (VPC-internal) | Editor UI on VPN-accessible domain; webhook/API on public API domain |
| Persistent storage | GKE PersistentVolume | `/home/node/.n8n` (10G staging, 100G production) for n8n data directory |
| Log volumes | GKE PersistentVolume | `/var/groupon/logs` (10G) for structured JSON log files |
| TLS certificates | k8s Secret (volume mount) | Mounted at `/var/groupon/server_certs/` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging (default) | Staging workflow validation | us-central1 (GCP stable VPC) | https://n8n-staging.groupondev.com |
| staging (playground) | Experimental workflows | us-central1 (GCP stable VPC) | https://n8n-playground.groupondev.com |
| production (default) | General internal automation | us-central1 (GCP prod VPC) | https://n8n.groupondev.com |
| production (finance) | Finance team workflows | us-central1 (GCP prod VPC) | https://n8n-finance.groupondev.com |
| production (merchant) | Merchant team workflows | us-central1 (GCP prod VPC) | https://n8n-merchant.groupondev.com |
| production (llm-traffic) | LLM automation workflows | us-central1 (GCP prod VPC) | https://n8n-llm-traffic.groupondev.com |
| production (business) | Business automation workflows | us-central1 (GCP prod VPC) | https://n8n-business.groupondev.com |

Webhook/API endpoints are routed separately:
- Default: `https://n8n-api.groupondev.com`
- Finance: `https://n8n-api-finance.groupondev.com`
- Merchant: `https://n8n-api-merchant.groupondev.com`
- LLM-traffic: `https://n8n-api-llm-traffic.groupondev.com`
- Business: `https://n8n-api-business.groupondev.com`
- Staging: `https://n8n-api-staging.groupondev.com`
- Playground: `https://n8n-api-playground.groupondev.com`

## CI/CD Pipeline

- **Tool**: GitHub Actions + Conveyor Cloud deploy_bot
- **Config**: `.github/workflows/build-n8n-runner.yaml` (custom runner image), `.deploy_bot.yml` (deployment targets)
- **Trigger**: On push to `main` (runner image build); deployment via deploy_bot target promotion

### Pipeline Stages (custom runner image)

1. **build-n8n-runner-pre-release**: Triggered on PR or push to `main` when `Dockerfile.runners` changes. Extracts version from base image tag, builds multi-stage Docker image for `linux/amd64`, pushes to `docker-conveyor.groupondev.com/conveyor-cloud/pre-release/n8n-runner:<version>`.
2. **build-n8n-runner-release**: Triggered on push to `main` only. Pulls pre-release image, re-tags as release (`docker-conveyor.groupondev.com/conveyor-cloud/n8n-runner:<version>`), and pushes release tags.

### Deployment Promotion

Staging deployments promote to production via deploy_bot:
- `staging-default-us-central1` promotes to `production-default-us-central1`
- `staging-queue-worker-us-central1` promotes to `production-queue-worker-us-central1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Queue-worker horizontal (default) | KEDA custom metrics | min: 5, max: 20; scales on `n8n_scaling_mode_queue_jobs_waiting` metric; threshold: 10 |
| Queue-worker horizontal (business, finance, merchant, llm-traffic) | KEDA | min: 2, max: 15; KEDA ScaledObject with 120s scaleDown stabilization window |
| Queue-worker concurrency | Static (per-pod) | `--concurrency=10` per queue-worker pod |
| Main worker (per instance) | Static | min: 1, max: 1 (StatefulSet, single replica) |
| Cron scheduling (default) | Cronscaler | Scale-up Monday 06:00 UTC (max 20), scale-down Friday 22:00 UTC (max 5) |

## Resource Requirements

| Component | CPU Request | Memory Request | Memory Limit | Disk |
|-----------|-------------|----------------|--------------|------|
| default worker (production) | — | 8 GiB | none | 100G (`/home/node/.n8n`) + 10G (logs) |
| finance worker (production) | — | 4 GiB | none | 100G |
| merchant worker (production) | — | 4 GiB | none | 100G |
| llm-traffic worker (production) | — | 8 GiB | none | — |
| business worker (production) | — | 8 GiB | none | — |
| default queue-worker (production) | 2 CPU | 2 GiB | none | — |
| business/finance/etc queue-worker | — | — | none | — |
| n8n-runners sidecar | 100m CPU | 128 MiB | 1256 MiB | — |
| staging worker | — | 150 MiB | 1000 MiB | 10G |
| playground (staging) | — | 512 MiB | 2048 MiB | 100G |
