---
service: "checkout-reloaded"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

checkout-reloaded is packaged as a Docker container built on `alpine-node20.19.5` and deployed to Kubernetes via Groupon's Conveyor/Krane deployment toolchain. The service runs in multiple regions for production availability. Scaling is handled automatically via Kubernetes HPA.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Base image: `alpine-node20.19.5`; Node.js 20.19.6 runtime |
| Orchestration | Kubernetes (Conveyor/Krane) | Managed via Groupon's internal Conveyor deployment platform |
| Load balancer | > No evidence found in codebase. | Managed externally by the Conveyor/Krane platform |
| CDN | > No evidence found in codebase. | Edge/CDN configuration managed externally |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and feature iteration | local | http://localhost:3000 |
| staging | Pre-production validation and QA | > No evidence found in codebase. | > No evidence found in codebase. |
| production | Live consumer traffic | snc1, sac1, dub1 (on-prem) + cloud | > No evidence found in codebase. |

## CI/CD Pipeline

- **Tool**: > No evidence found in codebase. (Groupon's Conveyor/Krane platform is referenced; specific CI tool not documented in inventory)
- **Config**: > No evidence found in codebase.
- **Trigger**: > No evidence found in codebase.

### Pipeline Stages

> No evidence found in codebase. Pipeline stage details are managed by the Conveyor/Krane platform and not documented in the service inventory.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Kubernetes Horizontal Pod Autoscaler) | Min: 2 replicas, Max: 10 replicas, Target CPU: 70% |
| Memory | > No evidence found in codebase. | `NODE_OPTIONS=--max-old-space-size=...` tunable via env var |
| CPU | > No evidence found in codebase. | `UV_THREADPOOL_SIZE` tunable via env var |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase. | > No evidence found in codebase. |
| Memory | > No evidence found in codebase. | > No evidence found in codebase. |
| Disk | > No evidence found in codebase. | > No evidence found in codebase. |

> Deployment configuration (resource requests/limits, manifest paths) is managed externally via the Conveyor/Krane platform. Contact the SRE or Checkout team for current production values.
