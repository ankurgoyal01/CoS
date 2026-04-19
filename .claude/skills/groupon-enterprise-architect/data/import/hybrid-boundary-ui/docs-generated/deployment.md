---
service: "hybrid-boundary-ui"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Hybrid Boundary UI is a compiled Angular SPA served by Nginx inside a Docker container. The Angular CLI builds static assets (HTML, JS, CSS) which are placed into an Nginx image. The container is deployed to the Continuum platform Kubernetes environment. All deployment manifests are managed externally to this architecture repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (Nginx) | Angular build artifacts served by Nginx; `try_files` for SPA routing |
| Orchestration | Kubernetes (inferred from Continuum platform standard) | Deployment manifests managed externally |
| Load balancer | Internal (Continuum platform) | Routes browser traffic to `continuumHybridBoundaryUi` pods |
| CDN | None evidenced | Internal tool; not publicly exposed |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development | Local | `http://localhost:4200` (Angular dev server) |
| staging | Pre-production validation | US | Internal |
| production | Live operator traffic | US | Internal |

> Deployment configuration managed externally.

## CI/CD Pipeline

- **Tool**: GitHub Actions (Continuum platform standard)
- **Config**: Managed in the service source repository (not this architecture repo)
- **Trigger**: On push to main branch; manual dispatch for production deploys

### Pipeline Stages

1. Install: `npm install` — install Angular and dependency packages
2. Build: `ng build --configuration production` — compile Angular SPA for production
3. Containerize: Build Nginx Docker image with compiled assets
4. Push: Push image to container registry
5. Deploy: Apply Kubernetes manifests to target environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual or HPA (inferred from Kubernetes) | Confirm with service owners |
| Memory | Container resource limits | Confirm with service owners |
| CPU | Container resource limits (Nginx is lightweight) | Confirm with service owners |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | — | — |
| Memory | — | — |
| Disk | — | — |

> Deployment configuration managed externally. Resource requirements are defined in Kubernetes manifests outside this architecture repository.
