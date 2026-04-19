---
service: "bling"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

bling is a containerized Ember.js SPA served by an Nginx reverse proxy container (`blingNginx`). The build process compiles the Ember application into a set of fingerprinted static assets, which are then baked into the Nginx container image. The Nginx container serves the static SPA bundle and reverse-proxies API calls to the Accounting Service and File Sharing Service. Deployment follows Continuum platform conventions on Kubernetes.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Two-stage Docker build: Node.js build stage (Ember CLI compile) + Nginx serve stage |
| Orchestration | Kubernetes | Manifests managed by Continuum platform team |
| Load balancer | Kubernetes Ingress / ALB | Fronts `blingNginx` for internal user access |
| CDN | None | Internal application; no CDN layer |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development with Ember CLI dev server | local | `http://localhost:4200` |
| staging | Pre-production integration testing for finance staff | AWS us-east-1 | Internal staging URL |
| production | Live finance and accounting operations | AWS us-east-1 | Internal production URL |

## CI/CD Pipeline

- **Tool**: GitHub Actions (Continuum platform standard)
- **Config**: `.github/workflows/` (managed in service repo)
- **Trigger**: On push to feature branches (test + build); on merge to main (deploy to staging); manual dispatch (deploy to production)

### Pipeline Stages

1. **Install**: Runs `npm install` and `bower install` to restore dependencies
2. **Test**: Executes Ember CLI QUnit tests (`ember-cli-qunit`)
3. **Build**: Runs `ember build --environment=production` to compile fingerprinted static assets
4. **Docker Build**: Builds Nginx Docker image with compiled assets baked in
5. **Push**: Pushes Docker image to container registry
6. **Deploy Staging**: Updates Kubernetes deployment in staging cluster
7. **Deploy Production**: Updates Kubernetes deployment in production cluster (gated by approval)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min/max replicas managed by platform team |
| Memory | Kubernetes resource limits | Nginx container is lightweight; managed by platform team |
| CPU | Kubernetes resource limits | Managed by platform team |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Deployment configuration managed externally | Deployment configuration managed externally |
| Memory | Deployment configuration managed externally | Deployment configuration managed externally |
| Disk | Stateless Nginx; compiled assets baked into image | — |

> Deployment configuration managed externally by the Continuum platform team. Contact the Finance Platform team for specific resource limits and replica counts per environment.
