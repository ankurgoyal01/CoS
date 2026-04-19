---
service: "gcp-aiaas-cloud-functions"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "gcp-cloud-run / gcp-cloud-functions"
environments: [staging, production]
---

# Deployment

## Overview

The AIaaS platform uses a mixed deployment model. Six workloads are deployed as GCP Cloud Functions (gen2) using the `functions-framework` HTTP trigger model. Two workloads — InferPDS Cloud Run API and MAD InferPDS Cloud Run API — are containerized with Docker and deployed to GCP Cloud Run. Both deployment models run Python 3.11 on GCP infrastructure. Build images for Cloud Run use the official Microsoft Playwright Python base image (`mcr.microsoft.com/playwright/python:v1.40.0-jammy`) to include Chromium browser dependencies.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (Cloud Run) | Docker | `inferpds_cloud_run_api/Dockerfile`, `mad_inferpds_cloud_run_api/Dockerfile` |
| Cloud Functions runtime | GCP Cloud Functions gen2 (functions-framework 3.x) | `aidg`, `deal_score`, `google_scraper`, `infer_pds_v3`, `pds_priority`, `social_link_scraper` |
| Cloud Run orchestration | GCP Cloud Run | InferPDS API and MAD InferPDS API |
| Playwright base image | `mcr.microsoft.com/playwright/python:v1.40.0-jammy` | Cloud Run containers require Chromium for browser-based scraping |
| Build scripts | Shell scripts | `inferpds_cloud_run_api/build_image.sh`, `mad_inferpds_cloud_run_api/build_image.sh` |
| Load balancer | GCP (built-in) | Cloud Run and Cloud Functions both use GCP-managed ingress |
| CDN | None | No evidence found in codebase |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Development and testing; uses `aidg_stg` PostgreSQL database and `groupon-dev.my.salesforce.com` Salesforce instance | us-central1 (inferred from Vertex AI config) | Not documented in codebase |
| Production | Live merchant intelligence workloads; BigQuery project `prj-grp-aiaas-prod-0052` | us-central1 (inferred from Vertex AI config) | Not documented in codebase |

## CI/CD Pipeline

- **Tool**: No CI/CD pipeline configuration files found in the repository
- **Config**: `inferpds_cloud_run_api/build_image.sh` and `mad_inferpds_cloud_run_api/build_image.sh` provide manual Docker build scripts
- **Trigger**: Manual deployment via build scripts and GCP CLI

### Pipeline Stages

> No CI/CD pipeline configuration found in codebase. Deployment configuration managed externally. The following stages are inferred from the build scripts and Dockerfile structure:

1. **Build**: `docker build` using Playwright Python base image; installs Python dependencies via `pip install -r requirements.txt`
2. **Playwright install**: `playwright install chromium` installs Chromium browser in the container
3. **Copy artifacts**: Reference CSV taxonomy files and application code copied into the image
4. **Push**: Docker image pushed to GCP Container Registry or Artifact Registry
5. **Deploy**: `gcloud run deploy` or `gcloud functions deploy` commands (managed externally)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | GCP Cloud Run automatic scaling; Cloud Functions automatic scaling | Cloud Run: min/max instances configured at deploy time (not in codebase) |
| Concurrency | Cloud Run: 1 uvicorn worker per container instance | `workers=1` in `main.py` uvicorn configuration |
| Memory | Configured at GCP platform level during deployment | Not specified in codebase |
| CPU | Configured at GCP platform level during deployment | Not specified in codebase |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not specified in codebase | Not specified in codebase |
| Memory | Not specified in codebase | Not specified in codebase |
| Disk | Not specified in codebase | Not specified in codebase |

> Deployment configuration (memory, CPU, timeout, concurrency) is managed externally via GCP Console or deployment scripts not present in this repository.

## Container Security

Both Cloud Run Dockerfiles create a non-root `app` user and set file ownership before switching to that user:
```
RUN useradd --create-home --shell /bin/bash app && chown -R app:app /app
USER app
```

Health checks are configured in the Dockerfile at 30-second intervals, 10-second timeout, 60-second start period:
```
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8080}/health || exit 1
```
