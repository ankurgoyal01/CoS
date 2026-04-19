---
service: "webbus"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Webbus is containerised using Docker and deployed to Kubernetes via Groupon's Conveyor Cloud platform. Deployments are managed by DeployBot, which is triggered automatically on merges to the `master` or `staging` branches. The service is deployed across multiple GCP and AWS regions. Kubernetes manifests are rendered at deploy time using Helm (`cmf-rails-api` chart version `3.88.1`) and applied with `krane`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `.ci/Dockerfile` — base image `docker.groupondev.com/ruby:1.9.3`; exposes port `9393` |
| Orchestration | Kubernetes (Conveyor Cloud) | Manifests rendered via Helm chart `cmf-rails-api@3.88.1`; applied with `krane` |
| Helm chart | `cmf-rails-api` | Version `3.88.1`, sourced from `http://artifactory.groupondev.com/artifactory/helm-generic/` |
| Deploy script | Bash | `.meta/deployment/cloud/scripts/deploy.sh` |
| Load balancer | Nginx (sidecar, Hybrid Boundary) | Nginx sidecar fronts the Ruby process on port 9393; Hybrid Boundary exposes public and default namespaces |
| App image | Docker | `docker-conveyor.groupondev.com/salesforce/webbus` |

## Environments

| Environment | Purpose | Region | Notes |
|-------------|---------|--------|-------|
| `development` (local) | Local development | — | Docker Compose via `.ci/docker-compose.local.yml` |
| `staging-us-central1` | Primary staging | GCP us-central1 | Kubernetes context: `webbus-gcp-staging-us-central1`; namespace: `webbus-staging` |
| `staging-us-west-1` | Staging (AWS) | AWS us-west-1 | Kubernetes context: `webbus-staging-us-west-1`; namespace: `webbus-staging` |
| `staging-us-west-2` | Staging (AWS EMEA gate) | AWS us-west-2 | Promotes to `production-eu-west-1` |
| `production-us-central1` | Primary production | GCP us-central1 | Kubernetes context: `webbus-gcp-production-us-central1`; namespace: `webbus-production` |
| `production-us-west-1` | Production (AWS) | AWS us-west-1 | Kubernetes context: `webbus-production-us-west-1` |
| `production-us-west-2` | Production (AWS) | AWS us-west-2 | Kubernetes context: `webbus-production-us-west-2` |
| `production-eu-west-1` | Production (EMEA) | AWS eu-west-1 | Kubernetes context: `webbus-production-eu-west-1`; datacenter: `dub1` |
| `dev-us-central1` | Dev environment | GCP us-central1 | Kubernetes context: `webbus-gcp-dev-us-central1`; namespace: `webbus-dev` |

## CI/CD Pipeline

- **Tool**: Jenkins (Groupon Cloud Jenkins) + DeployBot
- **Config**: `Jenkinsfile` (uses shared library `ruby-pipeline-dsl@latest-2`)
- **Trigger**: Push to `master`, `staging`, or `release.*` branches; DeployBot handles promotion

### Pipeline Stages

1. **Build**: Jenkins builds the application and runs the test suite (`bundle exec rspec`)
2. **Package**: Docker image is built and published to Groupon Artifactory (`docker-conveyor.groupondev.com/salesforce/webbus`)
3. **Deploy to staging**: DeployBot triggers deployment to `staging-us-west-1` and `staging-us-central1` automatically post-build
4. **Promote to production**: Manual promotion through DeployBot UI from staging to corresponding production targets (e.g., `staging-us-central1 -> production-us-central1`)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Default: min 2 / max 15, target CPU utilisation 100%; production-us-central1 overrides: min 1 / max 2 |
| Memory | Resource limits | Request: 100Mi, Limit: 500Mi (main container) |
| CPU | Resource limits | Request: 50m (main container); filebeat: request 10m, limit 30m |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 50m | not set |
| Memory (main) | 100Mi | 500Mi |
| CPU (filebeat) | 10m | 30m |
| Disk | — | — |

## Rollback

Rollback can be performed through DeployBot in two ways:
- **Retry**: Re-run the previous stable deployment from the DeployBot UI.
- **Rollback**: Click "Rollback" on a specific past deployment in the DeployBot UI.

Kubernetes-level rollback: `kubectl rollout restart deployment/webbus--app--default`

## Kubernetes Access

Access to the `webbus` namespace and LDAP groups must be requested via ARQ: `https://arq.groupondev.com/ra/ad_subservices/webbus`. Select all three Conveyor Cloud groups and provide a reason for access.
