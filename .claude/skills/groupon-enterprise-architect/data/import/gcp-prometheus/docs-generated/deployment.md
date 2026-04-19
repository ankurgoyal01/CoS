---
service: "gcp-prometheus"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-europe-west1]
---

# Deployment

## Overview

`gcp-prometheus` is deployed as a set of Kubernetes StatefulSets and Deployments on GKE clusters across two GCP regions (`us-central1` and `europe-west1`). Infrastructure is managed via Helm charts (`charts/thanos-groupon-stack`, `charts/grafana`) with per-environment values files. Deployments are orchestrated by Jenkins using the `java-pipeline-dsl` shared library and deployed via `krane` to the `telegraf-<env>` namespaces.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container runtime | Docker | `FROM busybox` stub Dockerfile at repo root (deployment images referenced directly in Helm templates) |
| Orchestration | Kubernetes (GKE) | StatefulSets and Deployments in `telegraf-staging` / `telegraf-production` namespaces |
| Helm chart (Thanos stack) | Helm v3 | `charts/thanos-groupon-stack/` |
| Helm chart (Grafana) | Helm v3 | `charts/grafana/` |
| Deployment tooling | krane | Applied via `deploy-gcp.sh` with `--global-timeout=300s` |
| Node pool | GKE `monitoring-platform` | All Thanos and Grafana workloads scheduled on dedicated monitoring node pool via `cloud.google.com/gke-nodepool=monitoring-platform` node affinity |
| Load balancer | Internal / External LB | Thanos Querier: `serviceLB.enableGateway: true` for hybrid boundary gateway access |
| Internal base URL | — | `http://thanos.us-central1.prometheus.stable.gcp.groupondev.com/` |
| External base URL | — | `https://thanos.us-central1.prometheus.stable.gcp.groupondev.com/` |

## Environments

| Environment | Purpose | Region | Kubernetes Cluster |
|-------------|---------|--------|--------------------|
| `staging-us-central1` | Pre-production validation | us-central1 | `gcp-stable-us-central1` |
| `staging-europe-west1` | Pre-production validation (EMEA) | europe-west1 | `gcp-stable-europe-west1` |
| `production-us-central1` | Live production (US/Canada) | us-central1 | `gcp-production-us-central1` |
| `production-europe-west1` | Live production (EMEA) | europe-west1 | `gcp-production-europe-west1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Library**: `java-pipeline-dsl@latest-2`
- **Trigger**: Git push; pipeline builds Docker image and deploys to `staging-europe-west1` by default

### Pipeline Stages

1. **Docker Build**: Builds the stub Docker image (used as a deploy trigger; actual component images are referenced in Helm templates)
2. **Deploy to Staging**: Runs `deploy-gcp.sh staging-europe-west1 staging` via `krane`; promotes to production target after validation
3. **Promote to Production**: Triggered after staging success; runs `deploy-gcp.sh production-<region> production` via `krane`

### Deploy Script (`deploy-gcp.sh`)

```bash
helm3 template stable charts/thanos-groupon-stack \
  -f .meta/deployment/cloud/components/thanos-stack/<target>.yml \
  -f .meta/deployment/cloud/secrets/thanos/gcp/<target>.yml \
| krane deploy telegraf-<env> <KUBE_CONTEXT> \
    --global-timeout=300s --filenames=- --no-prune
```

## Scaling

### Thanos Receive

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed replicas | 5 replicas (StatefulSet, `OrderedReady`) |
| Memory | Fixed limits | 152Mi request / (values-defined limit) |
| CPU | Fixed limits | 5m request / 500m limit |
| Storage | PVC per pod | 2000Gi `ReadWriteOnce` per replica |

### Thanos Query

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed / HPA | 10 replicas (production), 5-10 min/max (staging HPA) |
| Memory | Fixed limits | 5Gi request / 80Gi limit |
| CPU | Fixed limits | 500m request |

### Thanos Store Gateway (each shard)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed replicas | 3 replicas per shard (thanos-store-1, thanos-store-2, thanos-store-3) |
| Memory | Fixed limits | 35Gi request / 100Gi limit |
| CPU | Fixed limits | 3 request / 10 limit |
| Storage | PVC per pod | 1000Gi `ReadWriteOnce` per replica |

### Thanos Compact

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Single instance | 1 replica (StatefulSet) |
| Memory | Fixed limits | 123Mi request / 420Mi limit |
| CPU | Fixed limits | 123m request / 420m limit |
| Storage | PVC | 100Gi `ReadWriteOnce` |

### Grafana

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed replicas | 3 replicas |
| Memory | — | values-defined |
| CPU | — | values-defined |

## Resource Requirements

### Thanos Receive (per pod)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 5m (filebeat) + main (values) | 500m (filebeat) |
| Memory | 152Mi (filebeat) + main (values) | 320Mi (filebeat) |
| Disk | 2000Gi (PVC) | — |

### Thanos Store Gateway (per pod)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 3 cores | 10 cores |
| Memory | 35Gi | 100Gi |
| Disk | 1000Gi (PVC) | — |

### Thanos Query (per pod)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 500m | — |
| Memory | 5Gi | 80Gi |

### Thanos Compact (per pod)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 123m | 420m |
| Memory | 123Mi | 420Mi |
| Disk | 100Gi (PVC) | — |

### Grafana (filebeat sidecar)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 50m | 180m |
| Memory | 75Mi | 100Mi |
