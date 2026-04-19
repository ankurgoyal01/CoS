---
service: "ultron-ui"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

Ultron UI is packaged as a Docker image based on `openjdk:8` and deployed to Kubernetes clusters via Deploybot. Two environments are operated: staging (us-west-2) and production (us-west-2 and us-central1). The Play Framework application starts on an HTTP port within the container; Kubernetes handles load balancing and service discovery.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `openjdk:8` base image; Play app packaged as a fat JAR or dist archive |
| Orchestration | Kubernetes | Deploybot-managed; Helm chart supplies environment-specific values |
| Load balancer | Kubernetes Service / Ingress | Internal k8s routing; external ingress not detailed in inventory |
| CDN | None | No evidence found for a CDN in front of this service |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production validation | us-west-2 | Internal — not published in inventory |
| Production | Live operator traffic | us-west-2 | Internal — not published in inventory |
| Production | Live operator traffic (secondary) | us-central1 | Internal — not published in inventory |

## CI/CD Pipeline

- **Tool**: Deploybot
- **Config**: Deployment configuration managed externally via Deploybot and Helm chart values
- **Trigger**: On-push to main / manual dispatch via Deploybot

### Pipeline Stages

1. **Build**: SBT compiles the Play application and produces a distributable artifact
2. **Dockerize**: Docker image built on `openjdk:8`, application artifact copied in
3. **Push**: Image pushed to internal container registry
4. **Deploy to Staging**: Deploybot applies Helm chart to staging Kubernetes cluster (us-west-2)
5. **Deploy to Production**: Deploybot applies Helm chart to production Kubernetes clusters (us-west-2, us-central1)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA or manual replica count via Deploybot | Specific min/max not detailed in inventory |
| Memory | Kubernetes resource limits | Specific values not detailed in inventory |
| CPU | Kubernetes resource limits | Specific values not detailed in inventory |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not detailed in inventory | Not detailed in inventory |
| Memory | Not detailed in inventory | Not detailed in inventory |
| Disk | Ephemeral only — no persistent volumes required | Not applicable |

> Specific resource request/limit values are managed externally in Helm chart configuration.
