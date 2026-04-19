---
service: "epods"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

EPODS is a Java/Dropwizard service deployed as a containerized workload on the Groupon Continuum platform. It follows the standard JTier deployment model: packaged as a Docker image, orchestrated via Kubernetes, and promoted through development, staging, and production environments. Deployment configuration is managed externally to this repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | JVM 17 base image; packaged via Maven |
| Orchestration | Kubernetes | Deployment manifests managed in Groupon infra repo |
| Load balancer | Internal LB / Akamai | Terminates inbound traffic; routes to EPODS pod pool |
| CDN | Not applicable | Internal service — not CDN-fronted |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local and CI development | — | Internal dev routing |
| staging | Pre-production integration testing | — | Internal staging routing |
| production | Live traffic serving Groupon consumers and partner webhooks | — | Internal production routing |

> Specific URLs are managed by the Groupon infrastructure team and not stored in this repository.

## CI/CD Pipeline

- **Tool**: GitHub Actions (central Groupon CI/CD)
- **Config**: Managed in the service repository's `.github/workflows/`
- **Trigger**: On push to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. Build: Compile Java 17 source with Maven; run unit tests
2. Test: Integration tests against in-memory H2 or containerized Postgres/Redis
3. Package: Build Docker image; push to Groupon container registry
4. Deploy to Staging: Apply Kubernetes manifests to staging namespace
5. Smoke Test: Validate health endpoint and key API paths post-deploy
6. Deploy to Production: Apply Kubernetes manifests to production namespace on approval

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min/Max replicas configured in infra repo |
| Memory | JVM heap + container limits | Configured per environment in Kubernetes manifests |
| CPU | Container resource requests/limits | Configured per environment in Kubernetes manifests |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found | > No evidence found |
| Memory | > No evidence found | > No evidence found |
| Disk | Ephemeral only | Not applicable |

> Deployment configuration managed externally. Refer to the Groupon infrastructure repository and the JTier platform team for exact resource sizing and Kubernetes manifest details.
