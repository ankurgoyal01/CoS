---
service: "tronicon-ui"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "docker"
environments: [development, staging, production]
---

# Deployment

## Overview

Tronicon UI is containerized using a custom Docker image based on a `tronicon-ui` base image and served by Gunicorn as the WSGI server. Deployment is automated via Fabric scripts invoked by a Jenkins CI/CD pipeline. Frontend assets are compiled by Grunt before packaging. The service targets three environments: development, staging, and production.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Custom `tronicon-ui` base image; Gunicorn as entrypoint |
| Orchestration | Docker (host-level) | No Kubernetes or ECS evidence; container managed at VM/host level |
| Load balancer | No evidence found | Deployment configuration managed externally |
| CDN | No evidence found | Deployment configuration managed externally |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local developer environment | Local / internal | No evidence found |
| staging | Pre-production validation and QA | No evidence found | No evidence found |
| production | Live internal operator tool | No evidence found | No evidence found |

## CI/CD Pipeline

- **Tool**: Jenkins (with Fabric deployment scripts)
- **Config**: `deploy-config.js` (deployment targets), `fabfile.py` (Fabric tasks)
- **Trigger**: Manual dispatch via Jenkins; no automated on-push or on-PR pipeline evidence found

### Pipeline Stages

1. **Frontend Build**: Grunt compiles and bundles frontend JavaScript/CSS assets
2. **Docker Build**: Builds the `tronicon-ui` Docker image with compiled assets and Python dependencies
3. **Deploy**: Fabric (`fabfile.py`) executes deployment tasks — transfers image to target hosts and starts Gunicorn process
4. **Environment Config Injection**: Environment-specific `.env` file injected into the container at deploy time

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | No evidence found | Deployment configuration managed externally |
| Memory | No evidence found | Deployment configuration managed externally |
| CPU | No evidence found | Deployment configuration managed externally |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found | No evidence found |
| Memory | No evidence found | No evidence found |
| Disk | No evidence found | No evidence found |

> Deployment configuration beyond what is traceable from `deploy-config.js` and `fabfile.py` is managed externally by the Tronicon / Sparta team and Jenkins configuration.
