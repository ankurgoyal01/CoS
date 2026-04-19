---
service: "goods-stores-api"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Goods Stores API is deployed as a containerized Ruby application on the Continuum platform infrastructure. Three processes run from the same codebase: the Puma web server (API), the Resque worker pool (Workers), and the MessageBus consumer swarm. Each is deployed as a separate container or process group to allow independent scaling.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Application container built from service Dockerfile |
| Orchestration | Kubernetes (Continuum platform) | Deployment manifests managed by platform team |
| Load balancer | Managed by Continuum platform infrastructure | Routes HTTP traffic to `continuumGoodsStoresApi` (Puma) |
| CDN | > Not applicable | API is internal; no CDN configured |

> Deployment configuration is managed externally by the Continuum platform team. Specific Kubernetes manifest paths and Helm values are not stored in this repository.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and unit testing | Local | `http://localhost:3000` |
| staging | Integration testing against staging Continuum services | US / EU (Continuum staging) | Internal staging URL |
| production | Live production traffic | US / EU (Continuum production) | Internal production URL |

## CI/CD Pipeline

- **Tool**: Continuum platform CI (GitHub Actions or Jenkins — specific tool managed externally)
- **Config**: Pipeline configuration managed by Continuum platform team
- **Trigger**: On push to main branch; on pull request (validate/test); manual dispatch for production deploys

### Pipeline Stages

1. **Test**: Runs RSpec test suite; validates code against Ruby 2.5.9
2. **Build**: Builds Docker image tagged with commit SHA
3. **Publish**: Pushes image to container registry
4. **Deploy Staging**: Rolls out to staging environment; runs smoke tests
5. **Deploy Production**: Rolls out to production via canary or rolling deployment (strategy managed by platform)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| API (Puma) | Horizontal auto-scaling | Min/max replicas configured by platform team |
| Workers (Resque) | Horizontal manual or auto-scaling | `RESQUE_WORKER_COUNT` env var controls concurrency per pod |
| MessageBus Consumer | Horizontal | Swarm process; scaled independently |
| Memory | Limits set per container | Managed by platform team |
| CPU | Limits set per container | Managed by platform team |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > Not discoverable from inventory | > Not discoverable from inventory |
| Memory | > Not discoverable from inventory | > Not discoverable from inventory |
| Disk | > Not applicable — stateless; storage is external | > Not applicable |

> Deployment configuration managed externally by the Continuum platform team. Contact Goods CIM Engineering for environment-specific resource sizing.
