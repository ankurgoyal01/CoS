---
service: "consumer-data"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: false
orchestration: "vm"
environments: [development, staging, production]
---

# Deployment

## Overview

Consumer Data Service is deployed on the Continuum platform using Capistrano for deployment automation. The runtime is Puma serving the Sinatra app over Rack. No evidence of containerisation was found; deployment targets are likely VM-based hosts consistent with legacy Continuum service patterns.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None (not containerised) | No Dockerfile evidence found |
| Orchestration | VM / Capistrano | Capistrano 3.16.0 manages deploys to target hosts |
| Load balancer | No evidence found | Deployment configuration managed externally |
| CDN | No evidence found | Deployment configuration managed externally |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development | local | http://localhost:9292 |
| staging | Pre-production verification | No evidence found | No evidence found |
| production | Live consumer-facing traffic | No evidence found | No evidence found |

## CI/CD Pipeline

- **Tool**: Capistrano 3.16.0
- **Config**: `Capfile` / `config/deploy.rb` (Capistrano convention)
- **Trigger**: Manual deploy via Capistrano CLI or CI integration

### Pipeline Stages

1. Code checkout: Capistrano checks out the target revision to the deploy path on each host
2. Bundle install: Installs Ruby gem dependencies via Bundler
3. Database migration: Runs pending ActiveRecord migrations
4. Restart: Restarts Puma server workers on target hosts

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual | Capistrano deploy to additional hosts |
| Memory | No evidence found | Deployment configuration managed externally |
| CPU | No evidence found | Deployment configuration managed externally |

## Resource Requirements

> Deployment configuration managed externally.
