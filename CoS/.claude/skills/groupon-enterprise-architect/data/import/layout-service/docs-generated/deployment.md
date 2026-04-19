---
service: "layout-service"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Layout Service is deployed as a Docker container orchestrated by Kubernetes, following the standard Continuum platform i-tier deployment model. It runs in multiple regions to serve Groupon's global frontend traffic with low latency. The Redis cache (`continuumLayoutTemplateCache`) is provisioned as a managed in-cluster or cloud-hosted Redis instance co-located per region.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile at service repository root; Node.js base image |
| Orchestration | Kubernetes | Helm chart manages Deployments, Services, ConfigMaps, and Secrets |
| Load balancer | i-tier / internal Kubernetes Service | Cluster-internal load balancing; external traffic enters via i-tier gateway |
| CDN | Akamai / CloudFront (external) | Static assets served via CDN; asset URLs resolved by `layoutSvc_assetResolver` at render time |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | Local / single region | Internal dev URL |
| Staging | Pre-production validation | Multi-region staging cluster | Internal staging URL |
| Production | Live consumer traffic | Multi-region (global) | Internal production — consumed via i-tier routing |

## CI/CD Pipeline

- **Tool**: GitHub Actions (standard Continuum platform pipeline)
- **Config**: `.github/workflows/` in the service repository
- **Trigger**: On push to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. **Build**: Install Node.js dependencies, run linters and unit tests
2. **Docker Build**: Build and tag Docker image
3. **Push**: Publish image to container registry
4. **Deploy to Staging**: Apply Helm chart to staging Kubernetes cluster
5. **Integration Tests**: Run smoke and integration tests against staging
6. **Deploy to Production**: Rolling deploy via Helm to production Kubernetes clusters across all regions

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA (Horizontal Pod Autoscaler) | Min/max replicas defined in Helm values per environment |
| Memory | Kubernetes resource limits | Defined in Helm values; specific values not evidenced in architecture inventory |
| CPU | Kubernetes resource limits | Defined in Helm values; specific values not evidenced in architecture inventory |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Defined in Helm chart | Defined in Helm chart |
| Memory | Defined in Helm chart | Defined in Helm chart |
| Disk | Ephemeral only | No persistent disk required |

> Deployment configuration managed in the service repository's Helm chart. Specific resource values and replica counts are maintained there and are not duplicated here.
