---
service: "ams"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

AMS is a Java 17 / Dropwizard JTier service deployed as a containerized workload within the Continuum platform. It runs as a long-lived server process exposing REST APIs and background scheduling. Deployment configuration is managed externally to this repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile managed in service repository |
| Orchestration | Kubernetes / JTier | Manifest paths managed externally |
| Load balancer | Platform-managed | Configured by Continuum platform team |
| CDN | Not applicable | Internal service, not CDN-fronted |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev | Development and integration testing | Not discoverable | Not discoverable |
| staging | Pre-production validation | Not discoverable | Not discoverable |
| production | Live audience management and compute | Not discoverable | Not discoverable |

> Deployment configuration managed externally. Contact the Audience Service / CRM team for environment-specific URLs and region details.

## CI/CD Pipeline

- **Tool**: Not discoverable from repository inventory
- **Config**: Managed in service repository
- **Trigger**: On-push to main branch; manual dispatch for production

### Pipeline Stages

1. Build: Compile Java 17 source with Maven, run unit tests
2. Package: Build Docker image
3. Migrate: Apply Flyway database migrations to target environment
4. Deploy: Roll out updated container to Kubernetes cluster
5. Verify: Execute health check against `/grpn/healthcheck`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Platform-managed auto-scaling | Not discoverable from inventory |
| Memory | JVM heap sizing via JVM flags | Not discoverable from inventory |
| CPU | Container resource limits | Not discoverable from inventory |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not discoverable | Not discoverable |
| Memory | Not discoverable | Not discoverable |
| Disk | Not discoverable | Not discoverable |

> Deployment configuration managed externally. Resource requests and limits are defined in platform deployment manifests.
