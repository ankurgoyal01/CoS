---
service: "channel-manager-integrator-synxis"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

CMI SynXis is a JVM-based Dropwizard service deployed as part of the Continuum platform. It follows the standard JTier/Continuum deployment model. Specific Kubernetes manifests, Dockerfile paths, and CI/CD pipeline configuration are managed within the service repository and the Continuum platform deployment infrastructure.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (JVM) | Dockerfile and image configuration in service repository |
| Orchestration | Kubernetes (JTier/Continuum) | Deployment manifests managed by Continuum platform team |
| Load balancer | > No evidence found | Deployment configuration managed externally |
| CDN | Not applicable | Internal and partner-facing service; no CDN required |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local and integration development | — | > No evidence found |
| Staging | Pre-production validation and partner connectivity testing | — | > No evidence found |
| Production | Live ARI processing and hotel reservation management | — | > No evidence found |

> Exact environment URLs and regions are managed by the Continuum platform team and deployment configuration.

## CI/CD Pipeline

- **Tool**: > No evidence found in architecture model; standard Continuum CI/CD tooling applies
- **Config**: Refer to service repository for pipeline configuration
- **Trigger**: > Deployment configuration managed externally

### Pipeline Stages

> Deployment configuration managed externally. Typical JTier Continuum pipeline stages include: build (Maven), test, Docker image build, push to registry, deploy to staging, deploy to production.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | > No evidence found | Managed by Continuum platform |
| Memory | > No evidence found | Managed by Continuum platform |
| CPU | > No evidence found | Managed by Continuum platform |

## Resource Requirements

> Deployment configuration managed externally. Resource requests and limits are defined in Kubernetes manifests within the service repository or platform deployment configuration.
