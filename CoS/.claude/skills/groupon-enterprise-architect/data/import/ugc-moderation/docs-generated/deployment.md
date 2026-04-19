---
service: "ugc-moderation"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, staging-us-west-1, staging-us-west-2, production-us-west-1, production-eu-west-1, production-us-central1, production-europe-west1]
---

# Deployment

## Overview

UGC Moderation is a containerized Node.js application deployed to Kubernetes via the Groupon Conveyor Cloud platform. Docker images are built by Conveyor CI (Jenkins) and deployed using Napistrano (napistrano v2.180.18). The service runs in multiple AWS and GCP regions for both staging and production. mTLS is enforced at the Hybrid Boundary ingress layer.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; base image `docker-conveyor.groupondev.com/conveyor/alpine-node16.15.0:2022.05.23` |
| Orchestration | Kubernetes (Conveyor Cloud) | Deploy configs in `.deploy-configs/*.yml` |
| Service mesh | Hybrid Boundary (HB) | mTLS interceptor enabled (`mtlsInterceptor: true`, `hbUpstream: true`) |
| Log shipping | Filebeat → Kafka → ELK | Source type: `ugc-moderation_itier`; index: `steno` |
| Metrics | Telegraf → InfluxDB → Wavefront | Dashboard: `https://groupon.wavefront.com/dashboards/ugc-moderation` |
| Deployment tool | Napistrano / Deploybot | `npx nap --cloud deploy --artifact <tag> <env> <region>` |
| CI | Conveyor CI (Jenkins) | `Jenkinsfile` at repo root; `cloud-jenkins.groupondev.com` |

## Environments

| Environment | Purpose | Cloud Provider | Region | VIP / URL |
|-------------|---------|----------------|--------|-----------|
| staging-us-central1 | Primary staging | GCP | us-central1 | `ugc-moderation.staging.stable.us-central1.gcp.groupondev.com` |
| staging-us-west-1 | Secondary staging | AWS | us-west-1 | Internal staging |
| staging-us-west-2 | Secondary staging | AWS | us-west-2 | `ugc-moderation.staging.service.us-west-2.aws.groupondev.com` |
| staging-europe-west1 | EU staging | GCP | europe-west1 | Internal staging |
| production-us-west-1 | Primary US production | AWS | us-west-1 | `ugc-moderation.prod.us-west-1.aws.groupondev.com` |
| production-us-central1 | US production (GCP) | GCP | us-central1 | `ugc-moderation.production.service.us-central1.gcp.groupondev.com` |
| production-eu-west-1 | EU production (AWS) | AWS | eu-west-1 | `ugc-moderation.production.service.eu-west-1.aws.groupondev.com` |
| production-europe-west1 | EU production (GCP) | GCP | europe-west1 | Internal production |

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI) + Napistrano + Deploybot
- **Config**: `Jenkinsfile` (CI), `.deploy-configs/*.yml` (per-environment Kubernetes manifests)
- **Trigger**: On push to master (CI build); manual Napistrano deploy command or Deploybot UI (deploy/rollback)

### Pipeline Stages

1. **Build**: Conveyor CI builds Docker image tagged with timestamp and git SHA (e.g., `2019.04.20-23.42.42-cafed06`)
2. **Lint**: ESLint runs (`npm run lint`)
3. **Test**: Unit + server tests (`npm run test:unit`), integration tests (`npm run test:integration`), testem browser tests
4. **Asset build**: Webpack bundles frontend assets (`npm run dist-assets`)
5. **Push**: Docker image pushed to `docker-conveyor.groupondev.com/usergeneratedcontent/ugc-moderation`
6. **Deploy (staging)**: Napistrano deploys artifact to staging region(s)
7. **Deploy (production)**: Manual Napistrano or Deploybot deploy after staging validation
8. **Rollback**: `npx nap --cloud rollback <env> <region>` or Deploybot "ROLLBACK" button

### Artifact Promotion

- All successfully built CCI artifacts are available for `staging us-west-1` and `staging us-west-2`
- Only artifacts successfully deployed to `staging us-west-1` are available for `production us-west-1`
- Only artifacts successfully deployed to `staging us-west-2` are available for `production eu-west-1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min 1 / max 2 replicas per region |
| Horizontal (production) | Kubernetes HPA | min 2 / max 3–4 replicas per region (eu-west-1: 4, us-central1: 3, europe-west1: 3) |
| Memory | Kubernetes limits | Request: 1536Mi / Limit: 3072Mi (main container) |
| CPU | Kubernetes limits | Request: 1000m (main); Logstash: 400m req / 750m limit; Filebeat: 400m req / 750m limit |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m | Not set (cpu limit disabled per `values.yaml`) |
| Memory (main) | 1536Mi | 3072Mi |
| CPU (logstash) | 400m | 750m |
| CPU (filebeat) | 400m | 750m |
| Memory (filebeat) | 100Mi | 200Mi |
