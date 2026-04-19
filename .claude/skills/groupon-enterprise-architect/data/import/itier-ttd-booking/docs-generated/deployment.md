---
service: "itier-ttd-booking"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

`itier-ttd-booking` is a Node.js ITier application deployed as part of the Continuum platform. Deployment follows standard Continuum ITier service patterns — containerized and orchestrated on Kubernetes, with environment-specific configuration injected via environment variables. Specific CI/CD pipeline and manifest paths are managed in the service's source repository, not in this architecture module.

> Deployment configuration managed externally. Details below reflect the standard Continuum ITier deployment pattern inferred from the tech stack.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile in service source repository |
| Orchestration | Kubernetes | Kubernetes manifests in service source repository |
| Load balancer | Akamai / ALB | Traffic routed through Groupon CDN/load balancer layer |
| CDN | Akamai | Static assets served via Akamai CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and integration testing | — | localhost |
| staging | Pre-production validation | Groupon data center / AWS | Internal staging URL |
| production | Live consumer traffic | Groupon data center / AWS | groupon.com/live/checkout/booking/* |

## CI/CD Pipeline

- **Tool**: Jenkins / GitHub Actions (standard Continuum ITier pipeline)
- **Config**: Managed in service source repository
- **Trigger**: On pull request merge to main branch

### Pipeline Stages

1. Install dependencies: `npm install`
2. Build assets: Webpack 4.43.0 bundles client-side JS and CSS
3. Run tests: Unit and integration test suite
4. Build Docker image: Containerize the Node.js application
5. Push image: Publish to internal container registry
6. Deploy to staging: Apply Kubernetes manifests to staging cluster
7. Deploy to production: Apply Kubernetes manifests to production cluster after staging validation

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min/max replica counts managed in Kubernetes manifests |
| Memory | Kubernetes resource limits | Managed in Kubernetes manifests |
| CPU | Kubernetes resource limits | Managed in Kubernetes manifests |

## Resource Requirements

> Not discoverable from the architecture module. Resource requests and limits are defined in Kubernetes manifests in the service source repository.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | — | — |
| Memory | — | — |
| Disk | — | — |
