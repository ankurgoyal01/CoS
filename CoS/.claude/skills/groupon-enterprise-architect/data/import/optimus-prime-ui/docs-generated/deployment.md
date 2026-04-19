---
service: "optimus-prime-ui"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

Optimus Prime UI is built as a two-stage Docker image and deployed to Kubernetes via Helm and Krane. The build stage (Node.js 18 Alpine + pnpm) compiles the Vue/Vite SPA into static assets. The production stage serves those assets via nginx (stable-alpine) on port 8080. The container is deployed to AWS (us-west-2) and GCP (us-central1) Kubernetes clusters across dev, staging, and production environments. Releases are triggered by creating a GitHub release tag and are deployed via Deploybot, which calls Cloud Jenkins to build and publish the Docker image.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (multi-stage) | `Dockerfile` — build stage: `node:18-alpine` + pnpm 9.12.1; production stage: `nginx:stable-alpine` |
| Orchestration | Kubernetes (Helm + Krane) | Helm chart `cmf-generic-api` version `3.91.2`; deploy script `.meta/deployment/cloud/scripts/deploy.sh` |
| Load balancer | nginx (in-container) | Listens on port 8080; proxies `/api/` and `/refresh-api/`; serves static assets from `/var/www/html` |
| CDN | Not configured | Static assets served directly from nginx with `Cache-Control: immutable` headers |

## Environments

| Environment | Purpose | Region | Cloud |
|-------------|---------|--------|-------|
| dev-us-west-2 | Developer testing and preview | us-west-2 | AWS (stable VPC) |
| staging-us-west-2 | Pre-production validation | us-west-2 | AWS (stable VPC) |
| staging-us-central1 | Pre-production validation (GCP) | us-central1 | GCP |
| production-us-west-2 | Live production traffic | us-west-2 | AWS (prod VPC) |
| production-us-central1 | Live production traffic (GCP) | us-central1 | GCP |

## CI/CD Pipeline

- **Tool**: Cloud Jenkins (GitHub release-triggered) + Deploybot
- **Config**: `Jenkinsfile` (build); `.deploy_bot.yml` (deployment targets)
- **Trigger**: Creation of a new GitHub release tag (semver, e.g., `1.2.0`) on the `master` branch

### Pipeline Stages

1. **Build image**: Cloud Jenkins builds the Docker image using `pnpm build` inside the `node:18-alpine` stage, injects `VITE_BUILD_REF`, `VITE_BUILD_DATE`, `VITE_RELEASE` build args
2. **Publish image**: Docker image pushed to `docker-conveyor.groupondev.com/dnd_tools/optimus_prime_ui` tagged with the release semver
3. **Deploy to dev**: Deploybot automatically deploys the new image to `dev-us-west-2` via `.meta/deployment/cloud/scripts/deploy.sh dev-us-west-2 dev optimus-prime-ui-dev` using Krane with a 300-second timeout
4. **Promote to staging**: Operator clicks `Promote` in Deploybot UI; deploys to `staging-us-west-2` and `staging-us-central1`
5. **Deploy to production**: Manual approval required (`manual: true`); operator clicks `Authorize` in Deploybot to promote to `production-us-west-2` and `production-us-central1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min 1 / Max 2 (common); Production: Min 2 / Max 3 |
| HPA Target | CPU utilization | 50% target utilization (common config) |
| Memory | Not explicitly configured | Uses Helm chart defaults |
| CPU | Not explicitly configured | Uses Helm chart defaults |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not explicitly set (Helm chart defaults) | Not explicitly set |
| Memory | Not explicitly set (Helm chart defaults) | Not explicitly set |
| Disk | Ephemeral only (static assets baked into image) | Not applicable |

> CPU and memory requests/limits are commented out in the deployment YAML files and fall back to the `cmf-generic-api` Helm chart defaults.

## Port Configuration

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | HTTP | Main application port (nginx serves SPA and proxies API) |
| 8081 | HTTP | Admin port (exposed in common deployment config) |
