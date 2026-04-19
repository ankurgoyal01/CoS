---
service: "b2b-ui"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

The RBAC UI is containerized and deployed to Google Cloud Platform (GCP) Kubernetes clusters via Raptor / DeployBot. The Helm chart `cmf-generic-api` (v3.88.1) is used to render Kubernetes manifests for each environment. Deployments follow a staging-first promotion model: staging auto-deploys on merge, and promotes to production after validation. SOX compliance namespaces are used in both environments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | Built from `.ci/Dockerfile` (Alpine-based Java image for CI); app image: `docker-conveyor.groupondev.com/sox-inscope/b2b-ui` |
| Orchestration | Kubernetes | `cmf-generic-api` Helm chart v3.88.1; manifests rendered via `.meta/deployment/cloud/scripts/deploy.sh` |
| Deployment tool | krane | `krane deploy` with `--global-timeout=300s`; managed by Raptor/DeployBot |
| Load balancer | HTTP | Port 8080 (main), 8081 (admin) |
| Log shipper | Filebeat | JSON logs from `/var/groupon/logs/steno.log`; source type `mx-rbac-ui-service` |

## Environments

| Environment | Purpose | Region | Kubernetes Context |
|-------------|---------|--------|-------------------|
| staging | Pre-production validation | GCP us-central1 | `rbac-ui-gcp-staging-sox-us-central1` |
| production | Live traffic | GCP us-central1 | `rbac-ui-gcp-production-sox-us-central1` |

## CI/CD Pipeline

- **Tool**: DeployBot (Raptor)
- **Config**: `.deploy_bot.yml`
- **Trigger**: Automatic on merge for staging; promotion gate before production

### Pipeline Stages

1. **Build**: Nx builds the Next.js `rbac-ui` application (`nx build rbac-ui`); output to `dist/rbac-ui`
2. **Containerize**: Docker image built and pushed to `docker-conveyor.groupondev.com/sox-inscope/b2b-ui`
3. **Deploy staging**: `bash ./.meta/deployment/cloud/scripts/deploy.sh staging-us-central1 staging rbac-ui-staging-sox` — renders Helm manifest and applies via krane
4. **Promote to production**: After manual or automated approval — `bash ./.meta/deployment/cloud/scripts/deploy.sh production-us-central1 production rbac-ui-production-sox`

## Scaling

| Dimension | Strategy | Staging Config | Production Config |
|-----------|----------|---------------|-----------------|
| Horizontal | Kubernetes HPA | Min: 1, Max: 2, Target CPU: 50% | Min: 1, Max: 4, Target CPU: 50% |
| Memory (main) | Resource limits | Request: 500Mi, Limit: 500Mi | Request: 1Gi, Limit: 2Gi |
| CPU (main) | Resource limits | Request: 500m, Limit: 1000m | Request: 500m, Limit: 2000m |
| Memory (filebeat) | Resource limits | Not configured | Request: 200Mi, Limit: 400Mi |
| CPU (filebeat) | Resource limits | Not configured | Request: 100m, Limit: 2000m |

## Resource Requirements

### Staging

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 500m | 1000m |
| Memory | 500Mi | 500Mi |

### Production

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 500m | 2000m |
| Memory (main) | 1Gi | 2Gi |
| CPU (filebeat) | 100m | 2000m |
| Memory (filebeat) | 200Mi | 400Mi |
