---
service: "forex-ng"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Forex NG runs as a containerized Java service on Kubernetes. In cloud production, it is deployed as a Kubernetes **cron job** (`component: cron-job`) using the `cmf-generic-cron-job` Helm chart. The cron job runs the `refresh-rates` CLI command on a schedule (`*/11 * * * *`) to periodically refresh exchange rates. The HTTP server component (for API serving) is managed separately. Deployments span two cloud providers — AWS (us-west-1, eu-west-1) and GCP (us-central1, europe-west1) — as well as legacy snc1/sac1/dub1 datacenters. Deployments are managed via DeployBot using the `deploy_kubernetes` deploy image.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` (runtime); `.ci/Dockerfile` (build); base image: `docker.groupondev.com/jtier/prod-java11-jtier:2023-12-19-609aedb` |
| Orchestration | Kubernetes | Helm chart `cmf-generic-cron-job` version `3.89.0`; manifests in `.meta/deployment/cloud/components/cron-job/` |
| Load balancer | VIP (snc1/sac1/dub1 legacy) | `http://forex-vip.snc1`, `http://forex-vip.sac1`, `http://forex-vip.dub1` |
| CDN | None | Not applicable |
| Metrics | Telegraf | Per-environment Telegraf URL in deployment manifests; flush every 10s |
| Logging | Filebeat + Kafka | Steno JSON logs shipped to `kafka-elk-broker.snc1` (prod) or `kafka-elk-broker-staging.snc1` (staging) |

## Environments

| Environment | Purpose | Region / Cluster | URL |
|-------------|---------|-----------------|-----|
| development | Local development | Local JVM | `http://localhost:9000` |
| staging (AWS us-west-1) | Pre-production validation | AWS us-west-1 | `http://forex-vip-staging.snc1` |
| staging (GCP europe-west1) | Pre-production EMEA validation | GCP europe-west1 (`gcp-stable-europe-west1`) | — |
| staging (GCP us-central1) | Pre-production US validation | GCP us-central1 (`gcp-stable-us-central1`) | — |
| production (AWS us-west-1) | US/Canada production | AWS us-west-1 | `http://forex-vip.snc1` |
| production (AWS eu-west-1) | EMEA production | AWS eu-west-1 | `http://forex-vip.dub1` |
| production (GCP us-central1) | US/Canada production (GCP) | GCP us-central1 (`gcp-production-us-central1`) | — |
| production (GCP europe-west1) | EMEA production (GCP) | GCP europe-west1 (`gcp-production-europe-west1`) | — |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (in repository root)
- **Deploy tool**: DeployBot
- **DeployBot config**: `.deploy_bot.yml`
- **Trigger**: On push to `master` branch; manual via DeployBot

### Pipeline Stages

1. **Build**: `docker-compose -f .ci/docker-compose.yml run -T test mvn -U -B clean verify` — compile, unit test, integration test, code quality (PMD, FindBugs, JaCoCo)
2. **Docker image build and push**: JTier Maven plugin builds Docker image and pushes to `docker-conveyor.groupondev.com/orders/forex`
3. **Deploy to staging**: DeployBot runs `helm3 template cmf-generic-cron-job` + `krane deploy forex-staging` for the target staging cluster
4. **Promote to production**: DeployBot promotes from staging environment to corresponding production environment (configured via `promote_to` in `.deploy_bot.yml`)
5. **Deploy to production**: `helm3 template cmf-generic-cron-job` + `krane deploy forex-production` with `--global-timeout=600s`

### Promotion Chain

- `staging-europe-west1` promotes to `production-eu-west-1`
- `staging-us-central1` promotes to `production-us-central1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes cron job (not a long-running pod; runs on schedule) | One pod per scheduled run |
| Vertical Pod Autoscaler | Disabled | `enableVPA: false` (in `common.yml`) |
| Memory | Static request/limit | Request: 1Gi, Limit: 2Gi (common); overridable per environment |
| CPU | Static request/limit (override in production) | Common: 300m request; Production cloud: 1500m request / 2000m limit |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 300m (default) / 1500m (production cloud) | 2000m (production cloud) |
| Memory | 1Gi | 2Gi |
| Disk | Not specified | Not specified |

## AWS S3 Bucket Provisioning

The forex S3 bucket is provisioned via the AWS Service Catalog product `ConveyorS3Bucket` (version `v1.4`) declared in each cloud environment's deployment YAML under `serviceCatalogProducts`. Key parameters:

| Parameter | Value |
|-----------|-------|
| `S3BucketName` | `forex` |
| `S3NonAuthReadFromHB` | `true` (allows non-authenticated reads from the Groupon HB network) |
| `serviceIAMRoleName` | `forex-job` |
