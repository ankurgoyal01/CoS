---
service: "glive-gia"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

GIA is deployed as a containerized Ruby on Rails application running under Unicorn as the web server. Two distinct process types are deployed: the web app (`continuumGliveGiaWebApp`) handling HTTP requests, and the background worker (`continuumGliveGiaWorker`) running Resque job processors. Both share the same MySQL database and Redis instance. Detailed infrastructure configuration (Kubernetes manifests, Helm values) is managed externally to this repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile expected in repo root; Ruby 2.5.9 base image |
| Orchestration | Kubernetes | Manifest paths managed externally |
| Web server | Unicorn | Multi-process Ruby HTTP server; worker count configured via `UNICORN_WORKERS` / `config/unicorn.rb` |
| Load balancer | Internal LB / Ingress | Groupon-standard Kubernetes ingress; specific config managed externally |
| CDN | Not applicable | Internal admin tool; no CDN layer |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and feature testing | Local | `http://localhost:3000` |
| Staging | Integration testing with external system sandboxes | Groupon US staging | Internal URL — managed externally |
| Production | Live operations for GrouponLive supply team | Groupon US production | Internal URL — managed externally |

## CI/CD Pipeline

- **Tool**: CI/CD pipeline managed externally (Groupon standard pipeline)
- **Config**: Pipeline configuration not present in this repository
- **Trigger**: On push to main branch / pull request

### Pipeline Stages

1. **Test**: Runs Rails test suite and RSpec specs
2. **Build**: Builds Docker image with Ruby 2.5.9 and bundled dependencies
3. **Push**: Pushes image to internal container registry
4. **Deploy (Staging)**: Deploys to staging environment; runs database migrations
5. **Deploy (Production)**: Deploys to production after staging validation; runs database migrations

> Deployment configuration managed externally. Consult the GrouponLive team (ttd-dev.supply@groupon.com) for exact pipeline and Kubernetes manifest locations.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Web (Unicorn) | Horizontal — multiple pods; vertical via `UNICORN_WORKERS` | Min/max managed externally |
| Worker (Resque) | Horizontal — multiple worker pods pulling from shared Redis queue | Worker concurrency set per deployment |
| Memory | Kubernetes resource requests/limits | Managed externally |
| CPU | Kubernetes resource requests/limits | Managed externally |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Managed externally | Managed externally |
| Memory | Managed externally | Managed externally |
| Disk | MySQL and Redis storage managed externally | Managed externally |

> Deployment configuration managed externally. Contact team for specific resource profiles.
