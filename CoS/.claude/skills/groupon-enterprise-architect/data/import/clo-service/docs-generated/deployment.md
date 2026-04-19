---
service: "clo-service"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

CLO Service is deployed as two containerized workloads within the Continuum platform: `continuumCloServiceApi` (the Rails/Puma HTTP server) and `continuumCloServiceWorker` (the Sidekiq background worker). Both run on JRuby 9.3.15.0 and share the same codebase but have different entry points and resource profiles. Deployment configuration is managed externally to this architecture repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | JRuby 9.3.15.0 base image; separate images or entry points for API and Worker |
| Orchestration | Kubernetes | Deployment manifests managed externally |
| Load balancer | Not evidenced | Deployment configuration managed externally |
| CDN | Not evidenced | Deployment configuration managed externally |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and integration testing | Local | localhost |
| staging | Pre-production validation and QA | Not evidenced | Not evidenced |
| production | Live card-linked offers processing | Not evidenced | Not evidenced |

## CI/CD Pipeline

- **Tool**: Not evidenced in architecture inventory
- **Config**: Deployment configuration managed externally
- **Trigger**: Not evidenced

### Pipeline Stages

> Deployment configuration managed externally. Pipeline stages are not evidenced in the architecture inventory.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| API horizontal | Kubernetes HPA or manual replica scaling | Not evidenced — managed externally |
| Worker horizontal | Sidekiq concurrency + pod replica scaling | `SIDEKIQ_CONCURRENCY` env var; pod count managed externally |
| Memory | Kubernetes resource limits | Managed externally |
| CPU | Kubernetes resource limits | Managed externally |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not evidenced | Not evidenced |
| Memory | Not evidenced — JRuby JVM heap sizing required | Not evidenced |
| Disk | Ephemeral only; no local persistent storage | Not applicable |

> Deployment configuration managed externally. Infrastructure and resource details are maintained in the Continuum platform deployment repository.
