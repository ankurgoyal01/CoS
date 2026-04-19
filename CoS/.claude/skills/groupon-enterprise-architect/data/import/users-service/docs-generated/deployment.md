---
service: "users-service"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Users Service is deployed as three distinct runtime processes within the Continuum platform: the Sinatra HTTP API (`continuumUsersService`) served by Puma, the Resque background worker pool (`continuumUsersResqueWorkers`), and the GBus Message Bus Consumer (`continuumUsersMessageBusConsumer`). All three processes run from the same Ruby codebase but with different entry points. Deployment configuration is managed externally to this repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile in users-service repository |
| Orchestration | Kubernetes | Manifests managed externally (Continuum platform infrastructure) |
| Load balancer | Akamai / ALB | Fronts the Puma HTTP API |
| CDN | Akamai | Edge routing for HTTPS endpoints |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and unit testing | local | `http://localhost:3000` |
| Staging | Integration testing and pre-release validation | AWS us-east-1 (Continuum staging) | Internal staging URL |
| Production | Live traffic serving Groupon consumers | AWS us-east-1 (Continuum production) | Internal production URL |

## CI/CD Pipeline

- **Tool**: GitHub Actions
- **Config**: `.github/workflows/` within users-service repository
- **Trigger**: On pull request (validate), on merge to main (build + deploy to staging), manual dispatch (deploy to production)

### Pipeline Stages

1. **Test**: Run RSpec test suite with database and Redis in CI containers
2. **Build**: Build Docker image and push to container registry
3. **Deploy Staging**: Apply Kubernetes manifests to staging cluster
4. **Deploy Production**: Apply Kubernetes manifests to production cluster (gated on manual approval or promotion)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| API (Puma) horizontal | Kubernetes HPA or manual replica count | Configured externally |
| Resque Workers horizontal | Resque pool sizing via `resque-pool.yml` + pod replicas | `PUMA_WORKERS` / `resque-pool.yml` |
| Message Bus Consumer horizontal | Single consumer process per pod; parallelism via pod replicas | Configured externally |

## Resource Requirements

> Deployment configuration is managed externally. Exact CPU and memory request/limit values are defined in Kubernetes manifests outside this repository.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not discoverable from inventory | Not discoverable from inventory |
| Memory | Not discoverable from inventory | Not discoverable from inventory |
| Disk | Stateless (no local disk required) | Not applicable |
