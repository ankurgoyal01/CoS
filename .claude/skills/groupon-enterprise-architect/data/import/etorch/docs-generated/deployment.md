---
service: "etorch"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

eTorch is deployed as two separately deployable units within the Continuum platform: `continuumEtorchApp` (the HTTP API server running on Jetty) and `continuumEtorchWorker` (the background job process running Quartz). Both are Java applications built with Maven and deployed on Continuum platform infrastructure.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Java / Jetty 9.4.51 | eTorch App embedded Jetty server |
| Worker runtime | Java / Quartz | eTorch Worker scheduler process |
| Build | Maven | Standard Maven lifecycle; produces deployable JAR/WAR artifacts |
| Load balancer | > No evidence found | Managed by Continuum platform infrastructure |
| CDN | > No evidence found | Not applicable for a merchant API |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | — | — |
| Staging | Pre-production validation | — | — |
| Production | Live merchant-facing extranet API | — | — |

> Environment-specific URLs are managed externally and not published in this repository.

## CI/CD Pipeline

- **Tool**: > No evidence found — managed by Continuum platform CI/CD conventions
- **Config**: > No evidence found in this repository
- **Trigger**: > Deployment procedures to be defined by service owner

### Pipeline Stages

1. Build: Maven compile, test, and package
2. Deploy App: Deploy `continuumEtorchApp` to target environment
3. Deploy Worker: Deploy `continuumEtorchWorker` to target environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | > No evidence found | Managed by Continuum platform |
| Memory | > No evidence found | Managed by Continuum platform |
| CPU | > No evidence found | Managed by Continuum platform |

## Resource Requirements

> Deployment configuration managed externally. Resource limits are defined in platform-level infrastructure configuration not visible in this repository.
