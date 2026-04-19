---
service: "merchant-center-web"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: false
orchestration: "gcs-static"
environments: [development, staging, production]
---

# Deployment

## Overview

Merchant Center Web is deployed as a set of static files — HTML, JS, CSS, and assets — built by Vite and uploaded to a GCP Cloud Storage (GCS) bucket. There is no server-side runtime container or orchestration system. Files are served globally via Akamai CDN, which caches and distributes the static bundle to merchants worldwide. CI/CD is managed via GitHub Actions.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None (static files) | SPA built to `dist/` by Vite; no Docker container |
| Orchestration | GCP Cloud Storage | Static file hosting; bucket serves as origin for CDN |
| Load balancer | Akamai CDN | Distributes static assets globally; handles SSL termination |
| CDN | Akamai | Caches and serves `merchantCenterWebSPA` static bundle |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local dev with Vite HMR dev server | Local | http://localhost:5173 (default Vite port) |
| staging | Pre-production validation | GCP (Groupon region) | Internal staging URL |
| production | Live merchant-facing portal | GCP + Akamai (global) | merchant.groupon.com (or equivalent) |

## CI/CD Pipeline

- **Tool**: GitHub Actions
- **Config**: `.github/workflows/` (within merchant-center-web repository)
- **Trigger**: On push to main branch; on pull request (test/lint only); manual dispatch

### Pipeline Stages

1. **Install**: Installs dependencies using Bun package manager.
2. **Lint**: Runs TypeScript type-checking and ESLint code quality checks.
3. **Test**: Executes Vitest unit/integration tests.
4. **Build**: Runs `vite build` to produce optimized static assets in `dist/`.
5. **E2E Test**: Optionally runs Playwright end-to-end tests against the built bundle.
6. **Upload to GCS**: Uploads `dist/` contents to the target GCS bucket for the deployment environment.
7. **Akamai Cache Purge**: Sends cache invalidation request to Akamai to surface the new deployment immediately.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Automatic — CDN edge nodes scale globally | Managed by Akamai |
| Memory | Not applicable — static hosting | N/A |
| CPU | Not applicable — static hosting | N/A |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not applicable | Not applicable |
| Memory | Not applicable | Not applicable |
| Disk | GCS bucket storage (static files) | Managed by GCS bucket policy |

> Deployment configuration is managed by the merchant-center-web CI/CD pipeline and GCP project settings. Specific bucket names, CDN configuration IDs, and workflow file paths should be confirmed in the service repository.
