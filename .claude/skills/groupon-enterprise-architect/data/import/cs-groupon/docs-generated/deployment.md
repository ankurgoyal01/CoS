---
service: "cs-groupon"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "docker"
environments: [staging, production-snc1, production-sac1, production-dub1]
---

# Deployment

## Overview

cyclops is deployed as a Dockerized application on CentOS 7.5 base images. Deployments are managed via Capistrano. The service runs across three production datacenters (SNC1, SAC1, DUB1) for availability and geographic distribution. Each deployment starts Unicorn worker processes to serve the Rails application.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (CentOS 7.5) | Dockerfile in repository root; CentOS 7.5 base image |
| Orchestration | Capistrano | Capistrano deploy scripts manage release lifecycle (deploy, rollback, restart) |
| Web Server | Unicorn 4.3.1 | Multi-process HTTP server; worker count configurable via `UNICORN_WORKERS` |
| Load balancer | Internal load balancer / API Proxy (`apiProxy`) | Inbound traffic distributed across Unicorn workers |
| CDN | Not applicable | Internal CS tool; not publicly exposed |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production validation | — | Internal staging URL (not publicly documented) |
| Production SNC1 | Primary US production datacenter | SNC1 | Internal only |
| Production SAC1 | Secondary US production datacenter | SAC1 | Internal only |
| Production DUB1 | European production datacenter | DUB1 | Internal only |

## CI/CD Pipeline

- **Tool**: Capistrano (deployment automation)
- **Config**: `Capfile` / `config/deploy.rb` / `config/deploy/` directory
- **Trigger**: Manual deploy by GSO Engineering team; no evidence of automated deploy pipeline in inventory

### Pipeline Stages

1. Code checkout: Capistrano checks out the target revision to the release directory on target hosts
2. Bundle install: Installs gem dependencies via Bundler
3. Asset precompile: Compiles Rails assets for production
4. Database migrations: Runs pending ActiveRecord migrations against `continuumCsAppDb`
5. Symlink config: Links shared configuration files (database.yml, redis.yml, secrets)
6. Unicorn restart: Performs a graceful Unicorn worker restart to serve the new release
7. Cleanup: Removes old release directories beyond the configured keep count

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual — add/remove hosts per datacenter | Per-datacenter host pool; managed via Capistrano roles |
| Workers | Unicorn multi-process | Controlled by `UNICORN_WORKERS` environment variable |
| Memory | No evidence of automatic memory limits | Managed at OS / Docker level |
| CPU | No evidence of automatic CPU limits | Managed at OS / Docker level |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Operational procedures to be defined by service owner | — |
| Memory | Operational procedures to be defined by service owner | — |
| Disk | Operational procedures to be defined by service owner | — |

> Specific resource requests and limits are not enumerable from the DSL inventory. Deployment configuration is managed operationally by the GSO Engineering team.
