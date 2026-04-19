---
service: "merchant-preview"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Merchant Preview is a Continuum platform service deployed as part of the Groupon commerce engine. It consists of two runtime components: the web application (`continuumMerchantPreviewService`) and a scheduled cron worker (`continuumMerchantPreviewCronWorker`). Public traffic is fronted by Akamai CDN. Deployment configuration is managed externally from this architecture model.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | > No evidence found in codebase for Dockerfile path |
| Orchestration | > No evidence found in codebase | Deployment configuration managed externally |
| Load balancer | Akamai CDN | Fronts public merchant preview traffic; internal access via internal gateway |
| CDN | Akamai | Routes external merchant preview requests to service backend |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development | — | > No evidence found in codebase |
| staging | Pre-production testing | — | > No evidence found in codebase |
| production | Live merchant traffic | — | > No evidence found in codebase |

## CI/CD Pipeline

- **Tool**: > No evidence found in codebase
- **Config**: > No evidence found in codebase
- **Trigger**: > No evidence found in codebase

### Pipeline Stages

> Deployment configuration managed externally. Pipeline stages are not defined in the architecture model.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | > No evidence found in codebase | — |
| Memory | > No evidence found in codebase | — |
| CPU | > No evidence found in codebase | — |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase | — |
| Memory | > No evidence found in codebase | — |
| Disk | > No evidence found in codebase | — |

> Deployment configuration managed externally. Contact the Continuum Platform team for infrastructure details.
