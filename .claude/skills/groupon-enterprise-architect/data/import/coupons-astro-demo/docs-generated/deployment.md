---
service: "coupons-astro-demo"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging]
---

# Deployment

## Overview

`coupons-astro-demo` is containerized with Docker and deployed to Google Cloud Platform Kubernetes via Groupon's Conveyor Cloud / Deploybot platform. The CI pipeline builds a Docker image on every commit to `main`, publishes it to Groupon's internal Docker registry, and automatically deploys to the `staging-us-central1` Kubernetes cluster. The service runs as a standalone Node.js HTTP server (Astro's Node adapter in standalone mode) and is served through the Kubernetes service on port 8080.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` — multi-stage build: `docker-conveyor.groupondev.com/mobile-next/next-pwa-release-base-node22:2025.04.21-10.43.08-b5405678c4` builder + `node:22-alpine` runtime |
| Orchestration | Kubernetes (GKE) | Deployed via `krane` using Helm chart `cmf-generic-api` v3.72.1; manifest applied through `.meta/deployment/cloud/scripts/deploy.sh` |
| Image registry | Groupon internal Docker registry | `docker-conveyor.groupondev.com/coupons/coupons-astro` |
| Load balancer | Kubernetes Service (HTTP) | Container port `4321` mapped to service port `8080`; admin port `8081` also exposed |
| CDN | Not configured | No evidence found in codebase |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation | GCP us-central1 (VPC: `stable`) | Not documented in codebase |

> No production environment configuration is present in the repository at time of generation.

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (repository root)
- **Trigger**: Push/merge to `main` branch

### Pipeline Stages

1. **Docker Build**: Builds the multi-stage Docker image using pnpm for dependency installation and `pnpm run build` to compile the Astro SSR bundle into `./dist/`
2. **Image Publish**: Pushes the tagged image to `docker-conveyor.groupondev.com/coupons/coupons-astro`
3. **Deploy to staging-us-central1**: Runs `.meta/deployment/cloud/scripts/deploy.sh staging-us-central1 staging coupons-astro-staging`, which templates the Helm chart and applies it to the `coupons-astro-staging` Kubernetes namespace via `krane deploy` with a 300-second timeout

The Jenkins pipeline uses the `java-pipeline-dsl@latest-2` shared library with `dockerBuildPipeline`. Slack notifications are sent to the `#coupons` channel on start, completion, and override events. The `main` branch is the only `releasableBranch`.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Kubernetes Horizontal Pod Autoscaler) | Common: min 2, max 15, target utilization 50%; Staging override: min 1, max 2 |
| Memory | Not specified in available config | No explicit request/limit in available YAML |
| CPU | Not specified in available config | No explicit request/limit in available YAML |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not specified in available helm values | Not specified |
| Memory | Not specified in available helm values | Not specified |
| Disk | Ephemeral only (no persistent volumes) | Not specified |

> CPU and memory resource requests/limits can be added to the per-environment helm values files under the `cpus` and `memory` keys (see commented-out blocks in `staging-us-central1.yml`).

## Docker Build Details

The Dockerfile uses a two-stage build:
1. **Builder stage**: Uses Groupon's `next-pwa-release-base-node22` base image, enables `corepack`, installs `pnpm@10.12.1`, installs dependencies with `--frozen-lockfile`, prunes to production dependencies, then runs `pnpm run build` to generate `./dist/`
2. **Runtime stage**: Uses `node:22-alpine`, copies `dist/`, `node_modules/`, and `package.json` from the builder. The application is started with `node dist/server/entry.mjs`. The container exposes port `4321`.
