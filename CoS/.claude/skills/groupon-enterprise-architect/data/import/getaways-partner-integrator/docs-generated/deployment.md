---
service: "getaways-partner-integrator"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

Getaways Partner Integrator is containerized using a JTier Java 11 base image and orchestrated via Kubernetes. The service is deployed in three distinct per-partner variants — `aps`, `siteminder`, and `travelgatex` — each as a separate Kubernetes deployment with partner-specific configuration. This deployment model isolates partner traffic and allows independent scaling and rollout per channel manager.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (JTier Java 11) | JTier-managed base image providing Java 11 runtime, JVM tuning, and platform tooling |
| Orchestration | Kubernetes | Per-partner deployment manifests (aps, siteminder, travelgatex variants) |
| Load balancer | Internal Kubernetes service / JTier ingress | SOAP inbound endpoints exposed per-variant; REST API on internal cluster network |
| CDN | None | Not applicable — service is internal and partner-facing, not consumer-facing |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev | Development and integration testing | Internal | Managed by JTier platform |
| staging | Pre-production validation with partner sandbox endpoints | Internal | Managed by JTier platform |
| production | Live channel manager integrations | Internal | Managed by JTier platform |

## CI/CD Pipeline

- **Tool**: Jenkins / JTier standard pipeline (Groupon internal CI)
- **Config**: Standard JTier Maven build pipeline
- **Trigger**: On merge to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. **Build**: Maven compile and package — produces service JAR
2. **Test**: Maven unit and integration tests
3. **Docker Build**: Assembles JTier Java 11 Docker image with service JAR
4. **Push**: Publishes Docker image to Groupon internal container registry
5. **Deploy (per variant)**: Applies Kubernetes manifests for aps, siteminder, and travelgatex deployments sequentially through dev → staging → production

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual or Kubernetes HPA per variant | Separate replica counts per partner variant deployment |
| Memory | Kubernetes resource limits | JTier Java 11 JVM heap configured per variant |
| CPU | Kubernetes resource limits | Per-variant resource requests and limits |

## Resource Requirements

> Deployment configuration managed externally by JTier platform Helm charts. Contact the Travel team for current resource request/limit values per variant.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Managed by JTier Helm | Managed by JTier Helm |
| Memory | Managed by JTier Helm | Managed by JTier Helm |
| Disk | Stateless (no local disk) | N/A |
