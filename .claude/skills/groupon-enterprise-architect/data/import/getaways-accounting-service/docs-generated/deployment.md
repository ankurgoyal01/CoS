---
service: "getaways-accounting-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

The Getaways Accounting Service is containerized (Docker) and deployed to Google Cloud Platform (GCP) on Kubernetes via Groupon's internal deployment toolchain (`raptor` / `deploy_bot`). It runs two distinct Kubernetes components: a long-running API service (`app`) and a daily cron-job (`cron-job`) that executes the CSV generation workflow. Deployment promotion follows a staging-to-production pipeline managed by Jenkins (`jtierPipeline`). The service is part of the `sox-inscope` SOX-compliance boundary.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `.ci/Dockerfile` — base image `docker.groupondev.com/jtier/dev-java11-maven:2021-08-23-1a58f23` |
| Orchestration | Kubernetes (GCP) | Kustomize manifests in `.meta/kustomize/`; deployment scripts in `.meta/deployment/cloud/scripts/deploy.sh` |
| App image | Docker (Conveyor) | `docker-conveyor.groupondev.com/sox-inscope/getaways-accounting-service` |
| Load balancer | VIP (internal) | `https://getaways-accounting-vip.snc1` (production), `https://getaways-accounting-vip-staging.snc1` (staging) |
| APM | Elastic APM | Endpoint per cluster — `elastic-apm-http.logging-platform-elastic-stack-{env}.svc.cluster.local:8200` |
| Log shipping | Filebeat sidecar | Log source type: `getaways-accounting-service-app`; log path: `/var/groupon/jtier/logs/jtier.steno.log` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation and testing | GCP us-central1 | `https://getaways-accounting-service.us-central1.conveyor.stable.gcp.groupondev.com` |
| production | Live accounting service | GCP us-central1 | `https://getaways-accounting-vip.snc1` (internal) |
| uat | Historical on-prem UAT | snc1 | `https://getaways-accounting-vip-uat.snc1` |

## CI/CD Pipeline

- **Tool**: Jenkins (`java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch in `sox-inscope/getaways-accounting-service` repository

### Pipeline Stages

1. **Build**: Maven build with `docker-compose` (`.ci/docker-compose.yml`) — runs tests and produces artifact
2. **Release**: Publishes Docker image to Conveyor registry; syncs master branch to maintained fork (`travel-fork-sox-repo/getaways-accounting-service`)
3. **Deploy Staging**: Deploys to `gcp-stable-us-central1` Kubernetes cluster, namespace `getaways-accounting-service-staging-sox`
4. **Promote Production**: After staging validation, promotes to `gcp-production-us-central1`, namespace `getaways-accounting-service-production-sox`

Feature branches suffixed with `-deploy` may deploy to staging as a non-promotable release (`staging-us-central1-non-promotable`).

## Scaling

### App Component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA | Staging: min 1 / max 2; Production: min 2 / max 7 (common: min 3 / max 15, target 50% CPU) |
| Memory | Kubernetes limits | Request: 1.7Gi, Limit: 2.0Gi |
| CPU | Kubernetes requests | Main: 300m request; Filebeat: 10m request / 30m limit |

### Cron-Job Component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed | min 1 / max 1 (single pod) |
| Memory | Kubernetes limits | Request: 1.7Gi, Limit: 2.0Gi |
| CPU | Kubernetes requests | Main: 300m; Filebeat: 10m request / 30m limit |
| Schedule | Cron | Production: `20 0 * * *` (daily at 00:20 UTC) |

## Resource Requirements

### App Component

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 300m | — |
| Memory (main) | 1.7Gi | 2.0Gi |
| CPU (filebeat) | 10m | 30m |

### JVM Tuning

- JVM heap: `-Xmx2048m -Xms512m` (from `.mvn/jvm.config`)
- Glibc arenas: `MALLOC_ARENA_MAX=4` (prevents VMem explosion in containers)
- Metrics directory: `METRICS_CODAHALE_EXTRA_DIRECTORY=./logs`

## Ports

| Port | Usage |
|------|-------|
| 8080 | HTTP application traffic (production/staging) |
| 8081 | Dropwizard admin endpoint (tasks, health checks) |
| 8009 | JMX port |
| 9000 | HTTP application traffic (development only) |
| 9001 | Dropwizard admin (development only) |
