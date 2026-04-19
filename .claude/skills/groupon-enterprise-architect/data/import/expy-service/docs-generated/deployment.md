---
service: "expy-service"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

Expy Service is a JTier (Dropwizard) Java service deployed as part of the Continuum platform. It follows the standard Groupon JTier deployment model — containerized with Docker, orchestrated via Kubernetes, and deployed across dev, staging, and production environments. Deployment configuration details are managed externally to this architecture model.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard JTier Docker image — confirm Dockerfile path with Optimize team |
| Orchestration | Kubernetes | Standard Continuum k8s manifests — confirm manifest paths with Optimize team |
| Load balancer | Internal | JTier service mesh / internal load balancer — specific config not in architecture model |
| CDN | none | Internal service only; no public CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev | Development and integration testing | US | Internal |
| staging | Pre-production validation | US | Internal |
| production | Live traffic | US | Internal |

> Specific URLs and region assignments are managed in Groupon infrastructure configuration, not in this architecture model.

## CI/CD Pipeline

- **Tool**: Deployment configuration managed externally
- **Config**: Not defined in this architecture model — confirm with the Optimize team
- **Trigger**: Standard JTier CI/CD — on merge to main branch

### Pipeline Stages

1. Build: Maven compile and test
2. Package: Build Docker image with JTier base
3. Validate: Run unit and integration tests
4. Deploy to dev: Automated deployment on merge
5. Deploy to staging: Automated or gated promotion
6. Deploy to production: Gated promotion with approval

> Pipeline stage details are not defined in the architecture model. Confirm with the Optimize team.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min/max not defined in architecture model |
| Memory | JVM heap + container limit | Not defined in architecture model |
| CPU | Container request/limit | Not defined in architecture model |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not defined | Not defined |
| Memory | Not defined | Not defined |
| Disk | Minimal (stateless compute; data in MySQL and S3) | Not defined |

> Deployment configuration managed externally. Contact the Optimize team (optimize@groupon.com) for current resource limits and scaling configuration.
