---
service: "deal-management-api"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

DMAPI is deployed as two distinct process types — the Puma web server (`continuumDealManagementApi`) and the Resque worker (`continuumDealManagementWorker`) — within the Continuum platform. Both run Ruby (MRI 2.2.3 or JRuby 9.1.6.0 depending on environment configuration). Deployment configuration is managed externally to this repository.

> Deployment configuration managed externally. Details below reflect what is inferable from the inventory summary and Continuum platform conventions.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard Continuum base image; Dockerfile managed in service repo |
| Orchestration | Kubernetes (inferred from Continuum platform pattern) | Manifests managed in deployment repo |
| Load balancer | Internal Continuum load balancer | Routes traffic to Puma web workers |
| CDN | Not applicable | DMAPI is an internal API, not publicly exposed |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local developer environment | Local | `http://localhost:3000` (conventional) |
| staging | Pre-production integration testing | Groupon internal (inferred) | Internal staging URL |
| production | Live production traffic | Groupon production | Internal production URL |

## CI/CD Pipeline

- **Tool**: Jenkins or GitHub Actions (Continuum platform standard; not specified in inventory)
- **Config**: Managed in service repository (not visible in this architecture module)
- **Trigger**: On push to main branch; pull request validation

### Pipeline Stages

1. **Test**: Run Ruby test suite (RSpec/Minitest) against test database
2. **Build**: Package application into Docker image
3. **Publish**: Push image to internal container registry
4. **Deploy (staging)**: Roll out new image to staging environment
5. **Deploy (production)**: Roll out to production after staging validation

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (web) | Puma multi-process + multi-thread | `PUMA_WORKERS` / `PUMA_THREADS_MIN` / `PUMA_THREADS_MAX` env vars |
| Horizontal (worker) | Multiple Resque worker processes | `RESQUE_WORKER_COUNT` env var |
| Memory | Managed at orchestration layer | Configured in deployment manifests (not visible in inventory) |
| CPU | Managed at orchestration layer | Configured in deployment manifests (not visible in inventory) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not specified in inventory | Not specified in inventory |
| Memory | Not specified in inventory | Not specified in inventory |
| Disk | Stateless (no local disk) | Not applicable |

> Exact resource requests and limits are defined in deployment manifests maintained externally. Contact the dms-dev team for current values.
