---
service: "sponsored-campaign-itier"
title: Deployment
generated: "2026-03-02"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [production, staging]
---

# Deployment

## Overview

The service runs as a Docker container on Kubernetes, deployed via napistrano and Krane. CI/CD is managed by DeployBot (Harness) with Jenkins for build automation. Production runs across three regions (us-west-1, us-central1, eu-west-1); staging runs across three regions (us-central1, us-west-1, us-west-2). Horizontal Pod Autoscaler scales replicas between 2 and 10 based on load.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Base image: alpine-node20.19.5 |
| Orchestration | Kubernetes + Krane | Deployed via napistrano 2.180.3 |
| Load balancer | Internal VIP | `sponsored-campaign-itier.production.service` |
| External URL | Akamai / Groupon edge | `https://www.groupon.com/merchant/center/sponsored` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| production | Live merchant traffic | us-west-1 | `https://www.groupon.com/merchant/center/sponsored` |
| production | Live merchant traffic (secondary) | us-central1 | `https://www.groupon.com/merchant/center/sponsored` |
| production | Live merchant traffic (EU) | eu-west-1 | `https://www.groupon.com/merchant/center/sponsored` |
| staging | Pre-production validation | us-central1 | — |
| staging | Pre-production validation | us-west-1 | — |
| staging | Pre-production validation | us-west-2 | — |

## CI/CD Pipeline

- **Tool**: DeployBot (Harness) + Jenkins
- **Config**: Managed via napistrano (napistrano 2.180.3 deploy configuration)
- **Trigger**: Manual deploy via DeployBot; Jenkins for build and test

### Pipeline Stages

1. Build: Compile TypeScript, bundle assets with webpack 4.46.0
2. Test: Run mocha test suite with c8 coverage
3. Containerize: Build Docker image from alpine-node20.19.5 base
4. Deploy: napistrano + Krane applies Kubernetes manifests per region
5. Validate: Health checks confirm pod readiness before traffic routing

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Horizontal Pod Autoscaler) | Min: 2, Max: 10 replicas |
| Memory | Request / Limit | 1536Mi request / 3072Mi limit (production us-west-1) |
| CPU | Request / Limit | 1000m request / limit |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | 1000m |
| Memory | 1536Mi | 3072Mi |
| Disk | — | — |

> Disk resource limits are not specified in the inventory. Resource values shown are for production us-west-1; other regions may differ.
