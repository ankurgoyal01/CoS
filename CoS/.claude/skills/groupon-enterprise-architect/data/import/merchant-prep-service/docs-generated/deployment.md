---
service: "merchant-prep-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-europe-west1, production-eu-west-1]
---

# Deployment

## Overview

The Merchant Preparation Service is containerized using Docker and deployed to Kubernetes clusters on GCP (primary) and AWS (legacy EU). Deployments are managed by the Raptor deploy system via DeployBot (`deploy_bot.yml`). The CI pipeline runs on Jenkins using the `java-pipeline-dsl` shared library. The service operates in a SOX-regulated namespace (`mx-merchant-preparation-production-sox`) and follows a staging-to-production promotion model. APM (OpenTelemetry) tracing is enabled in production.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile`; base image `docker.groupondev.com/jtier/prod-java21-jtier:4` |
| Orchestration | Kubernetes | Managed via Raptor deploy system; manifests generated from `.meta/deployment/cloud/components/app/*.yml` |
| Load balancer | Hybrid Boundary (JTier) | Two domain namespaces: `public` and `default`; configured in `common.yml` |
| Registry | docker-conveyor.groupondev.com | Image: `docker-conveyor.groupondev.com/sox-inscope/merchant-prep-service` |
| Observability | OpenTelemetry Java Agent | Bundled at `src/main/docker/opentelemetry-javaagent.jar`; OTLP export to Tempo |

## Environments

| Environment | Purpose | Region | URL (internal) |
|-------------|---------|--------|----------------|
| staging-us-central1 | Pre-production validation (US) | GCP us-central1 | `http://merchant-preparation-us-staging-vip.snc1` |
| staging-europe-west1 | Pre-production validation (EU) | GCP europe-west1 | `http://merchant-preparation-emea-staging-vip.snc1` |
| production-us-central1 | Production (US) | GCP us-central1 | `http://merchant-preparation-us-vip.sac1`, `http://merchant-preparation-us-sox-vip.sac1` |
| production-europe-west1 | Production (EU, GCP) | GCP europe-west1 | `http://merchant-preparation-emea-vip.dub1`, `http://merchant-preparation-emea-sox-vip.dub1` |
| production-eu-west-1 | Production (EU, AWS legacy) | AWS eu-west-1 | `http://merchant-preparation-us-vip.snc1`, `http://merchant-preparation-us-sox-vip.snc1` |

Health check: `GET /merchant-self-prep/health?invoker=service-portal` on port 8080.

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Shared library**: `java-pipeline-dsl@latest-2`
- **Trigger**: On push to `main` or branches matching `MCE-.*`; promotion to production is manual for `production-*` targets, automatic for staging

### Pipeline Stages

1. **Build**: `mvn -U -B clean verify` — compiles, runs unit and integration tests, generates Swagger stubs, produces Docker image
2. **Docker push**: Image pushed to `docker-conveyor.groupondev.com/sox-inscope/merchant-prep-service`
3. **Deploy to Staging**: Automatic deploy to `staging-us-central1` and `staging-europe-west1` via DeployBot
4. **Promote to Production**: Manual promotion to `production-us-central1` (from `staging-us-central1`) and `production-eu-west-1` / `production-europe-west1` (from `staging-europe-west1`)
5. **Notification**: Google Chat (`GCHAT_SPACE`) and Slack (`merchant-experience-automation-logs`) build report sent on completion

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Kubernetes Horizontal Pod Autoscaler) | Staging: min 1 / max 2; Production: min 2 / max 15; target utilization: 100% |
| Memory | Resource limits | Request: 2.5 Gi, Limit: 5 Gi (common.yml) |
| CPU | Resource limits | Request: 300m, Limit: 1200m (common.yml) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 300m | 1200m |
| Memory | 2.5 Gi | 5 Gi |
| Disk | Not specified | Not specified |

### Ports

| Port | Purpose |
|------|---------|
| 8080 | HTTP API (main application port) |
| 8081 | Admin / health port |
| 8009 | JMX |
