---
service: "wolf-hound"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Wolfhound Editor UI is packaged as a Docker container and deployed on Kubernetes. The Node.js/Express process serves both the static frontend assets and the BFF API from a single container. Deployment configuration is managed via Helm charts with per-environment values files.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repository root |
| Orchestration | Kubernetes | Helm chart manifests |
| Load balancer | Kubernetes Ingress / internal LB | Routes external editor traffic to the service |
| CDN | None evidenced | Static assets served directly from Express |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local developer iteration | Local | `http://localhost:3000` (default) |
| Staging | Integration and QA testing | — | Internal staging URL |
| Production | Live editorial tooling | — | Internal production URL |

> Specific regional and URL details are managed in deployment manifests and are not captured in the architecture model.

## CI/CD Pipeline

- **Tool**: No evidence found — assumed GitHub Actions or Jenkins based on Groupon standards
- **Config**: Deployment configuration managed externally
- **Trigger**: On push to main / manual dispatch

### Pipeline Stages

1. **Install**: Install npm dependencies (`npm install`)
2. **Lint / Test**: Run linting and unit tests
3. **Build**: Bundle frontend assets (Vue.js workboard)
4. **Docker Build**: Build and tag the Docker image
5. **Push**: Push image to container registry
6. **Deploy**: Apply Helm chart to target Kubernetes cluster

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Deployment configuration managed externally |
| Memory | Kubernetes resource limits | Deployment configuration managed externally |
| CPU | Kubernetes resource limits | Deployment configuration managed externally |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | — | — |
| Memory | — | — |
| Disk | — | — |

> Deployment configuration managed externally. Consult Helm values files in the deployment repository for specific resource requests and limits.
