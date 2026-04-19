---
service: "doorman"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["dev-us-west-1", "dev-us-west-2", "dev-us-central1", "staging-us-west-2", "staging-us-central1", "staging-europe-west1", "production-eu-west-1", "production-us-central1", "production-europe-west1"]
---

# Deployment

## Overview

Doorman is containerized (Docker on Alpine Linux) and deployed to Kubernetes via Helm. The CI/CD pipeline is Jenkins-based (`Jenkinsfile`) using the `ruby-pipeline-dsl` shared library. Deployment is orchestrated by DeployBot, which renders Helm charts and applies them with `krane`. The service runs across two cloud regions (US and EMEA) in dev, staging, and production tiers. All cloud deployments use GCP Kubernetes clusters; legacy AWS (eu-west-1) Kubernetes clusters are also configured.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `.ci/Dockerfile` — `docker.groupondev.com/ruby:3.3.9-alpine`; entrypoint: `bundle exec puma -C config/puma.rb` |
| Orchestration | Kubernetes | Helm chart `cmf-generic-api` version `3.89.0` from Groupon Helm registry |
| Deploy tool | krane + DeployBot | `.deploy_bot.yml`; `krane deploy` with `--global-timeout=300s` |
| Load balancer | HTTPS Ingress | `httpsIngress.enabled: true`; inbound port 443; HTTP/2 disabled |
| Image registry | docker-conveyor.groupondev.com | Image: `docker-conveyor.groupondev.com/users-team/doorman` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev-us-west-1 | Development (US) | AWS us-west-1 | — |
| dev-us-west-2 | Development (EMEA path) | AWS us-west-2 | — |
| dev-us-central1 | Development (GCP US) | GCP us-central1 | — |
| staging-us-west-2 | Staging (EMEA path) | AWS us-west-2 | `https://doorman-staging-emea.groupondev.com` |
| staging-us-central1 | Staging (NA) | GCP us-central1 | `https://doorman-staging-na.groupondev.com` |
| staging-europe-west1 | Staging (EMEA) | GCP europe-west1 | — |
| production-us-central1 | Production (NA) | GCP us-central1 | `https://doorman-na.groupondev.com` |
| production-eu-west-1 | Production (EMEA, AWS) | AWS eu-west-1 | `https://doorman-emea.groupondev.com` |
| production-europe-west1 | Production (EMEA, GCP) | GCP europe-west1 | — |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (uses `@Library("ruby-pipeline-dsl@v2.21")`)
- **Trigger**: Push to `master`, `release`, or designated patch branches; auto-deploy to staging; manual promotion to production
- **Staging auto-deploy targets**: `staging-us-central1`, `staging-europe-west1`
- **Notifications**: Slack channel `users-team-bots`; alerts on start, complete, and override events

### Pipeline Stages

1. **Build**: Bundle gems in Docker image; run RuboCop linting
2. **Test**: Run RSpec test suite in `.ci/Dockerfile.tests` container
3. **Release**: Tag and push Docker image to `docker-conveyor.groupondev.com/users-team/doorman`
4. **Deploy (staging)**: Auto-deploy to `staging-us-central1` and `staging-europe-west1` via DeployBot / krane
5. **Deploy (production)**: Manual promotion from staging; DeployBot renders Helm chart and runs `krane deploy` with 300s timeout

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (common) | Fixed replicas | Min 3 / Max 3 (common); overridden per environment |
| Horizontal (production-us-central1) | HPA-capable | Min 2 / Max 3 |
| Vertical Pod Autoscaler | Enabled | `enableVPA: true` |
| Puma threads | Fixed | 5 threads, 2 workers (`config/puma.rb`) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (app) | 50m | — |
| CPU (filebeat) | 10m | 30m |
| Memory (app) | 150Mi | 700Mi |
| Memory (filebeat) | 100Mi | 600Mi |
| Disk | — | — |

## Health Checks (Kubernetes Probes)

| Probe | Path | Port |
|-------|------|------|
| Liveness | `/grpn/healthcheck` | 3180 |
| Readiness | `/grpn/healthcheck` | 3180 |

The `/grpn/healthcheck` endpoint returns `200` if `heartbeat.txt` is present on disk, `503` otherwise. The health check port is 3180 and the app HTTP port is 3180.
