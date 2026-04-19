---
service: "bookability-dashboard"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "google-cloud-storage"
environments: [development, staging-us-central1, staging-europe-west1, production-us-central1, production-europe-west1]
---

# Deployment

## Overview

The Bookability Dashboard is deployed as a static React SPA to Google Cloud Storage (GCS) buckets, served via Google Cloud CDN and GCP HTTPS load balancers. There are no containers or server-side processes. The Jenkins CI/CD pipeline builds the application, zips the artifact, uploads it to a shared build bucket, and then uses `deploybot` (Groupon's internal deploy orchestrator) to distribute the artifact to regional staging environments and trigger CDN cache invalidation. Production deployments are triggered separately through `deploybot`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Static hosting | Google Cloud Storage | Per-environment, per-region GCS buckets |
| CDN | Google Cloud CDN | URL-map-backed CDN for each environment |
| Load balancer | GCP HTTPS Load Balancer | Routes traffic to GCS backend buckets via URL maps |
| Build image | Docker (`docker-conveyor.groupondev.com/merchant-experience/bun_gcloud:v1.0.0`) | Used in Jenkins pipeline for install/lint/build steps |
| Build artifact store | GCS (`gs://bookability-web-builds/book-dash/`) | Stores versioned zip archives (`book-dash-{version}-{sha}.zip`) |

## Environments

| Environment | Purpose | Region | GCS Bucket | GCP Project |
|-------------|---------|--------|------------|-------------|
| Staging | Pre-production validation | us-central1 | `gs://bookability-dashboard-web-stable-us-central1/` | `prj-grp-book-dash-stable-2265` |
| Staging | Pre-production validation | europe-west1 | `gs://bookability-dashboard-web-stable-europe-west1/` | `prj-grp-book-dash-stable-2265` |
| Production | Live serving to internal users | us-central1 | `gs://bookability-dashboard-web-prod-us-central1/` | `prj-grp-book-dash-prod-a776` |
| Production | Live serving to internal users | europe-west1 | `gs://bookability-dashboard-web-prod-europe-west1/` | `prj-grp-book-dash-prod-a776` |
| Dev (build) | Artifact storage only | — | `gs://bookability-web-builds/book-dash/` | `prj-grp-book-dash-dev-583c` |

**URLs:**

- Staging: `https://staging.groupon.com/bookability/dashboard/`
- Production: `https://www.groupon.com/bookability/dashboard/`

**URL Maps (CDN):**

- Staging: `bookability-dashboard-web-stable-urlmap`
- Production: `bookability-dashboard-web-prod-urlmap`

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (repository root)
- **Docker image**: `docker-conveyor.groupondev.com/merchant-experience/bun_gcloud:v1.0.0`
- **Trigger**: Push to `main` branch (only `main` is a releasable branch)
- **Automatic deploy targets**: `staging-us-central1`, `staging-europe-west1`

### Pipeline Stages

1. **Prepare**: Reads `package.json`, computes version string as `{package.version}-{git-short-sha}`, determines if this is a releasable push (not a PR, on `main` branch)
2. **Install**: Runs `bun install` inside the build Docker container
3. **Lint**: Runs `bun run lint` (ESLint with TypeScript and React plugins)
4. **Build**: Runs `bun run build` (TypeScript compile + Vite production bundle), then zips `dist/` into `{project}-{version}.zip`
5. **Release** (only if releasable): Authenticates with GCP service account, uploads zip to `gs://bookability-web-builds/book-dash/`
6. **Deploy** (only if releasable): Calls `deploybotDeploy` with `version`, `targetEnv: [staging-us-central1, staging-europe-west1]`, and git metadata

### Deploy Script (`deploy.sh`)

The `deploybot` orchestrator calls `.meta/deployment/cloud/scripts/deploy.sh` with the target environment name. The script:

1. Authenticates with GCP using the dev service account key
2. Downloads the build artifact zip from `gs://bookability-web-builds/book-dash/`
3. Unzips the artifact into a `tmp/` directory
4. Copies the environment-specific `{env}.js` file to `tmp/env-config.js`
5. Removes all files from the target GCS bucket (clear old version)
6. Copies all files from `tmp/` to the target GCS bucket
7. Runs CDN cache invalidation on the corresponding URL map (`--path "/*" --async`)
8. Cleans up `tmp/`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Google Cloud CDN global edge caching | Automatic — CDN scales to demand |
| Memory | Not applicable (static hosting) | — |
| CPU | Not applicable (static hosting) | — |

## Resource Requirements

> Not applicable — this service uses GCS static hosting, not compute instances. There are no CPU/memory resource constraints to configure.

## Rollback

To roll back to a previous version:

1. List available builds: `gcloud storage ls gs://bookability-web-builds/book-dash/`
2. Identify the target `{git-sha}` to roll back to
3. Run the deploy script manually pointing `REVISION` to the desired sha and `TARGET_ENV` to the affected environment
4. Invalidate CDN cache for the affected URL map

See the Operations & Deployment owner-manual (`docs/owner-manual/3-Operations-Deployment.md`) for detailed rollback commands.
