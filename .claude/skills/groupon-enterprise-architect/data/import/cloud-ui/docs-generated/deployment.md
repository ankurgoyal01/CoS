---
service: "cloud-ui"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

Cloud UI is packaged as a Docker container using a three-stage multi-stage build (deps, builder, runtime) based on `node:22-slim`. The built Next.js application is run in standalone output mode for minimal runtime footprint. The container is orchestrated on GCP GKE using Helm charts managed through the Groupon `dockerBuildPipeline` Jenkins shared library. Deployment targets are defined in `.meta/deployment/cloud/` using Raptor-compatible Helm value files.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (multi-stage, `node:22-slim`) | `Dockerfile` at repo root; three stages: `deps`, `builder`, `runtime`; runs as non-root user `nextjs` (UID 1001); uses `tini` as PID 1 |
| Orchestration | Kubernetes (GKE) | Deployed via Helm chart managed through `dockerBuildPipeline`; namespace derived from `serviceId` and `deployEnv` |
| Image registry | Artifactory (`docker-conveyor.groupondev.com`) | Image: `docker-conveyor.groupondev.com/conveyor-cloud/cloud-ui` |
| Process supervisor | `tini` | Installed in runtime stage; used as `ENTRYPOINT ["tini", "--"]` to handle signal forwarding and zombie reaping |
| Load balancer | GCP (via Helm `cmf-generic-api` chart) | HTTP on port 3000; HBU/ingress configuration settable per component via `hybridBoundary` config |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production; connected to Encore preview backend | `us-central1` (GCP) | Not published in repo |
| Production | Live platform management UI | `us-central1` (GCP) | Not published in repo |

## CI/CD Pipeline

- **Tool**: Jenkins (primary) + GitHub Actions (tests only)
- **Jenkins config**: `Jenkinsfile` at repo root — uses `dockerBuildPipeline` shared library (`java-pipeline-dsl@latest-2`)
- **GitHub Actions config**: `.github/workflows/ci-tests.yml`
- **Trigger**: Push to `main` branch or pull request (GitHub Actions); Jenkins pipeline manages Docker build and deployment

### Pipeline Stages

**GitHub Actions (`ci-tests.yml`):**
1. Checkout: Fetch source code
2. Node.js setup: Install Node.js 22.x with npm cache
3. Install dependencies: `npm ci`
4. Run tests: `npm run test:ci`
5. Build application: `npm run build`

**Jenkins (`Jenkinsfile` via `dockerBuildPipeline`):**
1. Docker build: Multi-stage build producing `node:22-slim`-based image
2. Image push: Tag and push to `docker-conveyor.groupondev.com/conveyor-cloud/cloud-ui`
3. Deploy: Helm deploy to `staging-us-central1` target

### Docker Build Details

| Stage | Base | Purpose |
|-------|------|---------|
| `deps` | `node:22-slim` | Install all npm dependencies with `npm ci` |
| `builder` | `node:22-slim` | Copy deps, copy source, run `npm run build`, prune to production deps |
| `runtime` | `node:22-slim` | Copy Next.js standalone output, static assets; install `tini`; set non-root user |

**Startup**: `CMD ["./start.sh"]` — a shell script that handles environment variable injection at runtime before starting Next.js (required to apply `API_URL` to the standalone build without rebuild).

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed replica count (via common Helm values) | `minReplicas: 2`, `maxReplicas: 2` (`.meta/deployment/cloud/components/app/common.yml`) |
| Memory | Configurable via Helm values override | Not explicitly set in discovered configs; uses chart defaults |
| CPU | Configurable via Helm values override | Not explicitly set in discovered configs; uses chart defaults |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not explicitly configured (chart defaults apply) | Not explicitly configured |
| Memory | Not explicitly configured (chart defaults apply) | Not explicitly configured |
| Disk | Ephemeral only (Helm chart cache in `/tmp`) | Not applicable |

> Resource overrides can be set in environment-specific Helm values files under `.meta/deployment/cloud/components/app/`.
