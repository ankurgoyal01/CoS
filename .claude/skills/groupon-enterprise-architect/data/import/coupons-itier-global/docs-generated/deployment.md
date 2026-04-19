---
service: "coupons-itier-global"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

`coupons-itier-global` is a containerised Node.js service deployed within the Continuum Platform's I-Tier hosting layer. It serves 11 countries in production with Akamai CDN providing edge caching and geographic routing in front of the origin. Deployment configuration is managed externally to this repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Node.js 14.19.3 base image; Webpack 5.73.0 for UI asset build |
| Orchestration | Kubernetes (inferred from Continuum platform standard) | Manifest paths managed externally |
| Load balancer | Akamai CDN | Edge proxy and CDN routing for all consumer-facing page requests |
| CDN | Akamai | Caches rendered pages and static assets at edge across 11 countries |

> Specific Dockerfile paths and Kubernetes manifest paths are not captured in this architecture inventory. Deployment configuration managed externally.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and unit testing | Local | `http://localhost:3000` (default) |
| Staging | Integration testing against staging Vouchercloud and GAPI | Not documented | Not documented |
| Production | Live consumer traffic across 11 countries | Multi-region | Routed via Akamai CDN |

## CI/CD Pipeline

- **Tool**: GitHub Actions (Continuum platform standard)
- **Config**: Not captured in this architecture inventory
- **Trigger**: On push to main branch; manual dispatch

### Pipeline Stages

1. Install: Resolve npm dependencies
2. Build: Compile Preact UI assets via Webpack 5.73.0
3. Test: Run unit and integration tests
4. Docker build: Build container image
5. Deploy: Push image and apply to target environment

> Detailed pipeline configuration is managed externally.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Auto-scaling (Kubernetes HPA, inferred) | Not documented in architecture model |
| Memory | Resource limits defined per environment | Not documented |
| CPU | Resource limits defined per environment | Not documented |

## Resource Requirements

> Deployment configuration managed externally. Resource requests and limits are not captured in this architecture inventory.
