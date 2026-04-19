---
service: "AIGO-ContentServices"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, production-us-central1]
---

# Deployment

## Overview

AIGO-ContentServices is a monorepo of four independently deployable Docker containers orchestrated on Kubernetes via Groupon's Raptor deploy platform on GCP. Each component (frontend, generator, scraper, promptdb) has its own `Dockerfile`, deployment manifest under `.meta/deployment/cloud/components/<component>/`, and is built and pushed as a separate Docker image. Jenkins CI builds all four images on merge to `main` and triggers deployment to `staging-us-central1` automatically; production deployment requires promotion.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (frontend) | Docker | `frontend-content-generator/Dockerfile`; image: `docker-conveyor.groupondev.com/aigo/aigo-contentservices-frontend-content-generator` |
| Container (generator) | Docker | `service_content_generator/Dockerfile` (python:3.12-slim); image: `docker-conveyor.groupondev.com/aigo/aigo-contentservices-service_content_generator` |
| Container (scraper) | Docker | `service_web_scraper/Dockerfile`; image: `docker-conveyor.groupondev.com/aigo/aigo-contentservices-service_web_scraper` |
| Container (promptdb) | Docker | `service_prompt_database/Dockerfile`; image: `docker-conveyor.groupondev.com/aigo/aigo-contentservices-service_prompt_database` |
| Orchestration | Kubernetes (GCP) | Raptor deployment platform; manifests at `.meta/deployment/cloud/components/` |
| Load balancer / Ingress | Raptor hybridBoundary | Frontend is `isDefaultDomain: true`; backend services use internal cluster DNS |
| Database | PostgreSQL (Docker-compose for local; GCP-hosted for cloud) | Prompt Database Service connects via `POSTGRES_*` env vars |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Local dev | Development and testing | localhost | `http://localhost:3000` (frontend), `http://localhost:5000` (generator), `http://localhost:8000` (scraper), `http://localhost:5432` (postgres) |
| Staging | Pre-production validation | GCP us-central1 | `https://aigo-contentservices.staging.service.us-central1.gcp.groupondev.com/` (frontend) |
| Production | Live editorial tooling | GCP us-central1 | `https://aigo-contentservices.production.service.us-central1.gcp.groupondev.com/` (frontend) |

**Internal service URLs (staging)**:
- Generator: `https://aigo-contentservices--generator.staging.service.us-central1.gcp.groupondev.com`
- Scraper: `https://aigo-contentservices--scraper.staging.service.us-central1.gcp.groupondev.com`
- Prompt DB: `https://aigo-contentservices--promptdb.staging.service.us-central1.gcp.groupondev.com`

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (repo root)
- **Trigger**: Push to `main`, `master`, or `release` branch; manual dispatch
- **Deploy target**: `staging-us-central1` (automatic on merge); production requires separate promotion

### Pipeline Stages

1. **Prepare**: Resolves git SHA, patch version (`YYYY.MM.DD-HH.MM-<shortSHA>`), and determines if build should be published
2. **Test**: Runs per-service `docker-compose` test suites (currently disabled: `runTests = false`)
3. **Snapshot**: Builds and pushes snapshot Docker images on snapshot tags
4. **Release**: Builds Docker images for all four services with OCI labels; pushes to `docker-conveyor.groupondev.com`; tags as `latest` and patch version
5. **Security Scan**: Containerscan security scan per image (via `securityScan` step)
6. **Deploy**: Calls `deploybotDeploy` with patch version and target environment (`staging-us-central1`)

**Docker image naming**: `docker-conveyor.groupondev.com/<job-name>-<service-name>:<longSHA>` (snapshot) and `docker-conveyor.groupondev.com/<job-name>-<service-name>:<patch>` (release)

## Scaling

| Component | Dimension | Strategy | Staging | Production |
|-----------|-----------|----------|---------|------------|
| frontend | Horizontal | HPA | min 1 / max 2 | min 1 / max 2 |
| generator | Horizontal | HPA | min 1 / max 2 | min 1 / max 2 |
| scraper | Horizontal | HPA | min 1 / max 2 | min 1 / max 2 |
| promptdb | Horizontal | HPA | min 1 / max 2 | min 1 / max 2 |

`hpaTargetUtilization: 50` for all components (defined in `common.yml`).

## Resource Requirements

> Deployment configuration managed externally by Raptor platform defaults. No explicit CPU/memory request or limit overrides are set in the component manifests.

## Port Mapping

| Component | Container Port | Probe Port |
|-----------|---------------|------------|
| frontend | 3000 (HTTP) | 3000 |
| generator | 5000 (HTTP) | 5000 |
| scraper | 8000 (HTTP) | 8000 |
| promptdb | 7000 (HTTP) | 7000 |
