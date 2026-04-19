---
service: "itier-3pip"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

itier-3pip is containerized using a Docker image based on `alpine-node12` and deployed to Kubernetes via napistrano (Groupon's internal deployment tooling). The service runs in multiple regions with Kubernetes Horizontal Pod Autoscaler (HPA) configured to a maximum of 10 replicas. All environment-specific configuration is injected via Helm values at deploy time.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Alpine Linux + Node.js 12 base image (`alpine-node12`) |
| Orchestration | Kubernetes | Managed via napistrano; Helm chart defines replica counts, resource limits, and environment injection |
| Load balancer | Kubernetes Service / Ingress | Internal cluster ingress; upstream Akamai CDN assumed for external traffic |
| CDN | Akamai (assumed) | No direct evidence in architecture model; standard Groupon Continuum pattern |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local/CI development and integration testing | Local / single region | Not published |
| Staging | Pre-production validation and QA | Multi-region (assumed) | Internal staging URL |
| Production | Live consumer traffic | Multi-region | Embedded via iframe in Groupon deal pages |

## CI/CD Pipeline

- **Tool**: napistrano (Groupon internal deployment tooling)
- **Config**: Helm values file (managed externally by deployment tooling)
- **Trigger**: On merge to main / manual dispatch via napistrano

### Pipeline Stages

1. Build: Compile client-side assets with Webpack 4.44.1; produce Docker image on `alpine-node12`
2. Test: Run unit and integration tests via npm test scripts
3. Publish: Push Docker image to Groupon container registry
4. Deploy: napistrano applies Helm chart to target Kubernetes cluster and environment
5. Verify: Health check endpoint confirms pod readiness before traffic is routed

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min: not specified / Max: 10 replicas |
| Memory | Kubernetes resource limits | Values managed in Helm chart (not specified in architecture model) |
| CPU | Kubernetes resource limits | Values managed in Helm chart (not specified in architecture model) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not specified in architecture model | Not specified in architecture model |
| Memory | Not specified in architecture model | Not specified in architecture model |
| Disk | Ephemeral only (stateless) | Not applicable |

> Exact resource requests and limits are managed in the Helm chart via napistrano and are not exposed in the architecture DSL. Refer to the Helm values for the authoritative values.
