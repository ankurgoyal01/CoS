---
service: "occasions-itier"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

occasions-itier is a Continuum platform web application deployed as a containerized Node.js service. It runs within the Groupon internal Kubernetes infrastructure alongside its Memcached sidecar (`continuumOccasionsMemcached`). Deployment configuration is managed externally to this service repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Node.js 16.x base image; built from service Dockerfile |
| Orchestration | Kubernetes | Deployment manifests managed in infrastructure repo |
| Load balancer | Internal LB / Akamai | Traffic routed via Continuum API proxy layer |
| CDN | Akamai | Edge caching for static assets; HTML pages served from origin |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and unit testing | Local / dev cluster | localhost:3000 |
| Staging | Integration testing and QA | US / internal | Internal staging URL |
| Production | Live customer traffic | US (primary) | groupon.com/occasions |

## CI/CD Pipeline

- **Tool**: Internal Groupon CI (Jenkins or GitHub Actions)
- **Config**: Deployment configuration managed externally
- **Trigger**: On merge to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. Install: Installs npm dependencies
2. Build: Runs webpack to bundle client-side assets
3. Test: Executes unit and integration test suites
4. Docker Build: Builds and tags Docker image
5. Deploy to Staging: Deploys image to staging Kubernetes namespace
6. Smoke Test: Validates key endpoints respond correctly in staging
7. Deploy to Production: Promotes image to production Kubernetes namespace

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Auto-scaling (HPA) | Managed externally; min/max replica counts in infrastructure repo |
| Memory | Kubernetes resource limits | Managed externally |
| CPU | Kubernetes resource limits | Managed externally |

## Resource Requirements

> Deployment configuration managed externally. Specific CPU, memory, and disk allocations are defined in Kubernetes manifests outside this service repository.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found in codebase | No evidence found in codebase |
| Memory | No evidence found in codebase | No evidence found in codebase |
| Disk | Ephemeral only | No evidence found in codebase |
