---
service: "command-center"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

> Deployment configuration managed externally. Specific Dockerfile paths, Kubernetes manifests, and CI/CD pipeline configuration are not enumerated in the architecture DSL. The following reflects what is inferrable from the Continuum platform conventions and the three-container architecture model.

Command Center is deployed as two runtime processes — the web server (`continuumCommandCenterWeb`) and the background worker (`continuumCommandCenterWorker`) — backed by a shared MySQL database (`continuumCommandCenterMysql`). Both processes share the same application codebase but are started with different entry points (Rails server vs. Delayed Job worker process).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile path not enumerated in architecture inventory |
| Orchestration | Kubernetes (inferred from Continuum platform) | Manifest paths not enumerated in architecture inventory |
| Load balancer | Not enumerated | Internal-only service; load balancing details not in architecture inventory |
| CDN | Not applicable | Internal tool, no CDN required |
| Object storage | S3 (cloudPlatform) | Used for CSV/job report artifact storage |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development | Local | Not applicable |
| staging | Pre-production validation | Not enumerated | Not enumerated |
| production | Live internal operations | Not enumerated | Not enumerated |

## CI/CD Pipeline

- **Tool**: Not enumerated in the architecture inventory
- **Config**: Not enumerated in the architecture inventory
- **Trigger**: Not enumerated in the architecture inventory

### Pipeline Stages

> Deployment configuration managed externally. Pipeline stages are not enumerated in the architecture inventory.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Web horizontal | Not enumerated | Not enumerated |
| Worker horizontal | Controlled by `DELAYED_JOB_WORKERS` environment variable | Number of worker processes |
| Memory | Not enumerated | Not enumerated |
| CPU | Not enumerated | Not enumerated |

> Scaling configuration is managed in deployment manifests external to the architecture inventory.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not enumerated | Not enumerated |
| Memory | Not enumerated | Not enumerated |
| Disk | Not enumerated | Not enumerated |

> Deployment configuration managed externally. Resource requirements are defined in Kubernetes manifests in the command-center application repository.
