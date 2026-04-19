---
service: "ugc-api"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [local, staging-us-central1, staging-europe-west1, staging-us-west-2, production-us-central1, production-eu-west-1, production-europe-west1]
---

# Deployment

## Overview

The UGC API is deployed as a Docker container (JTier prod-java11-jtier base image) on Kubernetes clusters across multiple GCP and AWS regions. Deployment is orchestrated via Helm 3 with the `cmf-jtier-api` chart (version 3.92.0) and applied using `krane`. The CI/CD pipeline runs on Jenkins (JTier shared library). The service is identified as `ugc-api-jtier` in the Groupon service registry. APM is enabled.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — base image `docker.groupondev.com/jtier/prod-java11-jtier:3`; curl installed for health checks |
| CI build image | Docker | `.ci/Dockerfile` — `docker.groupondev.com/jtier/dev-java11-maven:2021-10-14-2047f4d` |
| Orchestration | Kubernetes | Helm 3 chart `cmf-jtier-api:3.92.0` via `.meta/deployment/cloud/scripts/deploy.sh` |
| Deployment tool | krane | Applied via `krane deploy ugc-api-jtier-{env} {context}` with 300s timeout |
| Load balancer | VIP (Groupon Conveyor) | Per-environment VIP DNS (e.g., `ugc-api-jtier.us-central1.conveyor.prod.gcp.groupondev.com`) |
| Log shipper | Filebeat sidecar | Configured in deployment manifests; JSON log format; source type `ugc_api_steno` |
| APM | Groupon APM | Enabled (`apm.enabled: true` in `common.yml`) |
| Admin port | 8081 (Dropwizard admin) | Exposed as `admin-port` |
| JMX port | 8009 | Exposed as `jmx-port` |

## Environments

| Environment | Purpose | Region / Cloud | URL / VIP |
|-------------|---------|----------------|-----------|
| local | Developer local run | localhost | `java -jar target/ugc-api-*.jar server development.yml` |
| staging-us-central1 | Pre-production US | GCP us-central1 (stable VPC) | `ugc-api-jtier.us-central1.conveyor.stable.gcp.groupondev.com` |
| staging-europe-west1 | Pre-production EU | GCP europe-west1 (stable VPC) | Configured in `staging-europe-west1.yml` |
| staging-us-west-2 | Pre-production US-West | AWS us-west-2 | Configured in `staging-us-west-2.yml` |
| production-us-central1 | Production US | GCP us-central1 (prod VPC) | `ugc-api-jtier.us-central1.conveyor.prod.gcp.groupondev.com` |
| production-eu-west-1 | Production EU (AWS) | AWS eu-west-1 (dub1) | Kubernetes cluster `production-eu-west-1` |
| production-europe-west1 | Production EU (GCP) | GCP europe-west1 | Kubernetes cluster `gcp-production-europe-west1` |

## CI/CD Pipeline

- **Tool**: Jenkins (JTier shared library `java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `release`, `main`, or named releasable branches; releasable PRs also supported
- **Agent**: M52xlarge Jenkins agent type
- **Slack notifications**: `#ugc-notifications` channel

### Pipeline Stages

1. **Build**: Maven clean package on M52xlarge agent (`mvn clean package`)
2. **Test**: Unit and integration tests with JaCoCo coverage reporting
3. **Docker build and push**: Docker image built and pushed to `docker-conveyor.groupondev.com/usergeneratedcontent/ugc-api`
4. **Deploy to staging**: Automatic deploy to `staging-europe-west1` and `staging-us-central1` via `.meta/deployment/cloud/scripts/deploy.sh`
5. **Promote to production**: Via deploy-bot (`production-eu-west-1`, `production-europe-west1`, `production-us-central1`) using `.deploy_bot.yml` targets

### Promote-to-Production Targets

| Staging | Promotes To |
|---------|-------------|
| `staging-us-central1` | `production-us-central1` |
| `staging-europe-west1` | `production-eu-west-1` |

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | HPA | Min: 1 replica, Max: 2 replicas |
| Horizontal (production) | HPA | Min: 3 replicas, Max: 50 replicas (common baseline: 5–10) |
| HPA target utilization | CPU-based | 40% (from `common.yml`) |
| VPA | Disabled | `enableVPA: false` in environment configs |

## Resource Requirements

### Production (GCP us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 3000m | Not specified (no limit in manifest) |
| Memory (main) | 9 Gi | 10 Gi |
| CPU (filebeat) | 275m | 350m |
| Memory (filebeat) | 450 Mi | 500 Mi |

### Staging (GCP us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m | Not specified |
| Memory (main) | 6 Gi | 6 Gi |
| CPU (filebeat) | 330m | 670m |
| Memory (filebeat) | 500 Mi | 1 Gi |

### Baseline (common.yml defaults)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m | Not specified |
| Memory (main) | 2 Gi | 20 Gi |
| CPU (filebeat) | 200m | 600m |
| Memory (filebeat) | 100 Mi | 500 Mi |
| JVM heap | 70% of container memory | 70% of container memory |
