---
service: "coupons-ui"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging-us-central1", "staging-europe-west1", "production-us-central1", "production-eu-west-1"]
---

# Deployment

## Overview

Coupons UI is containerized as a multi-stage Docker image and deployed to Kubernetes via the Raptor/Conveyor Cloud platform. The container runs nginx on port 8080 as the public-facing listener; nginx proxies SSR requests to the internal Astro Node.js server on port 3000 and serves static assets directly from the filesystem. Deployments are triggered through DeployBot after Jenkins CI completes on the `main` branch. Four environments are configured: two staging (US and EU) and two production (US and EU).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (multi-stage) | `Dockerfile` at repo root; builder stage on `node:22-alpine`, production stage installs prod deps and nginx |
| Orchestration | Kubernetes (GCP GKE + AWS EKS) | Manifests managed by Raptor via `.meta/deployment/cloud/` |
| Load balancer | nginx (in-container) | `nginx.conf`; listens port 8080, rewrites `/coupons/*` → `/coupons-ui/*`, proxies to `127.0.0.1:3000` |
| Static asset caching | nginx | `_astro/`, `assets/`, `styles/` paths served with `Cache-Control: public, immutable`, 1-year expiry |
| Container registry | `docker-conveyor.groupondev.com/coupons/coupons-ui` | Image tag references in Raptor deployment config |

## Environments

| Environment | Purpose | Cloud | Region | VIP |
|-------------|---------|-------|--------|-----|
| staging-us-central1 | Pre-production validation (North America) | GCP | us-central1 | `coupons-ui.staging.stable.us-central1.gcp.groupondev.com` |
| staging-europe-west1 | Pre-production validation (EMEA) | GCP | europe-west1 | `coupons-ui.staging.stable.europe-west1.gcp.groupondev.com` |
| production-us-central1 | Live traffic (North America) | GCP | us-central1 | `coupons-ui.prod.us-central1.gcp.groupondev.com` |
| production-eu-west-1 | Live traffic (EMEA) | AWS | eu-west-1 | `coupons-ui.prod.eu-west-1.aws.groupondev.com` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: Merge to `main` branch; also used for release branches
- **Deploy tool**: DeployBot at `https://deploybot.groupondev.com/Coupons/coupons-ui`

### Pipeline Stages

1. **Lint**: Runs ESLint over `.js`, `.mjs`, `.cjs`, `.ts`, `.tsx`, `.astro` files; output written to `test-output/eslint-report.json` for SonarQube
2. **Test & Coverage**: Runs Vitest with V8 coverage; coverage output written for SonarQube ingestion (`.ci/run-test-coverage.sh`)
3. **SonarQube Static Analysis**: Runs `sonar-scanner` inside `sonarsource/sonar-scanner-cli` Docker image with lint and coverage results
4. **Docker Build**: Multi-stage Docker build producing a minimal Alpine image with nginx and production Node.js deps
5. **Deploy to Staging**: DeployBot targets `staging-us-central1` and `staging-europe-west1` automatically after successful CI
6. **Promote to Production**: Staging deployments promote to `production-us-central1` (from staging-us-central1) and `production-eu-west-1` (from staging-europe-west1) via DeployBot promotion

## Scaling

| Environment | Min Replicas | Max Replicas | HPA Target CPU |
|-------------|-------------|-------------|----------------|
| staging-us-central1 | 1 | 6 | 50% (common.yml default) |
| staging-europe-west1 | 1 | 6 | 50% (common.yml default) |
| production-us-central1 | 4 | 20 | 50% |
| production-eu-west-1 | 4 | 20 | 50% |

Horizontal Pod Autoscaler (HPA) manages scaling. `hpaTargetUtilization: 50` is the default from `common.yml`. Replicas can be adjusted during incidents via `kubectl edit hpa`.

## Resource Requirements

| Resource | Staging Request | Staging Limit | Production |
|----------|----------------|--------------|------------|
| CPU | 1000m | not set | not explicitly configured |
| Memory | 500 Mi | 2000 Mi | not explicitly configured |

> Production resource requests/limits are not explicitly set in the committed deployment config files; defaults from the Raptor platform apply.

## Startup Sequence

The container entrypoint `docker-start.sh` runs at container start. It executes `scripts/normalize-astro-files.sh` to lowercase Astro-generated asset filenames (cross-platform compatibility), then starts nginx in the background and launches the Astro Node.js server (`node dist/server/entry.mjs`).
