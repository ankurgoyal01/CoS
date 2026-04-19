---
service: "message-service"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

The CRM Message Service is a JVM application packaged via SBT and deployed as a containerized service within the Continuum platform. The React/Webpack UI assets are bundled at build time and served by the Play Framework application. The service uses Google Cloud Bigtable as its primary assignment store in cloud-deployed environments, with Apache Cassandra available in legacy or non-GCP environments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | JVM application + Play distribution; UI assets bundled |
| Orchestration | Kubernetes | Deployment manifests managed externally to this repo |
| Load balancer | Internal Continuum LB / Akamai | Routes web/mobile traffic to `/api/getmessages`; routes UI traffic to `/campaign/*` |
| CDN | Not applicable | Static UI assets served by Play; no separate CDN documented |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | — | localhost |
| Staging | Pre-production validation | — | Not documented in architecture inventory |
| Production | Live traffic; serves web/mobile/email consumers | — | Not documented in architecture inventory |

## CI/CD Pipeline

- **Tool**: Not documented in architecture inventory (Continuum platform standard CI applies)
- **Config**: Not documented in architecture inventory
- **Trigger**: On merge to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. **Build**: SBT compiles Java sources; npm/Webpack bundles React UI assets
2. **Test**: Unit and integration tests via SBT test runner
3. **Package**: SBT dist packages the Play application; Docker image built and pushed
4. **Deploy to Staging**: Image deployed to staging Kubernetes cluster
5. **Deploy to Production**: Image deployed to production Kubernetes cluster after staging validation

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA (assumed; not documented in inventory) | Not documented in architecture inventory |
| Bigtable capacity | Manual via `/api/bigtable/scale` endpoint | Triggered operationally as needed |
| Memory | JVM heap tuned via Play/SBT packaging | Not documented in architecture inventory |
| CPU | Kubernetes resource limits | Not documented in architecture inventory |

## Resource Requirements

> Deployment configuration managed externally. Specific resource request/limit values are not documented in the architecture inventory.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not documented | Not documented |
| Memory | Not documented | Not documented |
| Disk | Not documented | Not documented |
