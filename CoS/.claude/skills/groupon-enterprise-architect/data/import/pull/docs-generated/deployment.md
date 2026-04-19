---
service: "pull"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Pull is deployed as a containerized Node.js I-Tier application following the standard Groupon Continuum I-Tier deployment model. The application runs on Node.js 16 inside a Docker container and is orchestrated on the Groupon platform infrastructure. Deployment configuration is managed externally to this service's repository, following the I-Tier platform conventions shared across Continuum services.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Containerized Node.js 16 application |
| Orchestration | Kubernetes (I-Tier platform) | Managed by the Continuum I-Tier platform |
| Load balancer | Platform-managed | Traffic routing handled by I-Tier infrastructure |
| CDN | Platform-managed (Akamai) | Edge caching and routing for groupon.com |

> Deployment configuration managed externally. Specific Dockerfile paths, Kubernetes manifests, and resource limit values are not present in the service DSL inventory. Consult the I-Tier platform team or the service's CI/CD pipeline configuration for exact infrastructure details.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | Local | — |
| Staging | Pre-production validation | US (platform-managed) | — |
| Production | Live consumer traffic for groupon.com discovery pages | US (primary) | groupon.com/ |

## CI/CD Pipeline

- **Tool**: Platform CI (standard I-Tier pipeline)
- **Config**: Managed externally by the Continuum I-Tier platform
- **Trigger**: On push to main branch; pull request validation

### Pipeline Stages

1. Install: Resolve npm dependencies
2. Build: Webpack 5 server and client bundle compilation
3. Test: Unit and integration test execution
4. Package: Docker image build and push
5. Deploy: Rolling deployment to target environment via I-Tier platform

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Platform auto-scaling (I-Tier) | Managed by platform — min/max not discoverable from service inventory |
| Memory | Platform-managed limits | Not discoverable from service inventory |
| CPU | Platform-managed limits | Not discoverable from service inventory |

## Resource Requirements

> Deployment configuration managed externally. Resource requests and limits are defined in the I-Tier platform deployment manifests, not within this service's DSL inventory.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Platform-managed | Platform-managed |
| Memory | Platform-managed | Platform-managed |
| Disk | Stateless — ephemeral only | — |
