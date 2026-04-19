---
service: "larc"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

LARC is deployed as three separate Kubernetes workloads — `app`, `worker`, and `worker-bulk` — all built from a single Docker image (`docker-conveyor.groupondev.com/travel/larc`). Deployments target Google Cloud Platform (GCP) Kubernetes clusters in `us-central1`. The Helm chart `cmf-jtier-api` (version `3.89.0`) renders Kubernetes manifests. Deployment orchestration is managed by DeployBot using the configuration in `.deploy_bot.yml`. CI/CD runs through Jenkins (Jenkinsfile at repo root).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | `Dockerfile` (root) and `src/main/docker/Dockerfile`; base image `java:8-jre` (legacy), Java 11 runtime in production |
| Container registry | Docker (Conveyor) | `docker-conveyor.groupondev.com/travel/larc` |
| Orchestration | Kubernetes (GCP) | Helm chart `cmf-jtier-api` v3.89.0; Kustomize overlays in `.meta/kustomize/worker/` |
| Deployment tool | DeployBot + Krane | `.deploy_bot.yml` defines targets; `krane deploy` applies manifests to cluster |
| APM | Elastic APM | Enabled on all components; production endpoint: `elastic-apm-http.logging-platform-elastic-stack-production.svc.cluster.local:8200` |
| Load balancer | Hybrid Boundary (HB) | `app` uses `isDefaultDomain: true` (domain: `larc`); `worker` and `worker-bulk` use `isDefaultDomain: false` |
| Logging | Filebeat sidecar | `sourceType: getaways-larc-app` (app), `getaways-larc-worker` (worker/worker-bulk) |

## Environments

| Environment | Purpose | Region | Kubernetes Cluster |
|-------------|---------|--------|-------------------|
| `staging` | Pre-production validation | us-central1 | `gcp-stable-us-central1` |
| `production` | Live traffic | us-central1 | `gcp-production-us-central1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (repo root)
- **Trigger**: On push to `master` branch; manual dispatch via DeployBot for targeted component deploys

### Pipeline Stages

1. **Build**: Maven builds JAR; `mvnvm.properties` pins Maven 3.3.9
2. **Test**: Unit and integration tests (JUnit, Mockito, WireMock, MockFtpServer); test coverage threshold at `0.00` ratio (25 missed class threshold enforced)
3. **Package**: Maven packages tarball (`target/*.tar.gz`); copied into Docker image
4. **Publish**: Docker image pushed to `docker-conveyor.groupondev.com/travel/larc`
5. **Deploy (staging)**: DeployBot runs `deploy-app.sh staging-us-central1 staging larc-staging`, `deploy-worker.sh`, `deploy-worker-bulk.sh`
6. **Promote**: Staging targets promote to production after verification (`promote_to` field in `.deploy_bot.yml`)
7. **Deploy (production)**: DeployBot runs equivalent production deploy scripts

## Scaling

### App Component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA | min 2, max 15 replicas; target utilization 100% |
| Memory | Limits | Request: 2500Mi (prod), Limit: 4000Mi (prod) |
| CPU | Limits | Request: 80m (prod), no explicit limit |

### Worker Component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed (no HPA scale-out) | min 1, max 1 replica |
| Memory | Limits | Request: 500Mi, Limit: 2000Mi |
| CPU | Limits | Request: 100m |

### Worker-Bulk Component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed (no HPA scale-out) | min 1, max 1 replica |
| Memory | Limits | Request: 500Mi, Limit: 2000Mi |
| CPU | Limits | Request: 1500m (high; bulk CSV processing) |

## Resource Requirements

### App (Production)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 80m | — |
| Memory | 2500Mi | 4000Mi |
| Filebeat CPU | 10m | 30m |
| Filebeat Memory | 80Mi | 200Mi |

### Worker (All Environments)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 100m | — |
| Memory | 500Mi | 2000Mi |

### Worker-Bulk (All Environments)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1500m | — |
| Memory | 500Mi | 2000Mi |

## Ports

| Component | Port | Purpose |
|-----------|------|---------|
| app | 8080 | HTTP API (primary) |
| app | 8081 | Dropwizard admin (health, metrics) |
| app | 8009 | JMX |
| worker | 8009 | JMX |
| worker-bulk | 8009 | JMX |
