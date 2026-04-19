---
service: "Deal-Estate"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "platform-managed"
environments: [development, staging, production]
---

# Deployment

## Overview

Deal-Estate is deployed as part of the Groupon Continuum platform. It runs four process types: a Unicorn web server (`continuumDealEstateWeb`), Resque background workers (`continuumDealEstateWorker`), a Resque Scheduler process (`continuumDealEstateScheduler`), and a Resque Web UI (`continuumDealEstateResqueWeb`). Deployment configuration is managed externally by the Continuum platform team.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Web server | Unicorn (Ruby) | Multi-process HTTP server; worker count configured via `UNICORN_WORKERS` env var |
| Background workers | Resque (Ruby) | Process count configured via `RESQUE_WORKER_COUNT` env var |
| Scheduler | Resque Scheduler | Single process; job definitions in `config/resque_schedule.yml` |
| Operations UI | Resque Web (Rack) | Internal Rack app for queue inspection |
| Container | Docker | Deployment packaging; Dockerfile path managed by platform team |
| Orchestration | Platform-managed | Continuum platform manages process supervision and scaling |
| Load balancer | Platform-managed | Fronts `continuumDealEstateWeb` Unicorn processes |
| CDN | none | Not applicable for internal API service |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and testing | local | http://localhost:3000 |
| staging | Pre-production validation | Groupon staging | Managed by platform team |
| production | Live commerce traffic | Groupon production | Managed by platform team |

## CI/CD Pipeline

- **Tool**: Managed by Continuum platform CI (details external to this repo)
- **Config**: Pipeline config managed externally
- **Trigger**: On merge to main branch; manual dispatch available

### Pipeline Stages

1. Test: Run RSpec and other test suites
2. Build: Package application and assets
3. Deploy staging: Push to staging environment
4. Deploy production: Push to production after staging validation

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (web) | Manual / platform-managed | Configured via `UNICORN_WORKERS` |
| Horizontal (workers) | Manual / platform-managed | Configured via `RESQUE_WORKER_COUNT` |
| Memory | Platform-managed | Limits defined by Continuum platform |
| CPU | Platform-managed | Limits defined by Continuum platform |

## Resource Requirements

> Deployment configuration managed externally. Consult the Continuum platform team for exact CPU, memory, and disk resource allocations per environment.
