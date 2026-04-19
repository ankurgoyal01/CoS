---
service: "zendesk"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "saas"
environments: [production]
---

# Deployment

## Overview

Zendesk is a fully managed SaaS platform hosted and operated by Zendesk, Inc. Groupon has no infrastructure ownership, deployment pipeline, or container configuration for Zendesk itself. Deployment and infrastructure management are handled entirely by Zendesk. Groupon's responsibility is limited to integration configuration and API credential management, performed by the GSS team.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | SaaS — no Groupon-managed containers |
| Orchestration | SaaS (Zendesk hosted) | Managed entirely by Zendesk |
| Load balancer | Zendesk managed | Not configurable by Groupon |
| CDN | Zendesk managed | Not configurable by Groupon |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production | Live customer support operations | Zendesk managed | Managed by Zendesk SaaS |

> No evidence found in codebase of a staging or development Zendesk environment. Groupon may maintain a sandbox Zendesk instance for testing — check with the GSS team.

## CI/CD Pipeline

> No evidence found in codebase. There is no Groupon-owned CI/CD pipeline for Zendesk. The `.service.yml` declares `branch: master` but no pipeline configuration files are present in the repository.

### Pipeline Stages

> Not applicable. Deployment configuration managed externally by Zendesk SaaS.

## Scaling

> Not applicable. Scaling is managed entirely by Zendesk SaaS infrastructure. Groupon has no scaling configuration.

## Resource Requirements

> Not applicable. Resource management is handled by Zendesk SaaS. Groupon does not configure CPU, memory, or disk for this service.
