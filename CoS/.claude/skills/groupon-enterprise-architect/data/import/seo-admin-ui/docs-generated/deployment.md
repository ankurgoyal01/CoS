---
service: "seo-admin-ui"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

seo-admin-ui is a Node.js I-Tier web application deployed as a containerised service on the Continuum platform. It follows the standard I-Tier deployment pattern: Docker-packaged, orchestrated via Kubernetes, and configured per environment through keldor-config. The service is internal-only and is not exposed through a public CDN or load balancer.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard I-Tier Dockerfile; Node 20.19.4 base image |
| Orchestration | Kubernetes | Continuum cluster; manifest paths managed by platform team |
| Load balancer | Internal Kubernetes service | Internal cluster routing only; not publicly exposed |
| CDN | None | Internal admin UI; no CDN required |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local developer testing | Local | http://localhost:3000 |
| staging | Pre-production validation | > No evidence found in codebase. | > No evidence found in codebase. |
| production | Live internal admin console | > No evidence found in codebase. | > No evidence found in codebase. |

## CI/CD Pipeline

- **Tool**: > No evidence found in codebase. Standard Continuum CI/CD pipeline assumed.
- **Config**: > No evidence found in codebase.
- **Trigger**: on-push to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. **Install**: Runs `npm install` to restore dependencies
2. **Lint**: Runs ESLint / code quality checks
3. **Build**: Runs `npm run build` invoking webpack 5.91.0 to bundle frontend assets
4. **Test**: Runs unit and integration test suites
5. **Docker build**: Packages application into container image
6. **Deploy**: Publishes image to Continuum Kubernetes cluster for the target environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | auto-scaling (HPA) | > No evidence found in codebase. Min/max replica counts managed by platform team. |
| Memory | Kubernetes resource limits | > No evidence found in codebase. |
| CPU | Kubernetes resource limits | > No evidence found in codebase. |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase. | > No evidence found in codebase. |
| Memory | > No evidence found in codebase. | > No evidence found in codebase. |
| Disk | Ephemeral only | Ephemeral only |

> Deployment configuration managed externally by the Continuum platform team. Kubernetes manifests and Helm values are not stored in the seo-admin-ui repository.
