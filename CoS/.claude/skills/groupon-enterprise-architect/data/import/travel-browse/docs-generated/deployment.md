---
service: "travel-browse"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

travel-browse is containerised with Docker and orchestrated on Kubernetes using napistrano as the deployment tool. It is deployed across multiple regions to serve global Getaways traffic. Horizontal Pod Autoscaler (HPA) is configured with a maximum of 64 replicas to handle peak Getaways browse traffic. Static assets are served via `grouponCdn` rather than from the application pods.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Node.js 16 base image; application built with Webpack 5.40.0 |
| Orchestration | Kubernetes (napistrano) | Multi-region deployment; napistrano manages Helm chart lifecycle |
| Load balancer | Internal Kubernetes ingress / platform LB | Routes external browser traffic to pod replicas |
| CDN | `grouponCdn` | Serves static assets and images; caches HTML responses at edge |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | Local / single region | Internal / localhost |
| Staging | Pre-production validation | Multi-region (staging) | Internal staging URL |
| Production | Live consumer traffic | Multi-region | `www.groupon.com/travel/...` and `www.groupon.com/hotels/...` |

## CI/CD Pipeline

- **Tool**: napistrano (Groupon's internal Kubernetes deployment system)
- **Config**: Helm chart managed by napistrano; Docker image built in CI pipeline
- **Trigger**: On merge to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. **Build**: TypeScript compilation (`tsc`) and Webpack 5 bundle generation for client assets
2. **Test**: Unit and integration test execution
3. **Docker build**: Produces Docker image tagged with commit SHA
4. **Push**: Image pushed to Groupon internal container registry
5. **Deploy (staging)**: napistrano applies Helm chart to staging Kubernetes cluster
6. **Deploy (production)**: napistrano promotes image to production clusters across regions

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min: platform default; Max: 64 replicas |
| Memory | Kubernetes resource limits | Requests/limits set in Helm chart (specific values managed externally) |
| CPU | Kubernetes resource limits | Requests/limits set in Helm chart (specific values managed externally) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Managed via Helm chart | Managed via Helm chart |
| Memory | Managed via Helm chart | Managed via Helm chart |
| Disk | Ephemeral only | Not applicable |

> Specific CPU/memory request and limit values are managed in the napistrano Helm chart configuration external to this architecture model.
