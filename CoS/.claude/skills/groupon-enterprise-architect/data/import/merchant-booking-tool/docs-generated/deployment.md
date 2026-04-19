---
service: "merchant-booking-tool"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "I-tier platform"
environments: [development, staging, production]
---

# Deployment

## Overview

The Merchant Booking Tool is deployed as part of the Continuum Platform's I-tier Node.js application hosting infrastructure. It follows the standard I-tier deployment model for web applications. The service is containerized and deployed within Groupon's internal infrastructure. Specific Dockerfile paths, Kubernetes manifests, and CI/CD pipeline configuration files are not visible in the federated architecture DSL; deployment details are managed externally per I-tier platform conventions.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (I-tier standard) | Standard I-tier Node.js container image |
| Orchestration | I-tier platform (internal) | Managed by Continuum Platform infrastructure |
| Load balancer | I-tier platform (internal) | Managed by Continuum Platform infrastructure |
| CDN | I-tier platform (internal) | Standard Groupon CDN configuration |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local/integration development and testing | — | Internal dev |
| Staging | Pre-production validation | — | Internal staging |
| Production | Live merchant traffic | — | groupon.com merchant booking paths |

## CI/CD Pipeline

- **Tool**: Internal Groupon CI/CD (I-tier standard)
- **Config**: Deployment configuration managed externally per I-tier platform conventions
- **Trigger**: Standard I-tier deploy pipeline triggers (on-push to main/develop branch)

### Pipeline Stages

1. Build: Compile and bundle Node.js / Preact application
2. Test: Run unit and integration tests
3. Package: Create deployable container image
4. Deploy to staging: Push to staging I-tier environment
5. Deploy to production: Promote to production I-tier environment

## Scaling

> Deployment configuration managed externally. Scaling follows I-tier platform standard horizontal scaling policies.

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | I-tier platform auto-scaling | Managed by Continuum Platform infrastructure |
| Memory | I-tier platform defaults | Managed externally |
| CPU | I-tier platform defaults | Managed externally |

## Resource Requirements

> Deployment configuration managed externally. Resource limits follow I-tier Node.js application standards.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | I-tier default | I-tier default |
| Memory | I-tier default | I-tier default |
| Disk | Stateless — minimal | Stateless — minimal |
