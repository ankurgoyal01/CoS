---
service: "booster"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "external-saas"
environments: []
---

# Deployment

## Overview

Booster is an external SaaS product operated entirely by Data Breakers. Groupon does not deploy, containerize, or orchestrate the Booster service. The `.service.yml` manifest explicitly declares `hosting_configured_via_ops_config: false` and `colos: none`, confirming that Booster has no Groupon-managed deployment infrastructure. The `status_endpoint` is also disabled.

The Groupon-owned integration boundary (`continuumBoosterService`) is a logical architecture representation only — it documents the integration contract, health monitoring approach, and operational runbook, but is not a separately deployed service.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Booster is an external SaaS; no Groupon-managed container |
| Orchestration | None | Vendor-managed; Groupon does not orchestrate Booster |
| Load balancer | Vendor-managed | Managed by Data Breakers |
| CDN | Vendor-managed | Managed by Data Breakers |

## Environments

> Deployment configuration managed externally. Booster environments (e.g., staging, production) are managed by Data Breakers. Groupon calling services reference Booster endpoints via their own environment-specific configuration.

## CI/CD Pipeline

> Not applicable. Booster is an external SaaS. There is no Groupon-owned CI/CD pipeline for building or deploying Booster.

### Pipeline Stages

> Not applicable.

## Scaling

> Not applicable. Scaling of the Booster service is managed entirely by the vendor (Data Breakers) according to the vendor agreement.

## Resource Requirements

> Not applicable. Booster is an external SaaS. Resource allocation is vendor-managed.
