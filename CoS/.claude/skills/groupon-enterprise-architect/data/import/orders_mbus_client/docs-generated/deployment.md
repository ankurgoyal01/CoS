---
service: "orders_mbus_client"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev-us-west-1, dev-us-west-2, staging-us-central1, staging-us-west-1, staging-us-west-2, staging-europe-west1, production-us-central1, production-us-west-1, production-eu-west-1, uat, emea-staging, dub1, sac1, snc1]
---

# Deployment

## Overview

Orders Mbus Client is a fully containerised Java service deployed to GCP Kubernetes clusters via the JTier / Raptor platform. Cloud deployments use the `orders-mbus-client` service ID with the `worker` component. Legacy on-premises datacenters (snc1, dub1, sac1) are supported via Docker Compose. CI runs on Jenkins with test and publish steps automated.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker (AdoptOpenJDK 11 UBI) | `Dockerfile` at repo root; image: `docker-conveyor.groupondev.com/jorders/orders_mbus_client` |
| Orchestration | Kubernetes (GCP) | Manifest base: `.meta/deployment/cloud/components/worker/` |
| On-prem orchestration | Docker Compose | `docker/docker-compose.<env>.yml` for snc1/dub1/sac1/UAT/staging |
| Load balancer | Service mesh / Kubernetes Service | HTTP port 8080 (cloud), admin port 8081 |
| CDN | None | Worker service — no CDN |
| Migrations | Flyway (jtier-migrations) | Run at startup unless `DISABLE_MIGRATION=true`; migrations in `src/main/resources/db/migration/` |

## Environments

| Environment | Purpose | Region | Namespace |
|-------------|---------|--------|-----------|
| `dev-us-west-1` | Developer testing | GCP us-west-1 | — |
| `dev-us-west-2` | Developer testing | GCP us-west-2 | — |
| `staging-us-central1` | Pre-production NA | GCP us-central1 | `orders-mbus-client-staging-sox` |
| `staging-us-west-1` | Pre-production NA (West) | GCP us-west-1 | — |
| `staging-us-west-2` | Pre-production NA (West 2) | GCP us-west-2 | — |
| `staging-europe-west1` | Pre-production EMEA | GCP europe-west1 | — |
| `production-us-central1` | Production NA | GCP us-central1 | `orders-mbus-client-production-sox` |
| `production-us-west-1` | Production NA (West) | GCP us-west-1 | — |
| `production-eu-west-1` | Production EMEA | GCP eu-west-1 | — |
| `uat` | UAT (on-prem snc1) | snc1 | — |
| `emea-staging` | EMEA staging (on-prem snc1) | snc1 | — |
| `dub1` | Production EMEA (on-prem) | dub1 | — |
| `sac1` | Production NA (on-prem) | sac1 | — |
| `snc1` | Production NA (on-prem) | snc1 | — |

**UAT health check URL**: `http://orders-mbus-consumer1-uat.snc1:9010`
**Staging health check URL**: `http://orders-mbus-consumer1-staging.snc1:9010`
**Production dashboards**: `https://groupon.wavefront.com/dashboard/orders-omc` and `https://groupon.wavefront.com/dashboards/Orders-OMC-Cloud`

## CI/CD Pipeline

- **Tool**: Jenkins (DotCI)
- **Config**: `.ci.yml`, `.ci/test_and_publish.sh`, `.ci/publish_docker.sh`
- **Trigger**: On push to any branch; auto-deploy after build success via deploy-bot

### Pipeline Stages

1. **Test**: Runs Maven test suite in Docker (`docker-compose-file: .ci/docker-compose.yml`). Collects JUnit XML, JaCoCo coverage, FindBugs XML, PMD reports, and the built JAR as artifacts.
2. **Publish Docker**: Builds and pushes Docker image to `docker-conveyor.groupondev.com/jorders/orders_mbus_client`.
3. **Deploy (automated)**: Deploy-bot triggers after successful build for UAT/staging. Production deployments require GPROD ticket approval and manual confirmation via `live-status` link.

**Rollback**: Via DeployBot at `https://deploybot.groupondev.com/JOrders/orders_mbus_client` — select older deployment and retry.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min 1 / max 2 replicas, target utilisation 50% |
| Horizontal (production) | Kubernetes HPA | min 2 / max 10 replicas, target utilisation 50% |
| VPA | Disabled | `enableVPA: false` in `common.yml` |
| Publisher thread pool | ThreadPoolExecutor | core = `poolSize` (20), max = `poolSize * 2` (40), queue = `LinkedBlockingQueue` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main container) | 300m | Not set (common.yml) |
| CPU (filebeat sidecar) | 50m | 80m |
| CPU (envoy sidecar) | 30m | 50m |
| Memory (main container) | 2Gi | 4Gi |
| Memory (filebeat sidecar) | 150Mi | 300Mi |
| Disk | Not specified | Not specified |
