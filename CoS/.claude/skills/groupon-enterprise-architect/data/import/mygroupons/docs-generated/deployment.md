---
service: "mygroupons"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

My Groupons is containerized using Docker (based on the `alpine-node20` image with Chromium bundled for Puppeteer PDF generation) and deployed to Kubernetes via Helm 3 using krane as the deploy tool. Production runs across three regions (`us-central1`, `eu-west-1`, `us-west-2`) with a Horizontal Pod Autoscaler configured for 3 to 25 replicas.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `alpine-node20` base image with Chromium installed for Puppeteer; `Dockerfile` at repo root |
| Orchestration | Kubernetes + Helm 3 | Helm chart at `helm/`; deployed via krane |
| Deploy tool | krane | Kubernetes resource deployment and rollout management |
| Load balancer | API Proxy / Akamai | Inbound traffic routed through API Proxy; Akamai CDN in front for edge caching of static assets |
| CDN | Akamai | Caches static assets (JS bundles, CSS) built by Webpack |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | Local / sandbox | `http://localhost:3000` |
| Staging | Pre-production validation and QA | — | Internal staging URL |
| Production | Live customer traffic | us-central1 | — |
| Production | Live customer traffic | eu-west-1 | — |
| Production | Live customer traffic | us-west-2 | — |

## CI/CD Pipeline

- **Tool**: No evidence found for specific CI tool; assumed internal Groupon CI (Jenkins or GitHub Actions)
- **Config**: Pipeline configuration managed in the service repository
- **Trigger**: On push to main branch; manual dispatch for production deployments

### Pipeline Stages

1. Install dependencies: Runs `npm install` to restore Node.js packages
2. Lint and test: Executes linting rules and unit test suite
3. Build assets: Runs `webpack` to produce client-side bundles
4. Build Docker image: Builds container image using `alpine-node20` + Chromium
5. Push image: Pushes tagged Docker image to Groupon container registry
6. Deploy to staging: Applies Helm chart to staging cluster via krane
7. Deploy to production: Applies Helm chart to production clusters across all three regions via krane

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min: 3 replicas, Max: 25 replicas; scales on CPU/memory utilization |
| Regions | Multi-region | us-central1, eu-west-1, us-west-2 |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found | No evidence found |
| Memory | No evidence found | No evidence found |
| Disk | Ephemeral — stateless service; no persistent volumes required | — |

> Precise CPU and memory request/limit values are defined in `helm/values.yaml` and environment-specific override files.
