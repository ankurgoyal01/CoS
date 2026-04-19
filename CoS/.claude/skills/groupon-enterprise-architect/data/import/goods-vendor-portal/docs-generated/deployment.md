---
service: "goods-vendor-portal"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

The Goods Vendor Portal is packaged as a Docker image using a multi-stage build: the first stage uses Node.js 14.21 to run `ember build`, producing a static asset bundle; the second stage copies those assets into an Nginx runtime image that serves the SPA and proxies API traffic to GPAPI. The resulting image is deployed to Kubernetes via Jenkins CI/CD pipelines.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Multi-stage Dockerfile — Node.js 14.21 build stage, Nginx runtime stage |
| Orchestration | Kubernetes | Kubernetes manifests manage pod lifecycle, replicas, and environment config |
| Load balancer | Nginx (in-container) | Nginx serves static SPA assets and proxies `/goods-gateway/*` to GPAPI upstream |
| CDN | Not applicable | Static assets served directly from Nginx; no CDN layer evidenced in this repository |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and feature branch testing | — | Localhost / dev cluster |
| Staging | Pre-production integration and QA | — | Internal staging URL (managed externally) |
| Production | Live merchant-facing portal | — | Production URL (managed externally) |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: Jenkinsfile (managed in the service repository)
- **Trigger**: On push to feature branches (build + test); on merge to main (build + deploy to staging); on release tag (deploy to production)

### Pipeline Stages

1. **Install**: Runs `npm install` to restore Node.js dependencies
2. **Lint**: Runs ESLint and template linting via `ember-template-lint`
3. **Test**: Executes Ember test suite (`ember test` — unit, integration, and acceptance tests)
4. **Build**: Runs `ember build --environment=production` to produce the static asset bundle
5. **Docker Build**: Builds the multi-stage Docker image, copying assets into the Nginx runtime stage
6. **Push**: Pushes the Docker image to the Groupon container registry
7. **Deploy**: Updates the Kubernetes deployment manifest and rolls out to the target environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Minimum/maximum replicas managed via Kubernetes deployment config (values managed externally) |
| Memory | Kubernetes resource limits | Request/limit values defined in Helm values per environment |
| CPU | Kubernetes resource limits | Request/limit values defined in Helm values per environment |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Deployment configuration managed externally | Deployment configuration managed externally |
| Memory | Deployment configuration managed externally | Deployment configuration managed externally |
| Disk | Ephemeral (static assets only — no persistent disk required) | — |

> Specific resource request and limit values are managed in Helm values files outside this repository. Consult the Goods/Sox team or the Kubernetes deployment manifests for current values.
