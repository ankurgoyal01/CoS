---
service: "garvis"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Garvis is a containerized Python service running three application processes: the Django web server (`continuumJarvisWebApp`), the Pub/Sub bot runtime (`continuumJarvisBot`), and the RQ worker/scheduler (`continuumJarvisWorker`). Each process is deployed as a separate container. Gunicorn serves the Django application. Deployment configuration is managed externally to this architecture repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Each of the three application containers is packaged as a Docker image |
| HTTP server | Gunicorn | Serves the Django web app (`continuumJarvisWebApp`) |
| Database | PostgreSQL | `continuumJarvisPostgres` — dedicated instance per environment |
| Cache / Queue | Redis 7.1.0 | `continuumJarvisRedis` — shared by all three application containers |
| Orchestration | Kubernetes (expected) | Deployment configuration managed externally |
| Load balancer | Internal (expected) | Routes HTTP traffic to `continuumJarvisWebApp` Gunicorn instances |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and feature testing | Local / developer workstation | localhost |
| Staging | Pre-production integration and QA | Groupon internal (region not specified in architecture model) | Internal staging URL |
| Production | Live service serving all Google Chat users | Groupon production (region not specified in architecture model) | Internal production URL |

> Deployment configuration managed externally. Specific regions, hostnames, and Kubernetes manifests are not tracked in this architecture repository.

## CI/CD Pipeline

- **Tool**: GitHub Actions (Groupon standard)
- **Config**: Managed in the garvis application repository (not in this architecture repo)
- **Trigger**: On push to main branch; on pull request; manual dispatch

### Pipeline Stages

1. Test: Run Python unit and integration test suite
2. Build: Build Docker images for `continuumJarvisWebApp`, `continuumJarvisBot`, and `continuumJarvisWorker`
3. Push: Publish images to container registry
4. Deploy: Apply Kubernetes manifests to target environment

> Pipeline stage details are not discoverable from the architecture model. Deployment configuration managed externally.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (`continuumJarvisWebApp`) | Kubernetes HPA (expected) | Min/max replica counts managed externally |
| Horizontal (`continuumJarvisWorker`) | Manual or HPA based on RQ queue depth | Worker count managed externally |
| `continuumJarvisBot` | Single subscriber process (Pub/Sub ordering) | Typically one replica per subscription |

## Resource Requirements

> Deployment configuration managed externally. Resource requests and limits (CPU, memory) are not specified in the architecture model.
