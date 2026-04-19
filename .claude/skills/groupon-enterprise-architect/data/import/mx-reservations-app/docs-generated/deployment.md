---
service: "mx-reservations-app"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

MX Reservations App is containerized with Docker running a Node.js 10/12 runtime. It is deployed to Kubernetes clusters in two data centres — snc1 (primary, US) and dub1 (secondary, EU) — using Capistrano for orchestration and promotion. The service serves the merchant-facing SPA and proxies API calls to backend Continuum services.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Node.js 10/12 base image; application built with Webpack 4.29.6 |
| Orchestration | Kubernetes + Capistrano | Deployed via Capistrano to k8s clusters in snc1 and dub1 |
| Load balancer | No evidence found | Managed by cluster ingress; details not in architecture inventory |
| CDN | No evidence found | CDN configuration not found in architecture inventory |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production validation | snc1 / dub1 | No evidence found |
| Production | Live merchant traffic | snc1 (US primary) | No evidence found |
| Production | Live merchant traffic | dub1 (EU secondary) | No evidence found |

## CI/CD Pipeline

- **Tool**: No evidence found; assumed internal Groupon CI (Capistrano-based)
- **Config**: Deployment managed via Capistrano configuration in the repository
- **Trigger**: On-merge to main branch and manual dispatch

### Pipeline Stages

1. Build: Compile TypeScript and bundle SPA assets with Webpack 4.29.6
2. Test: Run Jest unit tests and CodeceptJS end-to-end acceptance tests
3. Containerize: Build Docker image with Node.js 10/12 runtime
4. Deploy to staging: Capistrano promotes image to Kubernetes staging cluster (snc1/dub1)
5. Deploy to production: Capistrano promotes validated image to production Kubernetes clusters

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | No evidence found — managed via k8s manifests |
| Memory | Kubernetes resource limits | No evidence found — managed via k8s manifests |
| CPU | Kubernetes resource limits | No evidence found — managed via k8s manifests |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found | No evidence found |
| Memory | No evidence found | No evidence found |
| Disk | No evidence found | No evidence found |

> Deployment configuration (resource limits, HPA thresholds, ingress rules) is managed externally in Kubernetes manifests and Capistrano configuration. Consult the booking-tool team for exact values.
