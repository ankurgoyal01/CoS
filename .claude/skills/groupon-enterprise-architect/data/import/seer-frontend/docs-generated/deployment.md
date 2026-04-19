---
service: "seer-frontend"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging-us-west-1", "staging-us-central1", "production-us-west-1", "production-us-central1"]
---

# Deployment

## Overview

Seer Frontend is containerized with Docker (multi-stage build) and deployed to Kubernetes clusters on both GCP and AWS via the Deploybot system. The CI pipeline is Jenkins (`Jenkinsfile`). On merge to `main`, Jenkins triggers a Docker image build and pushes to `docker-conveyor.groupondev.com`. Deploybot then promotes through staging targets before deploying to production. The Vite preview server (`npm run preview`) is used as the production HTTP server, listening on port 8080.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (multi-stage) | `Dockerfile` at repo root; Stage 1: builds static assets with `npm run build`; Stage 2: copies dist and source, runs `npm run preview` |
| Orchestration | Kubernetes | Helm chart `cmf-generic-api` v3.76.1 deployed via `krane`; manifests in `.meta/deployment/cloud/` |
| Load balancer | Kubernetes Service | HTTP port 8080 exposed via `httpPort: 8080` in `common.yml` |
| CDN | No evidence found in codebase | — |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-west-1 | Pre-production validation | AWS us-west-1 | Not documented in codebase |
| staging-us-central1 | Pre-production validation | GCP us-central1 | `http://seer-service.staging.service.us-central1.gcp.groupondev.com` (backend reference in vite.config.js) |
| production-us-west-1 | Production | AWS us-west-1 | Not documented in codebase |
| production-us-central1 | Production | GCP us-central1 | Not documented in codebase |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (uses shared library `java-pipeline-dsl@latest-2` — `dockerBuildPipeline`)
- **Trigger**: Push to `main` branch (releasable branch defined as `['main']`)

### Pipeline Stages

1. **Docker Build**: Builds multi-stage Docker image tagged with version; image name `seer-frontend` (non-snake-case: `snakeCaseImageName: false`)
2. **Push to Registry**: Pushes image to `docker-conveyor.groupondev.com/svuppalapati/seer-frontend`
3. **Deploy to Staging**: Deploybot deploys to `staging-us-west-1` and `staging-us-central1` simultaneously (defined in `deployTarget`)
4. **Promote to Production**: Deploybot promotes from staging targets to `production-us-west-1` and `production-us-central1` (via `promote_to` in `.deploy_bot.yml`)

### Deployment Command

Each target runs:
```
helm3 template cmf-generic-api \
  --repo http://artifactory.groupondev.com/artifactory/helm-generic/ \
  --version '3.76.1' \
  -f .meta/deployment/cloud/components/app/common.yml \
  -f .meta/deployment/cloud/components/app/<target>.yml \
  --set appVersion=<version> \
| krane deploy seer-frontend-<env> <kube-context> --global-timeout=300s
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Horizontal Pod Autoscaler) | Min replicas: 1, Max replicas: 2, Target CPU utilization: 50% (`hpaTargetUtilization: 50` in `common.yml`) |
| Memory | Not configured in deployment manifests | Resource requests/limits commented out in YAML |
| CPU | Not configured in deployment manifests | Resource requests/limits commented out in YAML |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not configured (commented out in `.meta/deployment/cloud/components/app/common.yml`) | Not configured |
| Memory | Not configured (commented out) | Not configured |
| Disk | Not applicable (stateless SPA) | — |
