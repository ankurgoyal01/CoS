---
service: "elit-github-app"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev-us-west-1, dev-us-west-2, staging-us-central1, staging-us-west-1, staging-us-west-2, rde-dev-us-west-2, rde-staging-us-west-2, production-us-west-1, production-eu-west-1]
---

# Deployment

## Overview

The ELIT GitHub App is deployed as a containerised JVM service on Kubernetes. The container image is built on `docker.groupondev.com/jtier/prod-java17-alpine-jtier:3` (JVM 17, Alpine-based). Deployment is managed by the Groupon Conveyor platform using the `.meta/deployment/cloud/` manifest structure. The Jenkins pipeline handles build, test, Docker image push, and deployment to target environments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — FROM `docker.groupondev.com/jtier/prod-java17-alpine-jtier:3` |
| Image registry | Groupon Docker registry | `docker-conveyor.groupondev.com/alasdair/elit-github-app` |
| Orchestration | Kubernetes (Conveyor) | `.meta/deployment/cloud/` manifests; tenant: `elit-github-app` |
| Deploy bot | Groupon Deploy Bot v2 | `.deploy_bot.yml` — uses `docker.groupondev.com/rapt/deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0` |
| Load balancer | Hybrid Boundary (Groupon sidecar) | Port 8080 (HTTP); admin port 8081 |
| CDN | None identified | — |

## Environments

| Environment | Purpose | Region | Cluster |
|-------------|---------|--------|---------|
| dev-us-west-1 | Development | us-west-1 | — |
| dev-us-west-2 | Development | us-west-2 | — |
| staging-us-central1 | Staging (primary deploy target) | us-central1 | `gcp-stable-us-central1` |
| staging-us-west-1 | Staging | us-west-1 | — |
| staging-us-west-2 | Staging | us-west-2 | — |
| rde-dev-us-west-2 | RDE development | us-west-2 | — |
| rde-staging-us-west-2 | RDE staging | us-west-2 | — |
| production-us-west-1 | Production | us-west-1 | — |
| production-eu-west-1 | Production (EU) | eu-west-1 | — |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` — uses `java-pipeline-dsl@latest-2` shared library
- **Trigger**: On push to `main` branch or branches matching `.*-releasable`

### Pipeline Stages

1. **Build**: Maven build (`mvn clean package`) compiling Java 17 sources
2. **Test**: Unit tests via Maven Surefire with JaCoCo coverage
3. **Docker build**: Builds image using `src/main/docker/Dockerfile`
4. **Docker push**: Pushes image to `docker-conveyor.groupondev.com/alasdair/elit-github-app`
5. **Deploy**: Deploys to `staging-us-central1` as the primary automated deploy target via `.meta/deployment/cloud/scripts/deploy.sh`

Deploy bot manual deployments are supported for all additional environments listed in `.meta/deployment/cloud/components/api/`.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Target utilisation: 90% (`hpaTargetUtilization: 90` in `common.yml`) |
| Horizontal (dev) | Manual (fixed) | min: 1, max: 1 |
| Horizontal (staging) | Manual (fixed) | min: 2, max: 2 |
| Horizontal (production-us-west-1) | HPA | min: 2, max: 3 |
| Horizontal (production-eu-west-1) | Fixed | min: 3, max: 3 |
| Memory | Limits | Request: 500Mi, Limit: 500Mi (from `common.yml`) |
| CPU | Limits | Request: 300m (from `common.yml`) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 300m | Not set (no limit defined in `common.yml`) |
| Memory | 500Mi | 500Mi |
| Disk | Not specified | Not specified |
