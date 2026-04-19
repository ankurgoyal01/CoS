---
service: "raas_c1"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: false
orchestration: "N/A"
environments: [production]
---

# Deployment

## Overview

RAAS C1 is not a deployable application and has no container, orchestration, or CI/CD pipeline of its own. It is a Service Portal registration entry created to satisfy an OCT tooling constraint (DATA-5855) that prevents two BASTIC tickets from being associated with one service. The C1 entry anchors routing and ticketing for Redis nodes in the snc1, sac1, and dub1 colocation facilities. The actual Redis node management is handled by the `raas` platform and `redislabs_config` service.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | none | No Dockerfile or container image — this is a Service Portal record |
| Orchestration | none | No Kubernetes, ECS, or other orchestrator |
| Load balancer | Internal BASTIC | Routing through internal base URLs registered in `.service.yml` |
| CDN | none | Internal infrastructure only |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| production (snc1) | C1 Redis nodes — US region | snc1 | `https://us.raas-bast-cs-prod.grpn:8443` (internal) |
| production (sac1) | C1 Redis nodes — US region | sac1 | `https://us.raas-bast-cs-prod.grpn:8443` (internal) |
| production (dub1) | C1 Redis nodes — EU region | dub1 | `https://dub1.raas-bast-cs-prod.grpn:8443` (internal) |

## Subservices

Two subservices are registered under this Service Portal entry:

| Subservice | Title | Description | Repository |
|------------|-------|-------------|-----------|
| `raas_c1::mon` | Monitoring Host | Monitors clusters and databases in the C1 colo | https://github.groupondev.com/data/raas |
| `raas_c1::redis` | Redis node | Node of a Redislabs Cluster | https://github.groupondev.com/data/redislabs_config |

## CI/CD Pipeline

> Not applicable — this Service Portal entry has no deployable code and no CI/CD pipeline.

### Pipeline Stages

> Not applicable.

## Scaling

> Not applicable — no deployable application exists for this entry.

## Resource Requirements

> Not applicable — this entry carries no runtime process.
