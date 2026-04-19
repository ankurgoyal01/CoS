---
service: "invoice_management"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

invoice_management is a Java 8 Play Framework service deployed as a containerised application on the Continuum platform. It follows the standard Continuum Skeletor deployment pattern: Docker-packaged, orchestrated via Kubernetes. The service runs alongside a dedicated PostgreSQL instance (`continuumInvoiceManagementPostgres`) which is provisioned and managed separately by the platform team.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | JVM 8+ base image; application packaged as a Play distribution (`sbt dist`) |
| Orchestration | Kubernetes | Continuum cluster; manifests managed by platform/Goods team |
| Load balancer | Internal Kubernetes service | Internal cluster routing; not publicly exposed |
| CDN | None | Backend service; no CDN required |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local developer testing | Local | http://localhost:9000 (Play default) |
| staging | Pre-production validation with NetSuite sandbox | > No evidence found in codebase. | > No evidence found in codebase. |
| production | Live Goods invoicing and payments | > No evidence found in codebase. | > No evidence found in codebase. |

## CI/CD Pipeline

- **Tool**: > No evidence found in codebase. Standard Continuum CI/CD pipeline assumed.
- **Config**: > No evidence found in codebase.
- **Trigger**: on-push to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. **Compile**: Runs `sbt compile` to compile Java sources
2. **Test**: Runs `sbt test` for unit and integration tests
3. **Package**: Runs `sbt dist` to produce the Play distribution zip
4. **Docker build**: Packages the distribution into a Docker image
5. **Push**: Pushes Docker image to Continuum container registry
6. **Deploy**: Deploys new image to Kubernetes for the target environment
7. **Verify**: Health check on `/health` or `/status` to confirm successful startup

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | auto-scaling (HPA) | > No evidence found in codebase. Quartz scheduler must be configured for single-node execution to avoid duplicate job runs. |
| Memory | Kubernetes resource limits | JVM heap sizing via `JAVA_OPTS` (-Xms / -Xmx) |
| CPU | Kubernetes resource limits | > No evidence found in codebase. |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase. | > No evidence found in codebase. |
| Memory | > No evidence found in codebase. JVM heap + Play overhead; typically 512MB–2GB | > No evidence found in codebase. |
| Disk | Ephemeral only | Ephemeral only |

> Deployment configuration managed externally by the Continuum platform team. Kubernetes manifests are not stored in the invoice_management repository. Note: Quartz scheduler jobs should be pinned to a single replica to avoid duplicate invoice transmissions and payment pulls.
