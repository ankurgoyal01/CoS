---
service: "mds"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

MDS is deployed as a containerized application on Kubernetes. The service runs as a Helm-managed deployment within the Continuum platform's legacy-prod cluster. It consists of the main application container (serving both the JTier API and the Node.js deal-service worker), backed by managed PostgreSQL, Redis, and MongoDB instances. CI/CD is managed via Jenkins.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile in repository root |
| Orchestration | Kubernetes | Helm chart: `marketing-deal-service` |
| Load balancer | Platform-managed (ALB/internal) | Configured via Kubernetes service/ingress |
| CDN | None | Internal service; not consumer-facing |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and testing | local / dev cluster | localhost / dev service discovery |
| staging | Pre-production integration testing | staging cluster | staging service discovery |
| production | Live traffic serving | legacy-prod cluster | production service discovery |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: Jenkins job `mds-deploy`
- **Trigger**: On merge to main branch; manual dispatch

### Pipeline Stages

1. **Build**: Compile Java/JTier code, install Node.js dependencies, run unit tests
2. **Test**: Execute integration test suite against staging dependencies
3. **Docker Build**: Build container image with both JTier and Node.js worker layers
4. **Push**: Push container image to internal container registry
5. **Deploy to Staging**: Helm upgrade to staging namespace; run smoke tests
6. **Deploy to Production**: Helm upgrade to production namespace; verify health checks

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual / HPA | Configured per environment via Helm values |
| Memory | Limits configured | Per Kubernetes deployment spec |
| CPU | Limits configured | Per Kubernetes deployment spec |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Configured per environment | Configured per environment |
| Memory | Configured per environment | Configured per environment |
| Disk | Ephemeral only (stateless container) | — |

> Resource requests and limits are managed in the Helm chart values. Confirm exact values with the marketing-deals team and the platform infrastructure team.
