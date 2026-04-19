---
service: "checkout-flow-analyzer"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "unknown"
environments: [local, development]
---

# Deployment

## Overview

> Deployment configuration managed externally. No Dockerfile, Kubernetes manifests, CI/CD pipeline configuration, or cloud infrastructure files were found in the repository. The repository contains only application source code and pre-loaded data files. Based on the `package.json` scripts (`next dev`, `next build`, `next start`), the application is a standard Next.js deployable.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None detected | No Dockerfile found in repository |
| Orchestration | None detected | No Kubernetes, ECS, or Lambda manifests found |
| Load balancer | None detected | No configuration found |
| CDN | None detected | No configuration found |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Local development | Developer workstation — `next dev` or `next dev --turbopack` | Local | `http://localhost:3000` (Next.js default) |

> Additional environment details (staging, production URLs, regions) are not discoverable from the repository. This may be an internal tooling application deployed manually or via scripts not committed to this repo.

## CI/CD Pipeline

> No evidence found in codebase. No `.github/workflows/`, `Jenkinsfile`, `.circleci/`, or similar CI/CD configuration files exist in the repository.

### Pipeline Stages

> No evidence found in codebase.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Not configured | No evidence found |
| Memory | Not configured | No evidence found |
| CPU | Not configured | No evidence found |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not specified | Not specified |
| Memory | Not specified | Not specified |
| Disk | Requires storage for CSV/ZIP data files in `src/assets/data-files/` | Not specified |

## Local Development

To run the application locally:

```bash
# Install dependencies
pnpm install

# Start development server
pnpm dev
# or with Turbopack
pnpm dev:turbo

# Build for production
pnpm build

# Start production server
pnpm start
```

Required environment variables for local development (see [Configuration](configuration.md)):
- `NEXT_PUBLIC_AUTH_DEV_MODE=true` (bypasses Okta)
- `NEXTAUTH_SECRET` (any random string for local use)
- `NEXTAUTH_URL=http://localhost:3000`

Log data files must be placed in `src/assets/data-files/` following the naming convention:
`{pwa|orders|proxy|lazlo|bcookie_summary}(_logs)?_us_YYYYMMDD_HHMMSS_YYYYMMDD_HHMMSS.csv[.zip]`
