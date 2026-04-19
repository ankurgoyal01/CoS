---
service: "webhooks-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

The Webhooks Service is containerized using Docker and deployed to Kubernetes via Groupon's Conveyor platform. Deployments are managed by Deploybot, which uses Helm 3 to render Kubernetes manifests from the per-environment YAML configs under `.meta/deployment/cloud/`. On-prem (legacy SNC1) deployments also exist alongside cloud deployments. Staging is deployed automatically on merge to `main`; production is promoted manually via Deploybot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; base image `node:14.13.1-alpine3.11`; exposes port 80; app compiled with `npx tsc` at build time |
| Registry | Groupon Conveyor Docker | `docker-conveyor.groupondev.com/mobile/webhooks_service` |
| Orchestration | Kubernetes (via Conveyor) | Helm chart `cmf-java-api` version `3.80.6`; rendered and deployed via `krane` |
| Helm chart | `cmf-java-api` | Shared Groupon Helm chart; version `3.80.6`; manifests at `.meta/deployment/cloud/` |
| Deploy tool | Deploybot + krane | Automated staging deploy on merge to `main`; manual production promotion |
| CI pipeline | Jenkins (via Jenkinsfile) | Builds Docker image, runs test steps, deploys to staging targets |
| Log shipping | Filebeat | Log dir `/app/log`; source type `webhooks_service`; high-volume filebeat volume type |
| Metrics | Telegraf | `telegrafUrl` set per environment for metrics shipping |

## Environments

| Environment | Purpose | Region | VIP |
|-------------|---------|--------|-----|
| dev-us-central1 | Developer testing | GCP us-central1 | `webhooks-service.staging.service.us-central1.gcp.groupondev.com` |
| staging-us-central1 | Pre-production validation | GCP us-central1 | `webhooks-service.staging.service.us-central1.gcp.groupondev.com` |
| staging-us-west-1 | Pre-production validation | AWS us-west-1 | (per `staging-us-west-1.yml`) |
| staging-us-west-2 | Pre-production validation | AWS us-west-2 | (per `staging-us-west-2.yml`) |
| production-us-central1 | Production traffic | GCP us-central1 | `webhooks-service.us-central1.conveyor.prod.gcp.groupondev.com` |
| production-us-west-1 | Production traffic | AWS us-west-1 | `webhooks-service.prod.us-west-1.aws.groupondev.com` |
| production-us-west-2 | Production traffic | AWS us-west-2 | `webhooks-service.prod.us-west-2.aws.groupondev.com` |

## CI/CD Pipeline

- **Tool**: Jenkins (via Jenkinsfile) + Deploybot
- **Config**: `Jenkinsfile` at repo root; deploy scripts at `.meta/deployment/cloud/scripts/deploy.sh`
- **Trigger**: Merge to `main` branch automatically triggers staging deploy; production promotion is manual via Deploybot UI

### Pipeline Stages

1. **Checkout**: Clones repository with submodules (`cloneSubModules: true`)
2. **Build Docker image**: Builds container from `Dockerfile`; installs npm dependencies; compiles TypeScript
3. **Test**: Executes `unit_test.sh` inside the container (currently commented out in Jenkinsfile — tests run locally)
4. **Push image**: Publishes tagged image to `docker-conveyor.groupondev.com/mobile/webhooks_service`
5. **Deploy to staging**: Deploybot renders Helm manifests with `helm3 template cmf-java-api` and applies via `krane` to staging targets (`staging-us-west-1`, `staging-us-west-2`, `staging-us-central1`)
6. **Promote to production**: Manual Deploybot `Promote` action applies to production environments

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Kubernetes) | Staging: min 1 / max 1; Production: min 2–3 / max 3 (region-dependent); `hpaTargetUtilization: 100` |
| Memory | Resource requests + limits | See resource table below |
| CPU | Resource requests | See resource table below |

## Resource Requirements

| Resource | Staging Request | Staging Limit | Production Request | Production Limit |
|----------|-----------------|---------------|-------------------|-----------------|
| CPU | 50m | Not set | 100m | Not set |
| Memory | 300Mi | 2Gi | 500Mi | 2Gi |
| Disk | `/app/log` volume | Filebeat high volume | `/app/log` volume | Filebeat high volume |

## Health Checks

- **Readiness probe**: `GET /heartbeat` on port 80; initial delay 20s; period 5s
- **Liveness probe**: `GET /heartbeat` on port 80; initial delay 30s; period 15s
- **Port mapping**: Container port 80 (HTTP); admin port 8081
