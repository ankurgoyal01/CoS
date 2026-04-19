---
service: "mbus-sigint-frontend"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-west-1, staging-us-west-2, staging-us-central1, staging-europe-west1, production-us-west-1, production-eu-west-1, production-us-central1, production-europe-west1]
---

# Deployment

## Overview

The service runs as a Docker container on Groupon's Conveyor Cloud (Kubernetes). Deployments are managed by Napistrano via DeployBot, using Helm chart templating (`cmf-itier`) applied with `krane`. Eight deployment targets are defined: four staging environments and four production environments across AWS (us-west-1, eu-west-1) and GCP (us-central1, europe-west1) regions. Artifacts are built on Conveyor CI (Jenkins/CCI pipeline).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` — base image `alpine-node16.14.2:2022.04.20` |
| Orchestration | Kubernetes (Conveyor Cloud) | Helm chart `cmf-itier` v3.94.0 via Artifactory |
| Deployment tool | Napistrano + DeployBot | `.deploy_bot.yml`, `.deploy-configs/` |
| Deployment image | `docker.groupondev.com/rapt/deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0` | Used by DeployBot |
| App image | `docker-conveyor.groupondev.com/mbus/mbus-sigint-frontend` | Published by CCI build |
| Ingress | Hybrid Boundary (mTLS interceptor) | `mtlsInterceptor: true`, `hbUpstream: true` in deploy configs |
| Log shipping | Filebeat → Kafka → ELK | `filebeatKafkaEndpoint` set per region in deploy configs |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-west-1 | Pre-production validation (AWS) | us-west-1 | `https://mbus-sigint-frontend.staging.service.us-west-1.aws.groupondev.com` |
| staging-us-west-2 | Pre-production validation (AWS) | us-west-2 | `https://mbus-sigint-frontend.staging.service.us-west-2.aws.groupondev.com` |
| staging-us-central1 | Pre-production validation (GCP) | us-central1 | `https://mbus-sigint-frontend.staging.stable.us-central1.gcp.groupondev.com` |
| staging-europe-west1 | Pre-production validation (GCP) | europe-west1 | `https://mbus-sigint-frontend.staging.service` |
| production-us-west-1 | Production (AWS, US/Canada) | us-west-1 | `https://mbus-sigint-frontend.production.service.us-west-1.aws.groupondev.com` |
| production-eu-west-1 | Production (AWS, EMEA) | eu-west-1 | `https://mbus-sigint-frontend.production.service.eu-west-1.aws.groupondev.com` |
| production-us-central1 | Production (GCP, US/Canada) | us-central1 | `https://mbus-sigint-frontend.prod.us-central1.gcp.groupondev.com` |
| production-europe-west1 | Production (GCP, EMEA) | europe-west1 | `https://mbus-sigint-frontend.production.service` |

External URLs: `https://mbus.groupondev.com` (production), `https://mbus-sigint-staging.groupondev.com` (staging).

## CI/CD Pipeline

- **Tool**: Conveyor CI (Jenkins via `itier-pipeline-dsl`)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master`, `release.*`, or `hotfix.*` branches; also `GMB-6685.*` branches
- **Slack notifications**: `#mbus-ci`

### Pipeline Stages

1. **Build**: Compiles Node.js assets with Webpack (`npm run dist-assets`), builds Docker image
2. **Test**: Runs integration tests (`npm run test:integration`) and lint
3. **Deploy to staging**: Auto-deploys to `staging-us-central1` on `master`, `release.*`, `hotfix.*` pushes
4. **Promote to production**: Manual promotion via DeployBot — staging-us-central1 promotes to production-us-central1; staging-us-west-1 promotes to production-us-west-1; staging-europe-west1 promotes to production-eu-west-1

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production) | Kubernetes HPA | Min: 3, Max: 100 replicas |
| Horizontal (staging) | Kubernetes HPA | Min: 1, Max: 3 replicas |
| Memory | Limit enforced by Kubernetes | Request: 2048Mi, Limit: 4096Mi (both envs) |
| CPU | Limit enforced by Kubernetes | Request: 1000m (main); 400m request / 750m limit (logstash, filebeat) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m | Not set (`cpu: false` in setResourceLimits) |
| Memory (main) | 2048Mi | 4096Mi |
| CPU (filebeat) | 400m | 750m |
| Memory (filebeat) | 100Mi | 200Mi |
