---
service: "api-proxy"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

API Proxy is a containerised JVM service deployed on the Continuum platform. It runs as a Vert.x HTTP server on a configurable port. Deployment configuration is managed externally to the architecture model; specific Kubernetes manifests, Helm charts, and CI/CD pipeline definitions reside in the service repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile in service repository |
| Orchestration | Kubernetes | Helm chart / k8s manifests in service repository |
| Load balancer | Platform-managed | Traffic routed from Groupon edge (Akamai / platform LB) to API Proxy pods |
| CDN | Akamai | Sits upstream of API Proxy for cached and static content; dynamic API traffic passes through to the proxy |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and integration testing | — | — |
| staging | Pre-production validation; mirrors production topology | US / EU | Internal staging URL |
| production | Live consumer and merchant traffic | US / EU | `api.groupon.com` (via Akamai edge) |

## CI/CD Pipeline

- **Tool**: Jenkins / GitHub Actions (Continuum platform standard)
- **Config**: Defined in service repository (not in this architecture repo)
- **Trigger**: On pull request merge to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. Build: Maven `mvn package` compiles Java sources and produces a deployable JAR
2. Test: Unit and integration tests executed via Maven Surefire
3. Docker build: Container image built and tagged
4. Publish: Image pushed to internal container registry
5. Deploy to staging: Helm upgrade applied to staging Kubernetes cluster
6. Smoke test: Health check against `/heartbeat` and `/grpn/healthcheck`
7. Deploy to production: Helm upgrade applied to production cluster (manual gate for production)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Minimum replicas defined in Helm values; scales on CPU utilisation |
| Memory | JVM heap + container limit | Configured in Helm values per environment |
| CPU | Container requests and limits | Configured in Helm values per environment |

## Resource Requirements

> Deployment configuration managed externally. Specific CPU/memory requests and limits are defined in the Helm chart within the service repository and are not modelled in the architecture DSL.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Defined in Helm chart | Defined in Helm chart |
| Memory | Defined in Helm chart | Defined in Helm chart |
| Disk | Ephemeral only | Ephemeral only |
