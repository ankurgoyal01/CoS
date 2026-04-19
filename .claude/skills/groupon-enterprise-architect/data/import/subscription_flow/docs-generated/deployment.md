---
service: "subscription_flow"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Subscription Flow is deployed as a containerized Node.js service on Kubernetes. The Docker image packages the Node.js application (built via npm) and is managed through a Jenkins CI/CD pipeline. Being stateless with no databases or queues, deployment is straightforward — pods are interchangeable and can be scaled horizontally without coordination.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` in repository root |
| Orchestration | Kubernetes | Helm chart; single Deployment for the Node.js web service |
| Load balancer | Kubernetes Ingress / internal load balancer | Routes web client requests to subscription_flow pods |
| CDN | none | Internal i-tier service; no CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development | local | localhost |
| staging | Pre-production integration testing | — | Internal staging URL |
| production | Live subscription modal serving | — | Internal production URL |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (repository root)
- **Trigger**: On push to main branch; manual dispatch for production promotion

### Pipeline Stages

1. **Install**: Installs npm dependencies (`npm install`)
2. **Build**: Compiles CoffeeScript to JavaScript (`npm run build`)
3. **Test**: Runs unit and integration tests (`npm test`)
4. **Lint**: Runs linting checks
5. **Push**: Builds Docker image and pushes to container registry
6. **Deploy Staging**: Deploys to staging Kubernetes namespace via Helm
7. **Smoke Test**: Verifies modal rendering endpoint responds in staging
8. **Deploy Production**: Promotes image to production Kubernetes namespace via Helm after approval

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Scales based on CPU utilisation; min/max replicas in Helm values |
| Memory | Kubernetes resource limits | Managed in Helm values |
| CPU | Kubernetes resource limits | Managed in Helm values |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase | > No evidence found in codebase |
| Memory | > No evidence found in codebase | > No evidence found in codebase |
| Disk | ephemeral only | — |

> Exact resource request/limit values are managed in Helm values files outside this repository. Deployment configuration managed externally for precise resource sizing.
