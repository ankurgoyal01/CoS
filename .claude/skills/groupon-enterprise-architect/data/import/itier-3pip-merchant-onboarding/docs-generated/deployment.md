---
service: "itier-3pip-merchant-onboarding"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

The service is a stateless Node.js iTier application deployed as a container within the Continuum platform. It follows the standard Groupon Continuum deployment model — containerized via Docker, orchestrated on Kubernetes, and deployed across development, staging, and production environments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard iTier Dockerfile; Node.js 16 base image |
| Orchestration | Kubernetes | Standard Continuum k8s manifests |
| Load balancer | Akamai / internal LB | Traffic routed through Groupon's standard edge layer |
| CDN | Akamai | Static assets served via Groupon CDN |

> Deployment configuration managed externally. Specific Dockerfile paths and k8s manifest locations are maintained in the service repository, not the architecture model.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local and CI development | — | — |
| staging | Pre-production integration testing | — | — |
| production | Live merchant traffic | — | — |

## CI/CD Pipeline

- **Tool**: GitHub Actions (Groupon standard CI)
- **Config**: `.github/workflows/` in the service repository
- **Trigger**: on-push (feature branches), on-merge (main branch)

### Pipeline Stages

1. Install: Install npm dependencies
2. Lint / Test: Run unit and integration tests
3. Build: Webpack bundle compilation
4. Docker Build: Build and tag container image
5. Deploy: Push to container registry and roll out to target environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Managed externally per environment |
| Memory | Kubernetes resource limits | Managed externally per environment |
| CPU | Kubernetes resource limits | Managed externally per environment |

## Resource Requirements

> Deployment configuration managed externally. Resource requests and limits are defined in Kubernetes manifests in the service repository.
