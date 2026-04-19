---
service: "ckod-ui"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production-us-central1, production-us-west-1]
---

# Deployment

## Overview

ckod-ui is containerised with Docker (multi-stage build using `node:18-alpine`) and deployed to Google Cloud Platform (GCP) Kubernetes clusters managed by Groupon's Conveyor platform. The CI/CD pipeline runs in Jenkins using the `dockerBuildPipeline` shared library. Deployments are promoted from staging to production via Deploybot. The application listens on port 8080 and runs as a Next.js standalone server (`node server.js`).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker (node:18-alpine) | `Dockerfile` at repo root; multi-stage build (builder + runner) |
| Container registry | `docker-conveyor.groupondev.com/pre/ckod-ui` | Groupon internal Docker registry |
| Orchestration | Kubernetes (GCP) | Conveyor platform; manifests generated from `.meta/deployment/cloud/` YAML |
| Deployment tool | Deploybot | `https://deploybot.groupondev.com/PRE/ckod-ui` |
| Load balancer | Conveyor VIP | Per-environment VIP hostname |
| Log shipping | Filebeat | JSON logs from `/app/logs/ckod-ui.log`; source type `ckod-ui-logging` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation | GCP us-central1 (stable VPC) | `https://dataops-staging.groupondev.com` |
| production-us-central1 | Primary production | GCP us-central1 (prod VPC) | `https://dataops.groupondev.com` |
| production-us-west-1 | Secondary production | us-west-1 | VIP: `ckod-ui.production.service.us-west-1.gcp.groupondev.com` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: Push to `main` or `release` branch; tag push for release builds
- **Shared library**: `java-pipeline-dsl@latest-2` (`dockerBuildPipeline`)

### Pipeline Stages

1. **Build capture**: Jenkins records `GIT_REF`, `GITHUB_BRANCH`, `BUILD_NUMBER`, `TAG_NAME`, and generates `BUILD_DATE` in ISO 8601 format
2. **Version determination**: If `TAG_NAME` is set, `BUILD_VERSION` = tag; otherwise `BUILD_VERSION` = `{branch}-{buildNumber}`
3. **Docker build**: Runs `npm ci`, `npm run generate` (Prisma), `npm run build` (Next.js standalone); embeds build metadata as Docker `ARG`/`ENV`
4. **Docker push**: Pushes image to `docker-conveyor.groupondev.com/pre/ckod-ui`
5. **Slack notification**: Notifies `#C01DQ135TKL` Slack channel on start, complete, or override events
6. **Auto-deploy to staging**: After successful build, triggers deployment to `staging-us-central1` via Deploybot
7. **Manual promote to production**: Engineer promotes the staging deployment to `production-us-central1` or `production-us-west-1` via Deploybot

### Deployment Procedure

**Staging:**
1. Verify all Jenkins checks pass on the commit
2. Navigate to `https://deploybot.groupondev.com/PRE/ckod-ui`
3. Click the trigger for the most recent deployment matching the Jenkins build timestamp
4. Authorize the deployment and monitor Deploybot logs

**Production:**
1. Confirm a successful staging deployment exists
2. Click "Promote" on the staging deployment in Deploybot
3. Confirm promotion to the target production environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | min: 2, max: 15, target CPU utilisation: 50% (common); staging: min 1, max 2 |
| Memory | Fixed request/limit | 4194 MiB request, 4194 MiB limit |
| CPU | Fixed request | 1000m request |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | not set (unlimited) |
| Memory | 4194 MiB | 4194 MiB |
| Disk | — | Log volume via Filebeat (low volumeType) |

## Additional Operations

### Rolling Restart (zero-downtime)

```bash
kubectl rollout restart deployment ckod-ui--app--default
```

### Accessing Kubernetes Context

```bash
kubectl cloud-elevator auth
kubectl config use-context gcp-<dev|staging|production>-us-central1
kubectl config set-context --current --namespace ckod-ui-<dev|staging|production>
watch kubectl get pods
```

### Required Access Groups

- `grp_conveyor_stable_ckod-ui`
- `grp_conveyor_production_ckod-ui`
- `grp_conveyor_privileged_ckod-ui`
