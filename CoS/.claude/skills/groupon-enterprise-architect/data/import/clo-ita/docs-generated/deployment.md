---
service: "clo-ita"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

`clo-ita` is deployed as a containerized Node.js 18 service following the standard Continuum itier-server deployment model. It is stateless, which allows horizontal scaling without coordination. Deployment configuration is managed externally to this architecture repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard itier-server Node.js 18 container image |
| Orchestration | Kubernetes (assumed Continuum standard) | Manifests managed externally |
| Load balancer | Managed externally | Fronts the Express HTTP server |
| CDN | Managed externally | Static asset delivery for Preact/Webpack bundles |

> Deployment configuration managed externally. Confirm Dockerfile path and Kubernetes manifests in the service repository.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local and CI development | — | — |
| staging | Pre-production validation | — | — |
| production | Live traffic | — | — |

> Specific environment URLs and regions are managed externally and not documented in the architecture inventory.

## CI/CD Pipeline

- **Tool**: GitHub Actions (Continuum standard)
- **Config**: Managed in the service repository
- **Trigger**: On push to main / pull request

### Pipeline Stages

1. Install: Install npm dependencies
2. Build: Run Webpack 4 to produce Preact UI bundles
3. Test: Execute unit and integration tests
4. Containerize: Build Docker image with Node.js 18 runtime
5. Deploy: Push to target environment via Continuum deployment tooling

> Exact pipeline configuration is managed in the service repository, not in this architecture inventory.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Auto-scaling (Continuum/Kubernetes standard) | Min/max managed externally |
| Memory | Managed externally | — |
| CPU | Managed externally | — |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Managed externally | Managed externally |
| Memory | Managed externally | Managed externally |
| Disk | Stateless — minimal ephemeral disk | — |

> Deployment configuration managed externally. Resource requests and limits are defined in the service Kubernetes manifests.
