---
service: "itier-mobile"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production, uat]
---

# Deployment

## Overview

`itier-mobile` is containerized using Docker (multi-stage build on `alpine-node16.16.0`) and deployed to Groupon's Conveyor Cloud Kubernetes platform. Deployments are managed by Napistrano (`npx nap`) and orchestrated via Deploybot. The service runs in multiple geographic regions (US and EMEA) across both staging and production. Helm chart version `3.94.0` (`cmf-itier`) is used to generate Kubernetes manifests.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (multi-stage) | `Dockerfile` — build stage: `alpine-node16.16.0-build:2022.07.22`; release stage: `alpine-node16.16.0:2022.07.22` |
| Orchestration | Kubernetes (Conveyor Cloud) | Helm chart `cmf-itier` v3.94.0; manifests generated from `.deploy-configs/*.yml` |
| Deployment tool | Napistrano + Deploybot | `npx nap deploy`, `npx nap rollback`; Deploybot: https://deploybot.groupondev.com/InteractionTier/itier-mobile |
| Load balancer / Ingress | Hybrid Boundary (mTLS interceptor) | `mtlsInterceptor: true`; `hbUpstream: true`; `ingressEnabled: true`; `egressEnabled: true` |
| CDN | Akamai | Caches static assets at `/mobile-assets` and association files; `Cache-Control: public, max-age=300` on `/apple-app-site-association` |
| Log shipping | Filebeat → Kafka → ELK | `filebeatKafkaEndpoint: kafka-logging-kafka-bootstrap.kafka-production.svc.cluster.local` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation | GCP us-central1 | https://itier-mobile.staging.service / https://staging.groupon.com/mobile |
| staging | Pre-production validation | GCP europe-west1 | https://itier-mobile.staging.service |
| staging | Pre-production validation | AWS us-west-2 | https://itier-mobile.staging.service.us-west-2.aws.groupondev.com |
| staging | Pre-production validation | AWS us-west-1 | https://itier-mobile.staging.service.us-west-1.aws.groupondev.com |
| production | Live traffic | GCP us-central1 | https://itier-mobile.production.service / https://www.groupon.com/mobile |
| production | Live traffic | GCP europe-west1 | https://itier-mobile.production.service |
| production | Live traffic | AWS us-west-1 | https://itier-mobile.production.service.us-west-1.aws.groupondev.com |
| production | Live traffic | AWS eu-west-1 | https://itier-mobile.production.service.eu-west-1.aws.groupondev.com |
| uat | QA/release candidate testing | snc1 | https://uat.groupon.com/mobile |

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI) via I-Tier shared pipeline DSL
- **Config**: `Jenkinsfile` — uses `@Library('itier-pipeline-dsl@latest-2')`
- **Trigger**: On push to `main`, `release`, or `hotfix` branches (auto-deploy); on push to `pinky.*` / `perky.*` branches (publish + deploy to canary target only)
- **Slack notifications**: `#itier-spam`

### Pipeline Stages

1. **Lint**: Runs `npm run lint` (ESLint + l10nlint)
2. **Test (server)**: Runs `npm run test-server` (unit tests with c8 coverage)
3. **Test (integration)**: Runs `npm run test-integration`
4. **Build assets**: Runs `npm run dist-assets` (webpack production build), uploads to staging and production CDN via `npx nap upload-assets`
5. **Build Docker image**: Multi-stage Docker build; image pushed to `docker-conveyor.groupondev.com/interactiontier/itier-mobile`
6. **Deploy to staging**: Automatic on `main|release|hotfix` — deploys to `staging-us-central1` and `staging-europe-west1`
7. **Deploy to production**: Automatic on `main|release|hotfix` — deploys to `production-us-central1` and `production-eu-west-1`

> Staging-to-production promotion: artifacts deployed to `staging-us-west-1` are eligible for `production-us-west-1`; artifacts deployed to `staging-us-west-2` are eligible for `production-eu-west-1`.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production) | Kubernetes HPA | Min: 2 replicas, Max: 20 replicas, Target CPU utilization: 100% |
| Horizontal (staging) | Kubernetes HPA | Min: 1 replica, Max: 3 replicas |
| Memory | Resource limits | Request: 1536Mi, Limit: 3072Mi |
| CPU | Resource requests | Main: 1000m request (no limit set); logstash: 400m req / 750m limit; filebeat: 400m req / 750m limit |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main container) | 1000m | Not set |
| Memory (main container) | 1536Mi | 3072Mi |
| CPU (filebeat sidecar) | 400m | 750m |
| Memory (filebeat sidecar) | 100Mi | 200Mi |
| Node.js heap | — | 1024MB (`--max-old-space-size=1024` via `NODE_OPTIONS`) |
