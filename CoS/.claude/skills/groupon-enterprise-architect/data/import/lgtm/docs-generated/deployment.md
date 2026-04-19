---
service: "lgtm"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-europe-west1]
---

# Deployment

## Overview

LGTM is deployed as two Helm-managed Kubernetes workloads — Grafana Tempo (distributed mode) and the OpenTelemetry Collector — onto GCP GKE clusters. Deployments are orchestrated by Groupon's deploy bot (DeployBot) using Helm 3 for templating and Krane for Kubernetes resource application. Four deployment targets are defined: two staging regions and two production regions across GCP `us-central1` and `europe-west1`. Staging deployments are automatic (from releasable branches); production deployments are promoted from staging. Grafana dashboards (`grafana/dashboards/*.json`) are managed separately and loaded into the Grafana instance.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Images pulled from `docker.groupondev.com/otel/opentelemetry-collector-contrib` (OTel Collector); Tempo images from `docker.groupondev.com` registry (global registry set in `common.yml`) |
| Orchestration | Kubernetes (GKE) | Managed via `helm3` + `krane`; namespaces `tempo-staging` and `tempo-production` |
| Helm Charts | Helm 3 | `tempo-distributed` v1.32.0 and `opentelemetry-collector` v0.115.0 |
| Deploy tool | Krane | `krane deploy` with `--global-timeout=300s`; `--no-prune` flag used |
| CI/CD | Jenkins | `Jenkinsfile` with `dind_4gb_2cpu` agent; deploys via DeployBot |
| Deploy config | DeployBot v2 | `.deploy_bot.yml`; deploy image `docker.groupondev.com/rapt/deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0` |
| Load balancer | Kubernetes Service (cluster-internal) | Tempo Gateway service; no external load balancer evidenced |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | Kubernetes Cluster |
|-------------|---------|--------|--------------------|
| staging-us-central1 | Pre-production testing (US) | us-central1 | `gcp-stable-us-central1` |
| staging-europe-west1 | Pre-production testing (EMEA) | europe-west1 | `gcp-stable-europe-west1` |
| production-us-central1 | Live production (US) | us-central1 | `gcp-production-us-central1` |
| production-europe-west1 | Live production (EMEA) | europe-west1 | `gcp-production-europe-west1` |

Kubernetes contexts are set per-environment in `.deploy_bot.yml` (e.g., `lgtm-gcp-staging-us-central1`, `lgtm-gcp-production-us-central1`).

## CI/CD Pipeline

- **Tool**: Jenkins (Groovy DSL via `dsl-util-library@latest`)
- **Config**: `Jenkinsfile`
- **Trigger**: On push to releasable branches (`master`, `release`, `main`); PRs do not trigger deploy

### Pipeline Stages

1. **Checkout**: Performs a shallow clone of the repository using `scmCheckout`
2. **Prepare**: Determines branch context, whether this is a PR, and whether the build should be published; computes version patch string from date and git SHA
3. **Build and test**: Executes `/bin/true` — no build or test steps are currently active (infrastructure-only repo)
4. **Validate Deploy Config**: Runs `deploybotValidate()` if `.deploy_bot.yml` is present
5. **Deploy**: Calls `deploybotDeploy()` targeting `staging-us-central1` and `staging-europe-west1`; production deployments are promoted via DeployBot's `promote_to` mechanism

Deploy script (`deploy.sh`) templates both the Tempo and OTel Collector Helm charts and pipes the rendered manifests to `krane deploy` in a single operation.

## Scaling

### Tempo Components (configured in `common.yml`)

| Component | Min Replicas | Max Replicas | Notes |
|-----------|-------------|-------------|-------|
| Ingester | 2 | 10 | `maxUnavailable: 1` for rolling updates |
| Distributor | 1 | 5 | HPA enabled |
| Compactor | 1 | 5 | HPA enabled |
| Querier | 1 | 5 | HPA enabled |
| Query Frontend | 1 | 5 | HPA enabled |

### OpenTelemetry Collector

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (autoscaling) | Min: 1, Max: 10 |
| Mode | deployment (not daemonset) | Configured via `mode: deployment` in common.yml |

## Resource Requirements

> No evidence found in codebase for explicit CPU/memory resource requests and limits in the Helm values files present. Resource configuration is expected to be defined in the Helm chart defaults or applied by cluster-level admission policies.

## GCS Storage

Each environment uses a dedicated GCS bucket for Tempo trace block storage. Access is granted to the Tempo pods via GKE Workload Identity — see [Data Stores](data-stores.md) for bucket names and service account mappings.
