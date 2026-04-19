---
service: "sub_center"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

sub_center is deployed as a containerized Node.js I-Tier web application on the Continuum platform. Deployment follows standard Continuum I-Tier patterns: the service runs in Docker containers orchestrated by Kubernetes. Deployment configuration is managed externally to this architecture module.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Inferred from Continuum I-Tier standard; Dockerfile in service source repository |
| Orchestration | Kubernetes | Inferred from Continuum platform standard |
| Load balancer | Akamai / internal LB | Inferred from Continuum I-Tier traffic routing |
| CDN | Not applicable | Server-rendered pages, not static assets |

> Deployment configuration managed externally. Infrastructure details are not present in the federated architecture module. Verify Dockerfile, Helm charts, and pipeline config in the service source repository.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local / developer testing | local | localhost |
| staging | Integration testing and QA | US-East (inferred) | Internal staging URL |
| production | Live user traffic | US-East / US-West (inferred) | groupon.com/subscription-center |

## CI/CD Pipeline

- **Tool**: Jenkins (inferred from Continuum platform standard)
- **Config**: Managed in the service source repository
- **Trigger**: On push to main branch; manual dispatch for production deploys

### Pipeline Stages

1. Build: Compile and package the Node.js application
2. Test: Run unit and integration tests
3. Docker Build: Build and tag container image
4. Deploy to Staging: Push to Kubernetes staging namespace
5. Deploy to Production: Gated production rollout

> Pipeline stages are inferred from standard Continuum I-Tier deployment patterns. Verify against the service source repository CI configuration.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Auto-scaling (HPA) | Min/max replicas managed by Kubernetes HPA |
| Memory | Kubernetes limits | Defined in Helm values in service source repo |
| CPU | Kubernetes limits | Defined in Helm values in service source repo |

## Resource Requirements

> No evidence found in codebase. Resource requests and limits are defined in Kubernetes / Helm configuration in the service source repository.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not specified | Not specified |
| Memory | Not specified | Not specified |
| Disk | Not specified | Not specified |
