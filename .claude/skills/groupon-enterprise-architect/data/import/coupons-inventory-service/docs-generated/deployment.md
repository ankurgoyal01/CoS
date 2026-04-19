---
service: "coupons-inventory-service"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Coupons Inventory Service is a Java/Dropwizard (JTIER) application deployed as part of the Continuum platform. Following standard Continuum deployment conventions, the service is containerized and deployed to Groupon's infrastructure. The service depends on a Postgres database, Redis cache, and IS Core Message Bus connectivity in each environment.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard JTIER Docker image |
| Orchestration | Kubernetes (inferred from Continuum conventions) | Standard Continuum deployment manifests |
| Load balancer | Platform-managed | Continuum platform load balancing |
| CDN | none | Backend service, no CDN required |

> Exact infrastructure details follow Continuum platform conventions. Confirm specific Kubernetes manifests and deployment configuration with service owner.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and testing | — | localhost |
| Staging | Pre-production validation | — | Internal staging URL |
| Production | Live traffic serving | — | Internal production URL |

> Exact environment URLs and regions are managed by the Continuum platform team.

## CI/CD Pipeline

- **Tool**: Groupon internal CI/CD (inferred from Continuum platform conventions)
- **Config**: Standard JTIER pipeline configuration
- **Trigger**: On merge to main branch

### Pipeline Stages

1. **Build**: Compile Java source, run unit tests, package Dropwizard application
2. **Test**: Execute integration tests against test database and mock services
3. **Package**: Build Docker image with application JAR
4. **Deploy to Staging**: Deploy to staging environment with health check validation
5. **Deploy to Production**: Deploy to production environment with rolling update strategy

> Exact pipeline stages and configuration follow Continuum platform conventions. Confirm with service owner.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Auto-scaling (inferred) | Managed by platform |
| Memory | JVM heap configuration | JTIER defaults |
| CPU | Platform-managed | JTIER defaults |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Platform default | Platform default |
| Memory | Platform default | Platform default |
| Disk | Minimal (stateless application) | Platform default |

> Deployment configuration managed externally by the Continuum platform. Specific resource requests and limits should be confirmed with service owner and platform team.
