---
service: "badges-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-europe-west1, production-eu-west-1]
---

# Deployment

## Overview

The Badges Service is containerized with Docker and deployed on Kubernetes via the Groupon **Conveyor** internal PaaS. It runs in GCP across two production regions (us-central1 and europe-west1) and two staging regions. There is a separate legacy on-prem EU region (`eu-west-1`). The service is split into two Kubernetes deployment components: `api` (stateless request handlers, ENABLE_JOBS=false, horizontally scaled) and `jobs` (background job runner, ENABLE_JOBS=true, single replica).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (production) | Docker | `src/main/docker/Dockerfile` — base image `docker.groupondev.com/jtier/prod-java11-jtier:3` |
| Container (CI/build) | Docker | `.ci/Dockerfile` — base image `docker.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb` |
| Container registry | Conveyor registry | `docker-conveyor.groupondev.com/deal-platform/badges-service` |
| Orchestration | Kubernetes (Conveyor PaaS) | Manifests in `.meta/deployment/cloud/components/api/` and `.meta/deployment/cloud/components/jobs/` |
| Service mesh / proxy | Envoy sidecar | Included in pod spec; CPU request 450m (api), 50m (jobs) |
| Log shipper | Filebeat sidecar | Log dir `/var/groupon/jtier/logs`, file `jtier.steno.log`, source type `badges_service_app` |
| Metrics collector | Telegraf sidecar | CPU request 300m; pushes JVM and custom metrics to Wavefront |
| APM | Enabled | `apm.enabled: true` across all environments |

## Environments

| Environment | Purpose | Region | VIP / URL |
|-------------|---------|--------|-----------|
| staging-us-central1 | Pre-production validation | GCP us-central1 (stable VPC) | `badges-service.us-central1.conveyor.stable.gcp.groupondev.com` |
| staging-europe-west1 | Pre-production validation | GCP europe-west1 (stable VPC) | `badges-service.europe-west1.conveyor.stable.gcp.groupondev.com` |
| production-us-central1 | Production (US) | GCP us-central1 (prod VPC) | `badges-service.us-central1.conveyor.prod.gcp.groupondev.com` |
| production-europe-west1 | Production (EU) | GCP europe-west1 (prod VPC) | `badges-service.europe-west1.conveyor.prod.gcp.groupondev.com` |
| production-eu-west-1 | Production (legacy on-prem EU) | AWS eu-west-1 | Deployment manifests in `.meta/deployment/cloud/components/api/production-eu-west-1.yml` |

## CI/CD Pipeline

- **Tool**: Jenkins (JTier `jtierPipeline` shared library)
- **Config**: `Jenkinsfile`
- **Trigger**: On push to `master` branch; releasable PRs for specific branches
- **Slack notifications**: `#deal-platform-_robots`
- **Docker build**: `skipDocker: false`

### Pipeline Stages

1. **Build**: `docker-compose -f .ci/docker-compose.yml build` — builds the CI container image
2. **Test**: `mvn -U -B clean verify` inside CI container — runs unit tests (Spock + JUnit), integration tests, and code quality checks (JaCoCo coverage ≥ 70%, PMD, FindBugs)
3. **Package**: Maven builds the JAR artifact and Docker image tagged `docker-conveyor.groupondev.com/deal-platform/badges-service`
4. **Deploy (staging)**: Automatically deploys to `staging-us-central1` and `staging-europe-west1` on successful merge to `master`
5. **Deploy (production)**: Manual promotion via Conveyor deploy tooling (`deploy.sh`)

## Scaling

### API component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | min: 3 / max: 15 (common); max: 20 (production); target CPU utilization: 60% |
| VPA | Disabled | `enableVPA: false` |
| Memory | Limits configured | Request: 4Gi (common), 6Gi (production us-central1) / Limit: 6Gi (common), 8Gi (production us-central1) |
| CPU | Limits configured | Request: 1500m / Limit: 2000m |

### Jobs component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed single replica | min: 1 / max: 1; HPA target: 100% |
| Memory | Limits configured | Request: 4Gi / Limit: 4Gi |
| CPU | Limits configured | Request: 1200m / Limit: 1200m |

## Resource Requirements

### API component (common)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1500m | 2000m |
| Memory (main) | 4Gi (common), 6Gi (production) | 6Gi (common), 8Gi (production) |
| CPU (Filebeat) | 150m | 700m |
| Memory (Filebeat) | 100Mi | 400Mi |

### Jobs component

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1200m | 1200m |
| Memory (main) | 4Gi | 4Gi |
| CPU (Filebeat) | 100m | 500m |
| Memory (Filebeat) | 100Mi | 400Mi |

## Port Configuration

| Port | Purpose |
|------|---------|
| 8080 | HTTP application port (exposed as port 80 via Kubernetes service) |
| 8081 | Admin/management port |
| 8070 | JTier status endpoint (`/grpn/status`) |
