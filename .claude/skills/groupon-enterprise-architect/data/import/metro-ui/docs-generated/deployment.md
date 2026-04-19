---
service: "metro-ui"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production-us, production-eu]
---

# Deployment

## Overview

Metro UI is containerized using Docker (alpine-node14.19.1 base image) and deployed to Kubernetes across multiple regions (US and EU). Production deployments use Harness Canary strategy for progressive traffic rollout and safe rollback.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | alpine-node14.19.1 base image |
| Orchestration | Kubernetes | Multi-region cluster deployment |
| Deployment strategy | Harness Canary | Progressive traffic rollout with automated rollback |
| Load balancer | Kubernetes ingress / itier routing | Handles inbound merchant traffic |
| CDN | No evidence found | Static assets served by itier-server process |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and testing | Local | localhost |
| Staging | Pre-production integration testing | US | Internal staging URL |
| Production (US) | Live merchant traffic | US (multi-region) | groupon.com /merchant/center/draft |
| Production (EU) | Live merchant traffic, EU data residency | EU (multi-region) | EU groupon domain /merchant/center/draft |

## CI/CD Pipeline

- **Tool**: Harness (canary deployment); CI details managed in service repo
- **Config**: Helm values files (external to this architecture repo)
- **Trigger**: On merge to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. Build: Compile TypeScript, run Webpack bundling via `@grpn/mx-webpack ^2.18.0`, produce Docker image
2. Test: Run unit and integration test suites
3. Publish: Push Docker image to container registry
4. Canary Deploy: Harness routes a small percentage of traffic to the new version in production
5. Promote / Rollback: Harness promotes to full traffic or rolls back based on canary health metrics

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min/max replica counts managed via Helm values |
| Memory | Kubernetes resource limits | Defined in Helm values per environment |
| CPU | Kubernetes resource limits | Defined in Helm values per environment |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found | No evidence found |
| Memory | No evidence found | No evidence found |
| Disk | Stateless — no persistent disk | Not applicable |

> Exact CPU and memory resource requests/limits are managed in Helm values files external to this architecture repository. Contact the Metro Dev team (metro-dev-blr@groupon.com) for current values.
