---
service: "janus-schema-inferrer"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1-kafka, staging-us-central1-mbus, production-us-central1-kafka, production-us-central1-mbus, production-eu-west-1-kafka]
---

# Deployment

## Overview

Janus Schema Inferrer is deployed as a Kubernetes CronJob on GCP (us-central1) and AWS (eu-west-1). Each deployment target is a separate CronJob instance distinguished by inferrer type (`kafka` or `mbus`) and region. The CronJob runs hourly (`0 * * * *`), executes a single batch run, and exits. It runs as a single replica with no horizontal scaling. Container images are published to Groupon's internal Docker registry via the JTier Jenkins pipeline. Deployment is managed via `deploy_bot` with Helm (`cmf-generic-cron-job` chart v3.88.1) and `krane`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` (base: `docker.groupondev.com/jtier/prod-java11-jtier:3`) |
| Container registry | Groupon internal Docker registry | `docker-conveyor.groupondev.com/data-engineering/janus-schema-inferrer` |
| Orchestration | Kubernetes CronJob | Helm chart `cmf-generic-cron-job v3.88.1`; manifests in `.meta/deployment/cloud/` |
| Deployment tool | krane + Helm 3 | `.meta/deployment/cloud/scripts/deploy.sh` |
| CI/CD bot | deploy_bot v2 | `.deploy_bot.yml` — triggers krane deployment |
| CI pipeline | Jenkins | `Jenkinsfile` — `jtierPipeline` shared library |
| Load balancer | None | CronJob workers — no inbound traffic |
| CDN | None | No web-facing traffic |

## Environments

| Environment | Purpose | Region | VIP / URL |
|-------------|---------|--------|-----------|
| `staging-us-central1-kafka` | Staging validation — Kafka mode | GCP us-central1 | `janus-schema-inferrer.staging.service.us-central1.gcp.groupondev.com` |
| `staging-us-central1-mbus` | Staging validation — MBus mode | GCP us-central1 | `janus-schema-inferrer.staging.service.us-central1.gcp.groupondev.com` |
| `production-us-central1-kafka` | Production — Kafka mode | GCP us-central1 | `janus-schema-inferrer.us-central1.conveyor.production.gcp.groupondev.com` |
| `production-us-central1-mbus` | Production — MBus mode | GCP us-central1 | `janus-schema-inferrer.us-central1.conveyor.production.gcp.groupondev.com` |
| `production-eu-west-1-kafka` | Production — Kafka mode (EMEA) | AWS eu-west-1 | (no VIP configured — internal only) |

## CI/CD Pipeline

- **Tool**: Jenkins (JTier shared library `java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main`, `release`, `deploytest`, `janus-3557` branches; or manual dispatch

### Pipeline Stages

1. **Build**: `mvn clean verify` — compiles Java/Scala sources, runs ScalaTest tests, builds Docker image
2. **Docker push**: Pushes image to `docker-conveyor.groupondev.com/data-engineering/janus-schema-inferrer`
3. **Deploy to staging (Kafka)**: Auto-deploys `staging-us-central1-kafka` via deploy_bot
4. **Deploy to staging (MBus)**: Auto-deploys `staging-us-central1-mbus` via deploy_bot
5. **Promote to production (Kafka EU)**: Auto-deploys `production-eu-west-1-kafka` (listed in `deployTarget`)
6. **Promote to production (Kafka/MBus US)**: Manual promotion from staging targets via deploy_bot (`promote_to` in `.deploy_bot.yml`)

> Staging Kafka and MBus targets auto-promote to their respective production US-Central1 counterparts via `promote_to` in `.deploy_bot.yml`.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed — single replica | `minReplicas: 1`, `maxReplicas: 1`, `parallelism: 1` |
| Memory | Fixed limit | Request: 10 Gi, Limit: 15 Gi (production); 500 Mi / 1 Gi for filebeat sidecar |
| CPU | Fixed request | Request: 2000m (2 vCPU) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 2000m | No explicit limit |
| Memory (main) | 10 Gi | 15 Gi |
| Memory (filebeat) | 500 Mi | 1 Gi |
| Disk | Not specified | Not specified |

## CronJob Configuration

| Parameter | Value |
|-----------|-------|
| Schedule | `0 * * * *` (hourly, top of the hour) |
| Restart policy | `OnFailure` |
| Backoff limit | 3 (Kafka), 3–5 (MBus) |
| Max global timeout (krane) | 300 seconds |

## Health Probes

| Probe | Type | Mechanism | Delay | Period |
|-------|------|-----------|-------|--------|
| Readiness | exec | `pgrep java` | 20s | 5s |
| Liveness | exec | `cat /var/groupon/jtier/schema_inferrer_health.txt` | 45s | 15s |
