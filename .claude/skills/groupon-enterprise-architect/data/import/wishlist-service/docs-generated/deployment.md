---
service: "wishlist-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-eu-west-1]
---

# Deployment

## Overview

The Wishlist Service runs as two containerized Kubernetes components — `app` (REST API) and `worker` (background job processor and MBus consumer) — deployed to GCP Kubernetes clusters in US and EMEA regions. Kubernetes deployments are managed using Helm charts (`cmf-jtier-api` and `cmf-jtier-worker`, version 3.94.0) via the `krane` deploy tool, orchestrated by deploy-bot. The CI/CD pipeline is defined in a `Jenkinsfile` using the `java-pipeline-dsl` shared library. On-prem datacenter deployments (snc1, sac1, dub1) exist for legacy environments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (production) | Docker | `src/main/docker/Dockerfile` — FROM `docker.groupondev.com/jtier/prod-java11-jtier:3` |
| Container (CI build) | Docker | `.ci/Dockerfile` — FROM `docker.groupondev.com/jtier/dev-java11-maven:2020-12-04-277a463` |
| Container image registry | docker-conveyor.groupondev.com | `usergeneratedcontent/wishlist-service` |
| Orchestration | Kubernetes | Helm chart `cmf-jtier-api` / `cmf-jtier-worker` (version 3.94.0) |
| Helm deploy tool | krane | `krane deploy` with 300s global timeout; `--no-prune` flag |
| Load balancer / ingress | Hybrid Boundary | `upstreamDomain: wishlist-service`; HTTP port 8080 exposed as port 80 |
| CDN | None documented | — |

## Environments

| Environment | Purpose | Region | Kubernetes Cluster |
|-------------|---------|--------|-------------------|
| `staging-us-central1` | Pre-production validation | US Central 1 (GCP) | `gcp-stable-us-central1` |
| `staging-europe-west1` | Pre-production validation (EMEA) | Europe West 1 (GCP) | `gcp-stable-europe-west1` |
| `production-us-central1` | Production serving (US) | US Central 1 (GCP) | `gcp-production-us-central1` |
| `production-eu-west-1` | Production serving (EMEA) | EU West 1 (AWS) | `production-eu-west-1` |
| `snc1/production` | On-prem production (legacy) | US (SNC1) | On-prem VIP: `mobile-list-service-vip.snc1` |
| `sac1/production` | On-prem production (legacy) | US (SAC1) | On-prem VIP: `mobile-list-service-vip.sac1` |
| `dub1/production` | On-prem production (legacy EMEA) | Dublin (DUB1) | On-prem VIP: `mobile-list-service-vip.dub1` |

## CI/CD Pipeline

- **Tool**: Jenkins (via `java-pipeline-dsl@latest-2` shared library)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch (releasable branches: `master`)
- **Deploy targets (auto)**: `staging-us-central1`, `staging-europe-west1` (from Jenkinsfile)
- **Deploy promotion**: `staging-us-central1` promotes to `production-us-central1`; `staging-europe-west1` promotes to `production-eu-west-1`
- **Notifications**: Slack channel `ugc-notifications`

### Pipeline Stages

1. **Build**: `mvn clean verify` — compiles, runs unit and integration tests, code quality (PMD, FindBugs, JaCoCo)
2. **Docker Build**: Builds the production image using `src/main/docker/Dockerfile`
3. **Push**: Pushes image to `docker-conveyor.groupondev.com/usergeneratedcontent/wishlist-service`
4. **Deploy (Staging US)**: Helm-renders `cmf-jtier-api` + `cmf-jtier-worker` charts with env-specific values; deploys to `wishlist-service-staging` namespace via krane
5. **Deploy (Staging EMEA)**: Same as above for Europe West 1 staging cluster
6. **Promote to Production**: Deploys same artifact to production clusters on explicit promotion

## Kubernetes Components

### App Component

- **Namespace**: `wishlist-service-production` / `wishlist-service-staging`
- **Helm chart**: `cmf-jtier-api` version 3.94.0
- **Config**: `.meta/deployment/cloud/components/app/common.yml` + per-region overrides

### Worker Component

- **Namespace**: `wishlist-service-production` / `wishlist-service-staging`
- **Helm chart**: `cmf-jtier-worker` version 3.94.0
- **Config**: `.meta/deployment/cloud/components/worker/common.yml` + per-region overrides
- **Additional env vars**: `ENABLE_JOBS=true`, `ENABLE_MBUS=true`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (app) | HPA (auto-scaling) | Min: 3 replicas, Max: 10 replicas |
| Horizontal (worker) | HPA (auto-scaling) | Min: 3 replicas, Max: 10 replicas, Target utilization: 100% |
| Memory | Request/Limit | 500Mi request, 500Mi limit (both components) |
| CPU | Request | 100m request (main container); 10m/30m (filebeat sidecar) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 100m | Not set |
| Memory (main) | 500Mi | 500Mi |
| CPU (filebeat) | 10m | 30m |
| Memory (filebeat) | Not specified | Not specified |

## Health Checks

- **Heartbeat path**: `/var/groupon/jtier/heartbeat.txt`
- **Health check port**: 8080
- **Status endpoint**: `GET /grpn/status` (disabled in `.service.yml` `status_endpoint.disabled: true`)
- **Admin port**: 8081 (exposed as `admin-port`)
