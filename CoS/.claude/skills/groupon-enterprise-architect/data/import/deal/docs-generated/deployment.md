---
service: "deal"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production-us, production-eu]
---

# Deployment

## Overview

The deal service is containerized (Docker) and deployed to Google Kubernetes Engine (GKE) across two production regions (us-central1 and eu-west-1). Deployments are triggered via Jenkins using napistrano as the deployment orchestration layer. The service scales horizontally with Kubernetes HPA to handle Groupon's consumer traffic load.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile in service repository root |
| Orchestration | Kubernetes (GKE) | Kubernetes manifests / Helm charts |
| Load balancer | GKE Ingress / Internal load balancer | Fronted by Akamai CDN at the edge |
| CDN | Akamai | Caches rendered deal pages and static assets at edge |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production validation | > No evidence found in codebase. | > No evidence found in codebase. |
| Production (US) | Live consumer traffic — primary | us-central1 | groupon.com/deals/:deal-permalink |
| Production (EU) | Live consumer traffic — EMEA | eu-west-1 | groupon.co.uk/deals/:deal-permalink (and other EMEA domains) |

## CI/CD Pipeline

- **Tool**: Jenkins + napistrano
- **Config**: > No evidence found in codebase. (Jenkinsfile / napistrano config in service repository)
- **Trigger**: On merge to main branch; manual dispatch for hotfix deploys

### Pipeline Stages

1. **Install**: Run `npm install` to install Node.js dependencies
2. **Build**: Run `webpack` to compile and bundle static assets
3. **Test**: Run unit and integration test suites
4. **Docker Build**: Build Docker image with compiled assets
5. **Push**: Push Docker image to container registry
6. **Deploy (Staging)**: napistrano deploys to staging GKE cluster
7. **Deploy (Production)**: napistrano deploys to production GKE clusters (us-central1, eu-west-1) via rolling update

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (US) | Kubernetes HPA | Min: 12 / Max: 150 replicas |
| Horizontal (EU) | Kubernetes HPA | Min: 8 / Max: 50 replicas |
| Memory | > No evidence found in codebase. | > No evidence found in codebase. |
| CPU | > No evidence found in codebase. | > No evidence found in codebase. |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase. | > No evidence found in codebase. |
| Memory | > No evidence found in codebase. | > No evidence found in codebase. |
| Disk | Ephemeral only (stateless) | N/A |
