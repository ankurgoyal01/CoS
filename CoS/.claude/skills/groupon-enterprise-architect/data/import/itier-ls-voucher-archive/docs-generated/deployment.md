---
service: "itier-ls-voucher-archive"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

itier-ls-voucher-archive is deployed as a containerized Node.js application within Groupon's Continuum platform infrastructure. It follows the standard Groupon interaction tier deployment pattern: Docker image built from source, deployed to Kubernetes (or the Continuum equivalent orchestration platform), with Memcached (`continuumLsVoucherArchiveMemcache`) running as a sidecar or co-located cache. The service is accessed via Akamai CDN and/or an internal load balancer.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Node.js 10.x application image |
| Orchestration | Kubernetes / Continuum platform | Standard Continuum interaction tier deployment |
| Load balancer | Akamai / internal load balancer | Fronts the itier for external consumer traffic |
| CDN | Akamai | CDN layer for static asset caching |
| Cache | Memcached | `continuumLsVoucherArchiveMemcache` — co-located runtime cache |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and feature testing | local / dev cluster | internal |
| staging | Pre-production validation | Groupon staging infrastructure | internal |
| production | Live consumer traffic | Groupon production infrastructure | groupon.com / livingsocial.com paths |

## CI/CD Pipeline

- **Tool**: Groupon standard CI/CD (GitHub Actions or internal Jenkins equivalent)
- **Config**: Standard Continuum itier pipeline configuration
- **Trigger**: On merge to main branch; manual deploy for hotfixes

### Pipeline Stages

1. Install dependencies: `npm install` — resolves Node.js dependencies from package.json
2. Build assets: `webpack 4` — bundles client-side JavaScript and CSS
3. Lint and test: Runs configured linting and unit test suites
4. Build Docker image: Packages application and built assets into Docker image
5. Deploy to staging: Image promoted to staging Kubernetes deployment
6. Smoke test: Health check and basic route validation against staging
7. Deploy to production: Image promoted to production Kubernetes deployment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA or Continuum auto-scaling | Configured per Continuum platform standards |
| Memory | Kubernetes pod resource limits | Configured in deployment manifest |
| CPU | Kubernetes pod resource limits | Configured in deployment manifest |

## Resource Requirements

> Deployment configuration managed externally — resource limits are configured in Continuum platform deployment manifests, not in this repository.
