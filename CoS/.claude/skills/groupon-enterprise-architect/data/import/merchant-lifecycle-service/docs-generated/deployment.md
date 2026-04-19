---
service: "merchant-lifecycle-service"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Merchant Lifecycle Service deploys two JVM containers — `continuumMlsRinService` (the REST API) and `continuumMlsSentinelService` (the Kafka worker) — as part of the Continuum platform. Both run on Java 17 and are packaged as Dropwizard/JTier fat JARs. Deployment configuration is managed externally by the Continuum platform team.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | JTier-standard Dockerfile; fat JAR entry point |
| Orchestration | Kubernetes (Continuum platform) | Managed by Continuum platform team |
| Load balancer | Continuum platform LB | Fronts `continuumMlsRinService` REST endpoints |
| CDN | Not applicable | Internal service; no CDN |

> Deployment configuration managed externally by the Continuum platform team. Specific manifest paths and Dockerfile locations to be confirmed by service owner.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local and CI development | — | Internal dev endpoint |
| Staging | Pre-production integration testing | — | Internal staging endpoint |
| Production | Live merchant traffic | — | Internal production endpoint |

> Specific environment URLs and regions are not documented here. They are managed in the Continuum platform infrastructure registry.

## CI/CD Pipeline

- **Tool**: Groupon CI/CD (JTier-standard pipeline)
- **Config**: Service repository CI configuration (exact path to be confirmed by service owner)
- **Trigger**: On pull request merge to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. Build: Compile Java 17 source and run unit tests via Maven
2. Test: Integration tests against embedded/test databases and mock services
3. Package: Produce fat JAR and Docker image
4. Deploy to Staging: Deploy both `continuumMlsRinService` and `continuumMlsSentinelService` to staging
5. Smoke Test: Validate `/ping` and key read endpoints in staging
6. Deploy to Production: Promote staging artifacts to production

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (`continuumMlsRinService`) | Kubernetes HPA | Min/max replica counts managed by Continuum platform team |
| Horizontal (`continuumMlsSentinelService`) | Kubernetes deployment replicas | Scaled to Kafka partition count for optimal throughput |
| Memory | JVM heap configuration | JTier-standard heap settings; exact limits to be confirmed |
| CPU | Kubernetes resource limits | Managed by Continuum platform team |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not evidenced | Not evidenced |
| Memory | Not evidenced | Not evidenced |
| Disk | Not evidenced | Not evidenced |

> Deployment configuration managed externally. Resource requests and limits are defined in the Continuum platform Kubernetes manifests and are not documented in the architecture inventory.
