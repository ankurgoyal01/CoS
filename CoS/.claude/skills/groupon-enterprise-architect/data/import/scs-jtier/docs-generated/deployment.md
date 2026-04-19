---
service: "scs-jtier"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, staging-us-west-1, production-us-central1, production-eu-west-1, production-europe-west1, production-us-west-1]
---

# Deployment

## Overview

scs-jtier is deployed as a Docker container orchestrated by Kubernetes via Groupon's Conveyor Cloud platform. The service runs in two component types: `app` (web server, `IS_CRON_ENABLED=false`) and `worker` (background job runner, `IS_CRON_ENABLED=true`). Deployments are managed via Deploybot and configured through per-environment YAML manifests under `.meta/deployment/cloud/`. The service runs in both GCP (us-central1, europe-west1) and AWS (eu-west-1) regions.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — base image `docker.groupondev.com/jtier/prod-java11-jtier:3` |
| CI image | Docker | `.ci/Dockerfile` — base image `docker.groupondev.com/jtier/dev-java11-maven:2020-12-04-277a463` |
| Orchestration | Kubernetes (Conveyor Cloud) | Manifests: `.meta/deployment/cloud/components/app/`, `.meta/deployment/cloud/components/worker/` |
| App image registry | docker-conveyor.groupondev.com | Image: `docker-conveyor.groupondev.com/usergeneratedcontent/scs-jtier` |
| Load balancer | Hybrid Boundary / Kubernetes Service | HTTP port 8080; admin port 8081 exposed |
| CDN | None | Not applicable for an internal backend service |

## Environments

| Environment | Purpose | Cloud/Region | Internal URL |
|-------------|---------|--------------|-------------|
| `staging-us-central1` | Pre-production validation (US) | GCP us-central1 | `shopping-cart-service-jtier.us-central1.conveyor.stable.gcp.groupondev.com` |
| `staging-europe-west1` | Pre-production validation (EMEA) | GCP europe-west1 | Internal only |
| `staging-us-west-1` | Pre-production validation (US West) | AWS us-west-1 | Internal only |
| `production-us-central1` | Production (US) | GCP us-central1 | `shopping-cart-service-jtier.us-central1.conveyor.prod.gcp.groupondev.com` |
| `production-eu-west-1` | Production (EMEA) | AWS eu-west-1 | Internal only |
| `production-europe-west1` | Production (EMEA) | GCP europe-west1 | Internal only |
| `production-us-west-1` | Production (US West) | AWS us-west-1 | Internal only |

Legacy on-premises VIPs (from `.service.yml`) for reference:
- `http://shopping-cart-vip.snc1` — snc1 production
- `http://shopping-cart-staging-vip.snc1` — snc1 staging
- `http://shopping-cart-vip.sac1` — sac1 production
- `http://shopping-cart-vip.dub1` — dub1 production (EMEA)

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI)
- **Config**: `Jenkinsfile` (uses `java-pipeline-dsl@latest-2` shared library, `jtierPipeline` step)
- **Trigger**: On push to `master`, `release`, or `CORE673-VISBulkAvailability` branches; Docker build included (`skipDocker: false`)
- **Deploy targets (auto)**: `staging-us-central1`, `staging-europe-west1` — triggered automatically on merge to `master`
- **Slack notifications**: `ugc-notifications` channel

### Pipeline Stages

1. **Build**: Maven build (`mvn clean package`) producing a runnable JAR and Docker image
2. **Test**: Unit and integration tests via Maven; code coverage enforced by JaCoCo
3. **Static analysis**: PMD (`pmd-rulesets.xml`) and FindBugs (`findbugs-exclude.xml`) checks
4. **Docker push**: Image published to `docker-conveyor.groupondev.com/usergeneratedcontent/scs-jtier`
5. **Staging deploy**: Automatic deployment to `staging-us-central1` and `staging-europe-west1` via Deploybot
6. **Production promote**: Manual promotion via Deploybot; requires QA and prodCAT approval per change policy

### Deployment Order

Per OWNERS_MANUAL.md:
- `staging-europe-west1` → `production-eu-west-1`
- `staging-us-central1` → `production-us-central1`

## Scaling

| Dimension | Strategy | Config (Production GCP us-central1) | Config (Production AWS eu-west-1) |
|-----------|----------|--------------------------------------|----------------------------------|
| Horizontal (app) | HPA | min 2, max 25, target CPU 100% | min 2, max 25 |
| Horizontal (worker) | HPA | min 3, max 3 (common default) | min 3, max 3 |
| Horizontal (staging) | HPA | min 1, max 10, target CPU 100% | — |

> To add capacity: update `maxReplicas` in the relevant `.meta/deployment/cloud/components/app/<env>.yml` and redeploy the same image.

## Resource Requirements

### Production GCP us-central1 (app component)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 500m | No explicit limit (inherits from common) |
| Memory | 4 Gi | 4 Gi |

### Production AWS eu-west-1 (app component)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 100m | No explicit limit |
| Memory | 3 Gi | 3 Gi |

### Common defaults (app and worker components)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 300m | — |
| CPU (filebeat) | 10m | 30m |
| Memory (main) | 500 Mi | 500 Mi |

### Ports

| Port | Purpose |
|------|---------|
| 8080 | HTTP application traffic (mapped as `httpPort`) |
| 8081 | Admin/metrics port (Dropwizard admin interface) |
