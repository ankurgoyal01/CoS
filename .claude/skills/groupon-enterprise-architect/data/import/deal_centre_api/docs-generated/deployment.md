---
service: "deal_centre_api"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Deal Centre API is a containerized Spring Boot application deployed within the Continuum Platform. Deployment configuration is managed externally to this architecture import folder; details below reflect Continuum Platform standards and should be verified against the service repository's infrastructure configuration.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile in service repository root |
| Orchestration | Kubernetes | Helm chart or k8s manifests in service repository |
| Load balancer | Internal Continuum load balancer | Routes traffic from Deal Centre UI to `continuumDealCentreApi` |
| CDN | None | Internal service — not exposed via CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local and CI development | — | `http://localhost:8080` |
| staging | Pre-production validation | — | Internal staging URL — see service registry |
| production | Live production traffic | — | Internal production URL — see service registry |

## CI/CD Pipeline

- **Tool**: GitHub Actions (standard Groupon CI/CD)
- **Config**: `.github/workflows/` in the service repository
- **Trigger**: On push to main branch; on pull request for validation

### Pipeline Stages

1. Build: Compile Java source and run unit tests with Maven
2. Test: Execute integration tests against a test PostgreSQL instance
3. Package: Build Docker image and push to container registry
4. Deploy (staging): Deploy to staging environment via Helm/kubectl
5. Deploy (production): Deploy to production environment on approval

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min/max replicas defined in Helm values — verify in service repository |
| Memory | JVM heap + container limits | Configured via Kubernetes resource limits |
| CPU | Container CPU limits | Configured via Kubernetes resource requests/limits |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | — | — |
| Memory | — | — |
| Disk | — | — |

> Deployment configuration is managed externally. Exact resource requests, limits, and replica counts are defined in the service repository's Helm chart or Kubernetes manifests.
