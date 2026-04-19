---
service: "ultron-api"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

ultron-api is deployed as a containerized Scala/Play Framework service on the Continuum platform. It runs on the JVM inside Docker containers orchestrated by Kubernetes. Two relational database instances are provisioned separately and referenced via environment variables at startup. Deployment configuration is managed externally to this architecture module.

> Deployment configuration managed externally. Infrastructure details are not present in the federated architecture module. Verify Dockerfile, Helm charts, and pipeline config in the service source repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | JVM-based image; Dockerfile in service source repository |
| Orchestration | Kubernetes | Inferred from Continuum platform standard |
| Load balancer | Internal LB / Nginx | Inferred from Continuum platform standard |
| CDN | Not applicable | Internal tool; not publicly exposed |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local developer testing | local | localhost |
| staging | Integration testing and QA | US-East (inferred) | Internal staging URL |
| production | Live data operations workload | US-East / US-West (inferred) | Internal production URL |

## CI/CD Pipeline

- **Tool**: Jenkins (inferred from Continuum platform standard)
- **Config**: Managed in the service source repository
- **Trigger**: On push to main branch; manual dispatch for production deploys

### Pipeline Stages

1. Build: Compile Scala sources and run sbt build
2. Test: Run unit and integration tests via sbt test
3. Docker Build: Build and tag JVM container image
4. Deploy to Staging: Push to Kubernetes staging namespace
5. Schema Migrations: Run Play Evolutions against staging database
6. Deploy to Production: Gated production rollout with schema migrations

> Pipeline stages are inferred from standard Continuum Play Framework deployment patterns. Verify against the service source repository CI configuration.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual or HPA | Min/max replicas defined in Helm values |
| Memory | Kubernetes limits | JVM heap configured via `JAVA_OPTS`; limits in Helm values |
| CPU | Kubernetes limits | Defined in Helm values in service source repo |

## Resource Requirements

> No evidence found in codebase. Resource requests and limits are defined in Kubernetes / Helm configuration in the service source repository.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not specified | Not specified |
| Memory | Not specified | Not specified |
| Disk | Not specified | Not specified |

> JVM services typically require larger memory allocations than other runtimes. Consult Helm values in the service source repository for actual limits.
