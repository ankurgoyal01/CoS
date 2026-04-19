---
service: "calendar-service"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Calendar Service is deployed as two distinct runtime containers within the Continuum platform: the API hosts (`continuumCalendarServiceCalSer`) serving synchronous REST traffic, and the utility hosts (`continuumCalendarUtility`) running background Quartz scheduler workers. Both are JVM-based Dropwizard/JTier services. Data stores (Postgres, MySQL, Redis) are provisioned as managed DaaS instances by the JTier platform rather than deployed by the service team directly.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard JTier Dropwizard container image; Dockerfile path not declared in architecture DSL |
| Orchestration | Kubernetes (JTier platform) | Deployment manifests managed by JTier platform conventions; manifest paths not declared in architecture DSL |
| Load balancer | Internal platform load balancer | Routes traffic to `continuumCalendarServiceCalSer` API pods |
| CDN | none | Internal service; no CDN in front of calendar APIs |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local and developer integration testing | — | Not declared in architecture DSL |
| Staging | Pre-production integration and QA | — | Not declared in architecture DSL |
| Production | Live booking and availability serving | — | Not declared in architecture DSL |

## CI/CD Pipeline

- **Tool**: Not declared in architecture DSL — standard Groupon CI/CD tooling expected
- **Config**: Not declared in architecture DSL
- **Trigger**: On merge to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. Build: Compile Java source with Maven; run unit and integration tests
2. Package: Build Docker image; tag with commit SHA and semantic version
3. Validate: Run DSL validation if architecture files are modified
4. Deploy Staging: Deploy API hosts and utility hosts to staging environment
5. Deploy Production: Deploy API hosts and utility hosts to production after staging verification

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Auto-scaling via JTier/Kubernetes HPA | Min/max replica counts not declared in architecture DSL |
| Memory | JVM heap + container memory limits | Limits not declared in architecture DSL |
| CPU | Container CPU limits | Limits not declared in architecture DSL |

> Deployment configuration managed externally via JTier platform tooling. Consult the service repository and JTier deployment manifests for precise resource requests, limits, and scaling policies.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not declared in architecture DSL | Not declared in architecture DSL |
| Memory | Not declared in architecture DSL | Not declared in architecture DSL |
| Disk | Stateless API and worker containers; no local disk requirements | — |
