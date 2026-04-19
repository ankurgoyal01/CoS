---
service: "keboola"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "managed-saas"
environments: [production]
---

# Deployment

## Overview

Keboola Connection is a fully managed, single-tenant SaaS platform deployed on GCP by the Keboola vendor team. Groupon has no deployment responsibility for the Keboola runtime itself. No Dockerfiles, Kubernetes manifests, Helm charts, or CI/CD pipeline configurations exist in this repository. Groupon's role is limited to configuring and managing pipeline components (connectors, transformations, orchestration schedules) within the Keboola web UI.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Not applicable | No Dockerfile — managed SaaS |
| Orchestration | Managed by Keboola vendor on GCP | Single-tenant GCP environment (`OWNERS_MANUAL.md`) |
| Load balancer | Managed by Keboola vendor | Not applicable to Groupon |
| CDN | Not applicable | No web-facing Groupon endpoint |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production | Live data integration and analytics pipeline execution | GCP (region managed by Keboola) | https://help.keboola.com/ (platform docs) |

## CI/CD Pipeline

> No evidence found in codebase. No CI/CD pipeline configuration is present in this repository. Keboola service is owned and maintained by the Keboola team — no action is needed from Groupon to deploy the service (`OWNERS_MANUAL.md`).

### Pipeline Stages

> Not applicable. Deployment configuration managed externally by the Keboola vendor.

## Scaling

> Not applicable. Scaling is managed entirely by the Keboola vendor as part of the managed SaaS offering. Groupon does not configure horizontal scaling, memory limits, or CPU limits for this service.

## Resource Requirements

> Not applicable. Resource allocation is managed by the Keboola vendor on single-tenant GCP infrastructure.
