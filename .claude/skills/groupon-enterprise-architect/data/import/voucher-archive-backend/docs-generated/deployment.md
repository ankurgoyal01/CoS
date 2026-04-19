---
service: "voucher-archive-backend"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "No evidence found in codebase."
environments: [development, staging, production]
---

# Deployment

## Overview

The voucher-archive-backend is a Continuum platform Rails service deployed as a containerized application. It runs on Puma as its application server. Deployment follows the standard Continuum deployment pipeline. Specific orchestration details (Kubernetes, ECS) are not discoverable from the service repository inventory.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | > No Dockerfile path evidence found in codebase. |
| Orchestration | > No evidence found in codebase. | Deployment configuration managed externally. |
| Load balancer | > No evidence found in codebase. | Deployment configuration managed externally. |
| CDN | None | Internal API service; no CDN required. |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development | local | http://localhost:3000 |
| staging | Pre-production testing and integration | > No evidence found in codebase. | > No evidence found in codebase. |
| production | Live traffic serving consumer, merchant, and CSR requests | > No evidence found in codebase. | > No evidence found in codebase. |

## CI/CD Pipeline

- **Tool**: > No evidence found in codebase.
- **Config**: > No pipeline config path discoverable from inventory.
- **Trigger**: > No evidence found in codebase.

### Pipeline Stages

1. **Test**: Run RSpec test suite via `rspec-rails`
2. **Build**: Bundle gems and build Docker image
3. **Deploy**: Push image to registry and deploy to target environment

> Detailed pipeline stages are not discoverable from the service inventory. Deployment configuration managed externally.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | > No evidence found in codebase. | > No evidence found in codebase. |
| Memory | > No evidence found in codebase. | > No evidence found in codebase. |
| CPU | > No evidence found in codebase. | > No evidence found in codebase. |

Puma is configured to use multiple threads and workers, providing intra-instance concurrency. The `config/puma.rb` file governs thread/worker counts.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase. | > No evidence found in codebase. |
| Memory | > No evidence found in codebase. | > No evidence found in codebase. |
| Disk | > No evidence found in codebase. | > No evidence found in codebase. |

> Deployment configuration managed externally.
