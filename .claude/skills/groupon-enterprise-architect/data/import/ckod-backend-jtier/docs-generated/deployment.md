---
service: "ckod-backend-jtier"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

CKOD Backend JTier is deployed as two Kubernetes workloads (`app` and `worker`) from a single Docker image (`docker-conveyor.groupondev.com/pre/ckod-backend-jtier`). The image is built from `src/main/docker/Dockerfile` using a JTier production Java 17 base image. Deployments are managed via Deploybot and Conveyor across six Kubernetes environments spanning AWS and GCP regions. The CI/CD pipeline runs on Jenkins using the `jtierPipeline` shared library, which handles build, test, Docker image push, and automatic promotion to staging.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — `docker.groupondev.com/jtier/prod-java17-jtier:3` base |
| CI Build container | Docker | `.ci/Dockerfile` — `docker.groupondev.com/jtier/dev-java17-maven:2023-12-19-609aedb` |
| Orchestration | Kubernetes (Conveyor) | Manifests generated from `.meta/deployment/cloud/` via Conveyor/Raptor |
| Deployment tool | Deploybot | `https://deploybot.groupondev.com/PRE/ckod-backend-jtier` |
| Load balancer | Kubernetes Service / VIP | VIP: `ckod-api.production.service.us-central1.gcp.groupondev.com` (production GCP) |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Cloud | Region | Kubernetes Context |
|-------------|---------|-------|--------|-------------------|
| dev | Developer testing | GCP | us-central1 | `ckod-api-gcp-dev-us-central1` |
| staging | Pre-production validation | AWS | us-west-2 | `ckod-api-staging-us-west-2` |
| staging | Pre-production validation | GCP | us-central1 | `ckod-api-gcp-staging-us-central1` |
| production | Live traffic | AWS | us-west-1 | `ckod-api-production-us-west-1` |
| production | Live traffic | AWS | us-west-2 | `ckod-api-production-us-west-2` |
| production | Live traffic (EMEA) | AWS | eu-west-1 | `ckod-api-production-eu-west-1` |
| production | Live traffic | GCP | us-central1 | `ckod-api-gcp-production-us-central1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push to main branch

### Pipeline Stages

1. **Build and test**: Runs `mvn clean verify` inside the `.ci/docker-compose.yml` environment
2. **Docker build and push**: Builds and pushes image to `docker-conveyor.groupondev.com/pre/ckod-backend-jtier`
3. **Deploy to staging**: Automatically deploys to `staging-us-west-2` and `staging-us-central1` via Deploybot
4. **Promote to production**: Engineer clicks "Promote" in Deploybot UI after verifying staging deployment; promotes to the corresponding production target (e.g., `staging-us-central1` promotes to `production-us-central1`)

### Deployment Procedure (Manual)

1. Navigate to `https://deploybot.groupondev.com/PRE/ckod-backend-jtier`
2. Trigger the most recent deployment matching the Jenkins build timestamp
3. Authorize the deployment
4. Verify success in Deploybot logs
5. For production: click "Promote" from the staging deployment screen

## Scaling

| Component | Dimension | Strategy | Config |
|-----------|-----------|----------|--------|
| app | Horizontal | HPA | min: 2, max: 15, target CPU: 50% (production baseline) |
| worker | Horizontal | HPA | min: 1, max: 1 (single worker instance) |
| app (non-prod) | Horizontal | HPA | min: 1, max: 2 |

## Resource Requirements

### App component (production baseline from `common.yml`)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | Not set (from parent) |
| Memory | 500Mi | 500Mi |
| Disk | Not specified | Not specified |

### Worker component (production baseline from `common.yml`)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | Not set (from parent) |
| Memory | 500Mi | 500Mi |
| Disk | Not specified | Not specified |

## Ports

| Port | Purpose |
|------|---------|
| 8080 | HTTP API (app component) |
| 8081 | Dropwizard admin (health, metrics) |
| 8009 | JMX (both components) |
