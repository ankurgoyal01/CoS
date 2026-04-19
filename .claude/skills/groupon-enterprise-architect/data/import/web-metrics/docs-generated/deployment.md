---
service: "web-metrics"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging-us-central1", "staging-us-west-1", "staging-us-west-2", "staging-europe-west1", "production-us-west-1", "production-us-central1", "production-eu-west-1", "production-europe-west1"]
---

# Deployment

## Overview

Web Metrics is deployed as a Docker container running as a Kubernetes CronJob via Groupon's Conveyor Cloud (GCP and AWS-backed). It runs on the `cmf-generic-cron-job` Helm chart (version 3.80.5) managed by `napistrano`. The job fires twice per hour (at minutes 10 and 40) and restarts on failure. There is no inbound load balancer — the job is purely outbound. Deployment is triggered by CI on merge to `main` and promoted manually from staging to production.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (node:18 base) | `Dockerfile` at repo root; image published to `docker-conveyor.groupondev.com/seo/web-metrics` |
| Orchestration | Kubernetes CronJob | Managed via `cmf-generic-cron-job` Helm chart v3.80.5; deployed with `krane` |
| Helm chart | `cmf-generic-cron-job` | Sourced from `http://artifactory.groupondev.com/artifactory/helm-generic/` |
| Deployment tool | napistrano v2.181.8 + Deploybot | Generates Helm manifests and applies with krane |
| Log shipping | Filebeat sidecar + Kafka | Logs shipped to Kafka topic `logging_{env}_` index `steno`; Splunk sourcetype `web-metrics_cron-job` |
| CI | Jenkins (Conveyor CI) | `Jenkinsfile` at repo root |

## Environments

| Environment | Purpose | Cloud / Region | Namespace |
|-------------|---------|----------------|-----------|
| `staging-us-central1` | Primary staging (auto-deployed on merge to main) | GCP us-central1 | `web-metrics-staging` |
| `staging-us-west-1` | Secondary staging | AWS us-west-1 | `web-metrics-staging` |
| `staging-us-west-2` | Secondary staging (RDE-compatible) | AWS us-west-2 | `web-metrics-staging` |
| `staging-europe-west1` | EMEA staging | GCP europe-west1 | `web-metrics-staging` |
| `production-us-central1` | Primary production (US/Canada) | GCP us-central1 | `web-metrics-production` |
| `production-us-west-1` | Secondary production (US/Canada) | AWS us-west-1 | `web-metrics-production` |
| `production-eu-west-1` | Primary production (EMEA) | AWS eu-west-1 | `web-metrics-production` |
| `production-europe-west1` | Secondary production (EMEA) | GCP europe-west1 | `web-metrics-production` |

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI) with `@Library('conveyor@latest-5')`
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: On pull request and on push to `main` branch

### Pipeline Stages

1. **tests (parallel)**: Runs `npm cit` in both Node 16 and Node 18 Docker containers (PR branches only)
2. **deploy**: Builds Docker image and deploys to `staging-us-central1` via `dockerBuildPipeline` (main branch only)
3. **publish**: Runs `npm cit` then `npx nlm release --commit` to publish the npm package to `https://npm.groupondev.com` (main branch only)

Production deployments are promoted manually from staging via Deploybot (`https://deploybot.groupondev.com/seo/web-metrics`).

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Manual via Helm replicas | min: 1, max: 3 |
| Horizontal (production) | Manual via Helm replicas | min: 2, max: 3 |
| Memory (staging) | Fixed limit | Request: 2048Mi, Limit: 4096Mi |
| Memory (production) | Fixed limit | Request: 1536Mi, Limit: 3072Mi |
| CPU | Fixed request | Request: 1000m (main container) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m | No limit set |
| Memory (main, production) | 1536Mi | 3072Mi |
| Memory (main, staging) | 2048Mi | 4096Mi |
| CPU (filebeat sidecar) | 400m | 750m |
| Memory (filebeat sidecar) | 200Mi (low) – 600Mi (high) | 200Mi – 600Mi |

## CronJob Schedule

- **Schedule**: `10,40 * * * *` — runs twice per hour, at 10 and 40 minutes past each hour
- **Restart policy**: `OnFailure` — the pod restarts on failure up to 6 times (Kubernetes default backoff) before terminating
- **Readiness probe**: `exec: echo 'true'` — delay 20 s, period 5 s
- **Liveness probe**: `exec: echo 'true'` — delay 30 s, period 15 s
