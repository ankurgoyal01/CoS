---
service: "deal-alerts"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging-us-central1"]
---

# Deployment

## Overview

Deal Alerts is deployed as a containerized Next.js application using a multi-stage Docker build. The Jenkins pipeline builds a Docker image and deploys to Kubernetes in the staging-us-central1 environment. The n8n workflows run on a separate n8n instance (not managed in this repository).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Multi-stage build: `Dockerfile` (Alpine-based Node 22 image from `docker.groupondev.com/node:22-alpine`) |
| Orchestration | Kubernetes | Deployed via Jenkins `dockerBuildPipeline` to GKE |
| Base image | Node.js 22 Alpine | `docker.groupondev.com/node:22-alpine` with pnpm 9.0.0 and Turbo |
| Workflow engine | n8n | External n8n instance running workflow automations (not in this repo) |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-central1 | Staging deployment | us-central1 | Configured per deployment |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to repository (standard Jenkins pipeline)

### Pipeline Stages

1. **Prune**: Uses Turbo `prune` to create a minimal Docker context for the `web` app
2. **Install**: Installs dependencies with `pnpm install --frozen-lockfile --prefer-offline`
3. **Build**: Runs `pnpm dlx turbo build --filter=web` with `NODE_ENV=production` and `SKIP_ENV_VALIDATION=1`
4. **Package**: Copies standalone Next.js output, static assets to final Alpine runner image
5. **Deploy**: Pushes Docker image and deploys to `staging-us-central1` via `dockerBuildPipeline`

### Docker Build Details

The Dockerfile uses a 4-stage multi-stage build for minimal image size:
- **base**: Alpine Node 22 with pnpm and Turbo
- **pruner**: Turbo prune to isolate web app dependencies
- **installer/builder**: Install deps and build production bundle
- **runner**: Minimal runtime with non-root `nextjs:nodejs` user, exposes port 3000

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes-managed | Configured per deployment |
| Database connections | Connection pool | max: 10, idle timeout: 30s, connection timeout: 5s |

## Resource Requirements

> Resource requests and limits are configured in the Kubernetes deployment manifests managed externally. The Docker container runs the standalone Next.js server (`node apps/web/server.js`) on port 3000.
