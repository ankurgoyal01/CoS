---
service: "relevance-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

The Relevance Service is deployed as a containerized Java / Vert.x application on Kubernetes, following the standard Continuum Platform deployment model. The service runs alongside a dedicated Elasticsearch cluster (Feynman Search) for search index operations.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard Continuum Java service Dockerfile |
| Orchestration | Kubernetes | Deployed via Helm charts / Kubernetes manifests |
| Load balancer | Internal service mesh / Kubernetes Service | Traffic routed via API Proxy |
| CDN | None | Backend API service; no CDN layer |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local and shared development testing | -- | Internal dev endpoint |
| staging | Pre-production validation and Booster migration testing | -- | Internal staging endpoint |
| production | Live consumer search and browse traffic | Multi-region | Internal production endpoint |

## CI/CD Pipeline

- **Tool**: GitHub Actions / Jenkins (standard Continuum CI)
- **Config**: Defined in source repository
- **Trigger**: On push to main, pull request validation, manual dispatch

### Pipeline Stages

1. **Build**: Compile Java source, run unit tests, build Docker image
2. **Test**: Execute integration tests against test Elasticsearch cluster
3. **Publish**: Push Docker image to container registry
4. **Deploy Staging**: Deploy to staging environment, run smoke tests
5. **Deploy Production**: Rolling deployment to production Kubernetes cluster

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Horizontal Pod Autoscaler (HPA) | Scales based on CPU and request latency metrics |
| Memory | Kubernetes resource limits | Configured per environment |
| CPU | Kubernetes resource limits | Configured per environment |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Defined per environment | Defined per environment |
| Memory | Defined per environment (JVM heap + overhead) | Defined per environment |
| Disk | Minimal (stateless service; Elasticsearch storage managed separately) | -- |

> Exact resource requests, limits, and scaling thresholds are managed in Kubernetes manifests in the source repository. Elasticsearch cluster sizing is managed independently.
