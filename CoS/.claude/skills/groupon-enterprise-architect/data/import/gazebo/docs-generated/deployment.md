---
service: "gazebo"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Gazebo is containerized using Docker with a custom `editorial/gazebo` base image and deployed to Kubernetes (inferred from the containerized + multi-environment setup). CI/CD is managed via Jenkins at `ci.groupondev.com`. Four runtime containers are deployed: the web app (Unicorn), background worker, Message Bus consumer, and cron scheduler. The frontend assets are compiled via Gulp during the Docker build process.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Custom base image: `editorial/gazebo`; Dockerfile in repo root |
| Orchestration | Kubernetes (inferred) | Manifest paths not discoverable from inventory |
| Load balancer | No evidence found | Deployment configuration managed externally |
| CDN | No evidence found | Deployment configuration managed externally |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and testing | local | localhost |
| staging | Pre-production validation | No evidence found | No evidence found |
| production | Live editorial platform for all Groupon editorial staff | No evidence found | No evidence found |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `ci.groupondev.com` (external CI server; pipeline config not in this repo's inventory)
- **Trigger**: On push / on pull request (inferred standard Jenkins pipeline behavior)

### Pipeline Stages

1. Install dependencies: `bundle install` (Bundler 1.16.6) and `npm install`
2. Frontend build: Gulp compiles frontend assets
3. Test: Run RSpec unit/integration tests and Cucumber BDD acceptance tests
4. Docker build: Build `editorial/gazebo` Docker image
5. Push image: Push image to container registry
6. Deploy: Apply Kubernetes manifests for web app, worker, MBus consumer, and cron containers

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA (inferred) | No evidence found; managed externally |
| Unicorn workers | Process-based | Configured via `UNICORN_WORKERS` environment variable |
| Memory | Kubernetes resource limits (inferred) | No evidence found; managed externally |
| CPU | Kubernetes resource limits (inferred) | No evidence found; managed externally |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found | No evidence found |
| Memory | No evidence found | No evidence found |
| Disk | No evidence found | No evidence found |

> Deployment configuration managed externally. Specific Kubernetes manifests and resource quota values are not discoverable from this repository's inventory.
