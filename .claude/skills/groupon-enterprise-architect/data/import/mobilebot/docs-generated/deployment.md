---
service: "mobilebot"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

Mobilebot is containerized using Docker and deployed to Kubernetes via the Groupon Conveyor platform (using `cmf-java-api` Helm chart v3.80.6). It runs as a single-replica stateful bot process (min/max replicas both set to 1 — no horizontal scaling) across multiple AWS and GCP regions. Deployment is orchestrated by DeployBot using `krane` for Kubernetes manifest application. The Docker image is built with a multi-stage approach that embeds both Node.js 18 and Ruby 2.7.7 runtimes in an Alpine Linux base.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; base `node:18.14.2-alpine3.17` with Ruby 2.7.7 layered in; entrypoint `service_scripts/docker_entry_point.sh` |
| Orchestration | Kubernetes (via Conveyor) | Helm chart `cmf-java-api` v3.80.6; manifests applied by `krane`; config at `.meta/deployment/cloud/` |
| Image registry | Conveyor Docker registry | `docker-conveyor.groupondev.com/mobile_consumer/mobilebot` |
| Deploy tool | DeployBot + krane | `.deploy_bot.yml` defines targets; deploy script at `.meta/deployment/cloud/scripts/deploy.sh` |
| Load balancer | Kubernetes VIP (cloud) | Internal VIP per environment (see Environments table) |
| CDN | None | Not applicable — no user-facing web traffic |
| Legacy (on-prem) | VM (SNC1) | `http://mobilebot1.snc1` (production), `http://mobilebot1-staging.snc1` (staging) — noted in `.service.yml` |

## Environments

| Environment | Purpose | Region | VIP |
|-------------|---------|--------|-----|
| dev (AWS us-west-1) | Development testing | AWS us-west-1 | `mobilebot.dev.stable.us-west-1.aws.groupondev.com` |
| dev (AWS us-west-2) | Development testing (EMEA cluster) | AWS us-west-2 | `mobilebot.dev.stable.us-west-2.aws.groupondev.com` |
| staging (AWS us-west-1) | Pre-production validation | AWS us-west-1 | `mobilebot.staging.stable.us-west-1.aws.groupondev.com` |
| staging (AWS us-west-2) | Pre-production validation (EMEA) | AWS us-west-2 | `mobilebot.staging.stable.us-west-2.aws.groupondev.com` |
| staging (GCP us-central1) | Pre-production validation (GCP) | GCP us-central1 | — |
| production (AWS us-west-1) | Production (US/Canada) | AWS us-west-1 | `mobilebot.prod.us-west-1.aws.groupondev.com` |
| production (AWS eu-west-1) | Production (EMEA) | AWS eu-west-1 | `mobilebot.prod.eu-west-1.aws.groupondev.com` |
| production (GCP us-central1) | Production (US/Canada GCP) | GCP us-central1 | — |

## CI/CD Pipeline

- **Tool**: DeployBot (Groupon internal deployment orchestrator)
- **Config**: `.deploy_bot.yml`
- **Trigger**: Manual dispatch via DeployBot; staging deploys promoted to production via `promote_to` in `.deploy_bot.yml`
- **Deploy image**: `docker.groupondev.com/rapt/deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0`
- **Slack notifications**: `#CF8A83FEW` channel on `start`, `complete`, `override` events

### Pipeline Stages

1. **Build**: Docker image built and pushed to `docker-conveyor.groupondev.com/mobile_consumer/mobilebot`
2. **Deploy to dev**: `bash ./.meta/deployment/cloud/scripts/deploy.sh dev-us-west-1 dev mobilebot-dev`
3. **Deploy to staging**: `bash ./.meta/deployment/cloud/scripts/deploy.sh staging-us-west-1 staging mobilebot-staging`
4. **Promote to production**: `bash ./.meta/deployment/cloud/scripts/deploy.sh production-us-west-1 production mobilebot-production`
5. **Kubernetes apply**: `krane deploy mobilebot-{env} {kube_context}` with 300-second global timeout

### Docker Build Notes

- Node.js dependencies: `npm ci`
- Ruby dependencies: `bundle install` in `scripts/ruby/` with `--deployment` flag (bundler v2 vendored)
- Both runtimes co-exist in the same container image (Node.js 18 Alpine + Ruby 2.7.7 Alpine layer)
- Log directory `/app/log` created at build time and exposed as a volume for on-prem deployments

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed — single instance | `minReplicas: 1`, `maxReplicas: 1`, `hpaTargetUtilization: 100` |
| Memory | Limit enforced | Request: 200Mi, Limit: 500Mi |
| CPU | Limit enforced | Request: 50m (main), 10m (filebeat); Limit: 30m (filebeat) |

> Mobilebot is intentionally single-replica because it maintains stateful Redis connections and is a singleton chat bot. Running multiple replicas would result in duplicate command responses.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 50m | Not set (best-effort) |
| CPU (filebeat sidecar) | 10m | 30m |
| Memory (main) | 200Mi | 500Mi |
| Disk | `/app/log` volume | Managed by node filesystem |

## Ports

| Port | Purpose |
|------|---------|
| 8080 | Main application HTTP port (Kubernetes service `httpPort`) |
| 80 | Heartbeat listener (internal, started by `startup.js`) |
| 8081 | Admin port (exposed as `admin-port` on Kubernetes service) |

## Health Checks

- **Path**: `/heartbeat`
- **Port**: 80 (internal) / forwarded via Kubernetes to `healthcheckPort: 80`
- **Behaviour**: Returns HTTP 200; writes `app.heartbeat` log event via `groupon-steno`
