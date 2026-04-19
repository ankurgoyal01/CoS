---
service: "backbeat"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Backbeat deploys two distinct runtime processes — the API Runtime (`continuumBackbeatApiRuntime`) as a Rack web server and the Worker Runtime (`continuumBackbeatWorkerRuntime`) as a Sidekiq process — alongside their dedicated PostgreSQL and Redis datastores. Both runtimes are containerized. Deployment configuration is managed externally to this architecture repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Separate images for API and Worker runtimes |
| Orchestration | Kubernetes (inferred from Continuum platform standard) | Deployment manifests managed externally |
| Load balancer | Internal (Continuum platform) | Routes traffic to `continuumBackbeatApiRuntime` |
| CDN | None | Internal service — not publicly exposed |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and integration testing | Local | — |
| staging | Pre-production validation | US | Internal |
| production | Live traffic | US | Internal |

> Deployment configuration managed externally.

## CI/CD Pipeline

- **Tool**: GitHub Actions (Continuum platform standard)
- **Config**: Managed in the service source repository (not this architecture repo)
- **Trigger**: On push to main branch; manual dispatch for production deploys

### Pipeline Stages

1. Test: Run Ruby test suite
2. Build: Build Docker image for API and Worker runtimes
3. Push: Push images to container registry
4. Deploy: Apply Kubernetes manifests to target environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual or HPA (inferred from Kubernetes) | Confirm with service owners |
| Memory | Container resource limits | Confirm with service owners |
| CPU | Container resource limits | Confirm with service owners |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | — | — |
| Memory | — | — |
| Disk | — | — |

> Deployment configuration managed externally. Resource requirements are defined in Kubernetes manifests outside this architecture repository.
