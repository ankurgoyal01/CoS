---
service: "pingdom"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "Not applicable"
environments: ["production"]
---

# Deployment

## Overview

> Deployment configuration managed externally. The Pingdom entry is a service metadata and SRE operational endpoint with no deployable application artifact of its own. It is registered as part of the Continuum Platform's federated architecture model and has no Docker image, Kubernetes manifest, or CI/CD pipeline.

The `tdo-team` pingdom-shift-report cron job — which consumes the Pingdom API on behalf of this registration — is deployed as a Kubernetes CronJob within the `tdo-team` application image (`docker-conveyor.groupondev.com/tdo/tdo-team`). Its deployment details are documented under the `tdo-team` service.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Not applicable | No Dockerfile exists in this repository |
| Orchestration | Not applicable | No Kubernetes or ECS manifests exist in this repository |
| Load balancer | Not applicable | No inbound traffic is served |
| CDN | Not applicable | No web assets are served |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production | Live Pingdom monitoring integration | Global | `https://status.pingdom.com/` (external status page) |

## CI/CD Pipeline

> No evidence found in codebase. No pipeline configuration file exists in this repository. The service metadata is updated by modifying `.service.yml` and is synced to the central architecture model via the daily federation pull workflow in the `architecture` repository.

### Pipeline Stages

> Not applicable.

## Scaling

> Not applicable. No application runtime exists to scale.

## Resource Requirements

> Not applicable. No application runtime exists.

### Consuming Service Resources (tdo-team pingdom-shift-report cron)

For operational reference, the `tdo-team` pingdom-shift-report Kubernetes CronJob is configured with:

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 300m | Not set |
| Memory | 500Mi | 500Mi |

- `activeDeadlineSeconds`: 1500 seconds (25 minutes max runtime per job run)
- `startingDeadlineSeconds`: 60 seconds
