---
service: "groupon-monorepo"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "encore-cloud, cloud-run, digitalocean"
environments: [local, staging, production]
---

# Deployment

## Overview

The Encore Platform uses a multi-target deployment model. The TypeScript and Go backends are deployed to Encore Cloud (GCP-backed managed infrastructure). React frontends are deployed to Google Cloud Run as containerized applications. Python AI microservices are deployed to DigitalOcean droplets via Docker. The platform supports preview environments for PRs and uses Encore namespaces for branch-level isolation during development.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| TS Backend Container | Encore Cloud (managed) | Automatic containerization by Encore platform |
| Go Backend Container | Encore Cloud (managed) | Automatic containerization by Encore platform |
| Frontend Container | Docker / Cloud Run | `apps/admin-react-fe/`, `apps/aidg-react-fe/` |
| Python Container | Docker / DigitalOcean | `apps/microservices-python/Dockerfile` |
| Load balancer | Encore Cloud (managed) | Automatic load balancing and TLS termination |
| CDN | Google Cloud CDN (via Cloud Run) | Frontend static assets |
| Databases | Encore Cloud (managed PostgreSQL) | Automatic provisioning per `SQLDatabase` declaration |
| Redis | Encore Cloud (managed) | Shared caching infrastructure |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Local | Development and testing | Local machine | `http://localhost:4000` (backend), `http://localhost:3000` (frontend) |
| Staging | Pre-production testing | GCP (us-central1, europe-west1) | `https://staging-<app>.encr.app` |
| Production | Live platform | GCP (us-central1, europe-west1) | `https://<app>.encr.app` |
| Preview (PR) | Per-PR preview environments | GCP | Auto-generated URLs per PR |

## CI/CD Pipeline

- **Tool**: GitHub Actions + Encore Cloud
- **Config**: `.github/workflows/` (29 workflow files)
- **Trigger**: on-push (staging/production branches), on-PR (checks), manual dispatch

### Pipeline Stages

1. **Code Quality Check** (`code-quality-check.yml`): Biome linting, formatting, type checking on PR
2. **PR Title Check** (`pr-title-check.yml`): Enforces `[XXX-YY] Description` commit format
3. **Database Change Detection** (`database-change-detector.yml`): Detects and flags migration changes in PRs
4. **API Tests** (`api-tests.yml`): Encore test suite execution
5. **E2E Tests** (`e2e-tests.yml`): End-to-end integration tests
6. **OpenAPI Update** (`pr-openapi-update.yml`): Auto-regenerates OpenAPI specs on backend changes
7. **Frontend Preview Deploy** (`prr-admin-react-fe-deploy.yml`, `prr-aidg-react-fe-deploy.yml`): Deploys frontend preview to Cloud Run for MAD-prefixed PRs
8. **Python Services Deploy** (`prr-python-services-deploy.yml`): Deploys Python services preview
9. **Encore Backend Deploy**: Automatic deployment by Encore Cloud on merge to staging/production branches
10. **Release** (`release.yml`): Release tagging and changelog
11. **Staging to Production PR** (`auto-stg-to-prd-pr.yml`): Auto-creates PR from staging to production
12. **Frontend Cloud Run Deploy** (`deploy-frontends-cloudrun.yml`): Production frontend deployment
13. **Python Production Deploy** (`python-services-do-droplet-deploy-prod.yml`): Python services production deployment
14. **Preview Cleanup** (`prr-admin-react-fe-cleanup.yml`, `prr-aidg-react-fe-cleanup.yml`, `prr-pr-preview-ttl-cleanup.yml`): Cleans up preview environments after PR merge
15. **Distributed Client Publish** (`publish-distributed-clients.yml`): Publishes shared client packages

### Branch Strategy

- `staging`: Main development branch (default). Merges trigger staging deployment.
- `production`: Production branch. Merges trigger production deployment.
- Feature branches: `Tribe/Initiative/Ticket-description` format (auto-generated via `pnpm branch`).
- Preview branches: PRs with `MAD` prefix get preview environments.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Encore Cloud auto-scaling (managed) | Platform-managed based on request volume |
| Memory | Encore Cloud managed | Platform default limits |
| CPU | Encore Cloud managed | Platform default limits |
| Frontend | Cloud Run auto-scaling | Container instances scale 0-N based on traffic |
| Python | DigitalOcean droplet (manual) | Fixed droplet size per environment |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Encore-managed | Encore-managed |
| Memory | Encore-managed | Encore-managed |
| Disk | Encore-managed (databases) | Encore-managed |
| Frontend (Cloud Run) | 1 vCPU / 512 MB | 2 vCPU / 1 GB |
| Python (DigitalOcean) | Droplet-specific | Droplet-specific |

> Exact resource limits for Encore Cloud services are managed by the platform and not directly configurable. Cloud Run and DigitalOcean resources are configured in their respective deployment workflows.
