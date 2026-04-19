---
service: "deals-cluster-api-jtier"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-europe-west1, production-eu-west-1]
---

# Deployment

## Overview

The Deals Cluster API is containerized and deployed to GCP Kubernetes clusters using Helm chart `cmf-jtier-api` (version 3.89.0), orchestrated by DeployBot. The service runs as two distinct Kubernetes deployments within the same namespace: an `app` component (serving the REST API) and a `worker` component (running the JMS tagging/untagging workers). Deployments are managed via the `.meta/deployment/cloud/` configuration hierarchy and triggered by git tag creation in DeployBot. CI runs via Conveyor CI (`Jenkins`).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | `docker-conveyor.groupondev.com/com.groupon.mars/deals-cluster-api` |
| CI image | Docker | `docker.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb` (`.ci/Dockerfile`) |
| Orchestration | Kubernetes (GCP) | Helm chart `cmf-jtier-api` v3.89.0 via krane |
| Deployment image | Docker | `docker.groupondev.com/rapt/deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0` |
| Load balancer | Internal VIP | `deals-cluster-vip.<colo>` (on-prem), GKE ingress (cloud) |
| CDN | none | Internal service only |
| Local dev | Docker Compose | `docker-compose.yml`, `docker/postgres/` (Postgres + PgBouncer) |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-central1 | Staging (US) | GCP us-central1 (stable VPC) | `http://deals-cluster-staging.snc1` |
| staging-europe-west1 | Staging (EU) | GCP europe-west1 (stable VPC) | — |
| production-us-central1 | Production (US) | GCP us-central1 (prod VPC) | `http://deals-cluster-vip.snc1` |
| production-europe-west1 | Production (EU) | GCP europe-west1 (prod VPC) | — |
| production-eu-west-1 | Production (EMEA) | AWS eu-west-1 | `http://deals-cluster-vip.dub1` |

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI)
- **Config**: `.ci.yml` (CI config), `Jenkinsfile` (Jenkins pipeline)
- **Trigger**: Pull request merge to `main` branch triggers CI build; git tag creation triggers DeployBot deployment

### Pipeline Stages

1. **Build**: `mvn clean verify` (compiles, runs tests, generates artifacts)
2. **Test**: JUnit, FindBugs, PMD, JaCoCo code coverage via plugins declared in `.ci.yml`
3. **Artifact**: Maven builds the JAR; Docker image is published to Conveyor artifact registry
4. **Tag**: Engineer creates git tags in format `staging-<major>.<minor>.<date>_<sha>` (staging) or `production_<colo>-<tag>#<GPROD>` (production)
5. **Deploy (Staging)**: DeployBot triggers `deploy.sh staging-us-central1 staging deals-cluster-staging` via Helm + krane
6. **Promote**: Staging deployment is promoted to production via DeployBot UI
7. **Deploy (Production)**: DeployBot triggers `deploy.sh production-us-central1 production deals-cluster-production` via Helm + krane
8. **Verify**: Monitor Wavefront dashboards post-deployment

### Deployment Script

`.meta/deployment/cloud/scripts/deploy.sh` renders two Helm charts (app + worker) and applies them with `krane deploy` targeting the environment namespace.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (app, staging) | HPA | min=1, max=2, targetUtilization=100% |
| Horizontal (app, production US) | HPA | min=4, max=10 |
| Horizontal (app, production EU) | HPA | min=2, max=10 |
| Horizontal (worker, all) | Fixed | min=3, max=3, targetUtilization=100% |
| VPA | Enabled (app + worker) | `enableVPA: true` |

## Resource Requirements

### App Component

| Resource | Request (staging) | Request (production US) | Limit (production US) |
|----------|-------------------|--------------------------|-----------------------|
| CPU | 50m (default) | 2000m | — |
| Memory | 1Gi (default) | 5Gi | 6Gi |

### Worker Component

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 50m (default) | — |
| Memory | 2Gi | 3Gi |

## Ports

| Port | Purpose |
|------|---------|
| 8080 | HTTP (application) |
| 8081 | Admin/metrics port |
