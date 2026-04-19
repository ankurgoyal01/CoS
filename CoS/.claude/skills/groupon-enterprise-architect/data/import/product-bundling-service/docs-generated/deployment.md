---
service: "product-bundling-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, uat, production]
---

# Deployment

## Overview

Product Bundling Service is containerized using Docker and deployed to Kubernetes on GCP (primary cloud) via the Conveyor platform, with additional on-premises VIPs in `snc1` and `sac1` datacenters. CI/CD is managed by Jenkins using the shared `java-pipeline-dsl` library. Deployment promotion flows from staging to production via the `deploy_bot` tool.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — `FROM docker.groupondev.com/jtier/prod-java11-jtier:3` |
| CI Docker image | Docker | `.ci/Dockerfile` — used for CI build container |
| Orchestration | Kubernetes (GCP) | Helm-based deployment via `.meta/deployment/cloud/scripts/deploy.sh` |
| Image registry | Docker (Conveyor) | `docker-conveyor.groupondev.com/deal-platform/product-bundling-service` |
| Load balancer | Kubernetes Service / VIP | HTTP port 8080 (app), admin port 8081 |
| On-prem VIP | Internal VIP | `http://product-bundling-service-vip.snc1` (production), `http://product-bundling-service-staging-vip.snc1` (staging) |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local developer testing | localhost | `http://localhost:9000` (app), `http://localhost:9001` (admin) |
| staging (GCP) | Pre-production integration testing | GCP us-central1 (stable VPC) | `https://product-bundling-service.us-central1.conveyor.stable.gcp.groupondev.com` |
| staging (snc1) | On-prem staging | snc1 | `http://product-bundling-service-staging-vip.snc1` |
| uat (snc1) | User acceptance testing | snc1 | `http://product-bundling-service-uat-vip.snc1` |
| production (GCP) | Live traffic — primary cloud | GCP us-central1 (prod VPC) | `https://product-bundling-service.us-central1.conveyor.prod.gcp.groupondev.com` |
| production (snc1) | Live traffic — on-prem | snc1 | `http://product-bundling-service-vip.snc1` |
| production (sac1) | Live traffic — on-prem secondary | sac1 | `http://product-bundling-service-vip.sac1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch (or branches matching `/^\d+\.\d+\.\d+/`)
- **Shared library**: `java-pipeline-dsl@latest-2`
- **Slack notifications**: `#deal-platform-_robots`

### Pipeline Stages

1. **Build**: `mvn clean package` — compiles source and packages the fat JAR
2. **Test**: Unit and integration tests via Maven Surefire/Failsafe
3. **Docker build and push**: Builds Docker image and pushes to `docker-conveyor.groupondev.com/deal-platform/product-bundling-service`
4. **Deploy to staging**: Triggers Kubernetes deployment to `gcp-stable-us-central1` cluster (`product-bundling-service-gcp-staging-us-central1` context)
5. **Promote to production**: After staging validation, `deploy_bot` promotes to `gcp-production-us-central1` cluster (`product-bundling-service-gcp-production-us-central1` context)

### Deployment Command

```
bash ./.meta/deployment/cloud/scripts/deploy.sh <env>-us-central1 <env> product-bundling-service-<env>
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Staging: min 1 / max 2; Production: min 2 / max 50; HPA target utilization: 100% (common) |
| Memory | Kubernetes resource limits | Request: 2Gi, Limit: 3Gi (`common.yml`) |
| CPU | Kubernetes resource requests | Request: 300m (`main`), 10m (`filebeat`); Limit: 30m (`filebeat`) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 300m | Not set (common.yml) |
| Memory (main) | 2Gi | 3Gi |
| CPU (filebeat sidecar) | 10m | 30m |
| Disk | Not specified | Not specified |

## Application Ports

| Port | Purpose |
|------|---------|
| 8080 | HTTP application port (external, mapped from container port 9000) |
| 8081 | Admin port (exposed as `admin-port`) |
| 9000 | Internal Dropwizard application connector |
| 9001 | Internal Dropwizard admin connector |

## Release Process

Releases are created via Maven Release Plugin:
```
mvn clean release:clean release:prepare release:perform
```
Artifacts are published to the internal Nexus repository. Version scheme: `{major}.{minor}.{patch}` (e.g., `1.0.x`).
