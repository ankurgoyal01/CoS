---
service: "fraud-arbiter"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Fraud Arbiter is deployed as a containerized Rails application on Kubernetes. The Docker image packages both the Puma web server (for API endpoints and webhook receivers) and Sidekiq workers (for background job processing). Jenkins manages the CI/CD pipeline from build through to production deployment.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` in repository root |
| Orchestration | Kubernetes | Helm chart with separate Deployment manifests for API and Sidekiq worker pods |
| Load balancer | Kubernetes Ingress / internal load balancer | Routes external webhook traffic and internal service-to-service traffic |
| CDN | none | Internal service; no CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and testing | local | localhost |
| staging | Pre-production integration testing | — | Internal staging URL |
| production | Live fraud review processing | — | Internal production URL |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (repository root)
- **Trigger**: On push to main branch; manual dispatch for production promotion

### Pipeline Stages

1. **Build**: Builds Docker image, installs Ruby gems via Bundler
2. **Test**: Runs Rails test suite (RSpec/minitest)
3. **Lint**: Runs RuboCop for style and static analysis
4. **Push**: Pushes Docker image to container registry
5. **Deploy Staging**: Deploys to staging Kubernetes namespace via Helm
6. **Integration Tests**: Runs smoke tests against staging environment
7. **Deploy Production**: Promotes image to production Kubernetes namespace via Helm after approval

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (API) | Kubernetes HPA | Min/max replica counts managed in Helm values |
| Horizontal (Sidekiq) | Kubernetes HPA | Scales based on Redis queue depth |
| Memory | Kubernetes resource limits | Managed in Helm values |
| CPU | Kubernetes resource limits | Managed in Helm values |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase | > No evidence found in codebase |
| Memory | > No evidence found in codebase | > No evidence found in codebase |
| Disk | ephemeral only | — |

> Exact resource request/limit values are managed in Helm values files outside this repository. Deployment configuration managed externally for precise resource sizing.
