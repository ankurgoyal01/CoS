---
service: "seo-local-proxy"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

SEO Local Proxy is fully containerised and deployed to Kubernetes clusters on both GCP and AWS via Deploybot and Jenkins. It comprises two Kubernetes workloads: an Nginx Deployment (`seo-local-proxy--nginx`) serving the static file proxy, and a Kubernetes CronJob (`seo-local-proxy--cron-job`) running daily sitemap generation. Both are deployed via Helm 3 charts (`cmf-generic-cron-job` and `cmf-generic-nginx` at chart version 3.89.0) rendered and applied using `krane`. Deployments target multiple regions for US and EMEA coverage.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (cron job) | Docker | `.ci/Dockerfile` — Node.js 12.6 base, groupon-site-maps cloned at build, Hadoop 2.7.4, Hive 1.2.2, OpenJDK 11.0.2, AWS CLI v2, Google Cloud SDK |
| Container (nginx) | Docker | `docker/nginx/Dockerfile` — nginx-logrotate alpine base with nginx-mod-http-lua, AWS CLI, curl, jq |
| Orchestration | Kubernetes (GCP GKE + AWS EKS) | `.meta/deployment/cloud/scripts/deploy.sh` — Helm 3 + krane (300s timeout) |
| Nginx image | `docker-conveyor.groupondev.com/seo/seo-local-proxy-nginx:0.0.03` | `.meta/deployment/cloud/components/nginx/common.yml` |
| Cron job image | `docker-conveyor.groupondev.com/seo/seo-local-proxy` | `.meta/deployment/cloud/components/cron-job/common.yml` |
| Helm chart (cron job) | `cmf-generic-cron-job` v3.89.0 | Artifactory helm-generic repo |
| Helm chart (nginx) | `cmf-generic-nginx` v3.89.0 | Artifactory helm-generic repo |
| Hybrid Boundary | Groupon Hybrid Boundary (HBU) | Nginx component uses `isDefaultDomain: false` — domain: `seo-local-proxy--nginx` |
| Storage | AWS S3 / GCP Cloud Storage | Regional buckets per environment (see [Data Stores](data-stores.md)) |

## Environments

| Environment | Purpose | Region | Kubernetes Context | URL / VIP |
|-------------|---------|--------|--------------------|-----------|
| dev-us-west-2 | Developer testing (US) | AWS us-west-2 | `seo-local-proxy-dev-us-west-2` | — |
| dev-us-central1 | Developer testing (GCP US) | GCP us-central1 | `seo-local-proxy-gcp-dev-us-central1` | — |
| staging-us-west-2 | Staging (EMEA/AWS) | AWS us-west-2 | `seo-local-proxy-staging-us-west-2` | — |
| staging-us-central1 | Staging (US/GCP) | GCP us-central1 | `seo-local-proxy-gcp-staging-us-central1` | `seo-local-proxy--nginx.us-central1.conveyor.staging.stable.gcp.groupondev.com` |
| staging-europe-west1 | Staging (EMEA/GCP) | GCP europe-west1 | `seo-local-proxy-gcp-staging-europe-west1` | — |
| production-us-central1 | Production US/Canada | GCP us-central1 | `seo-local-proxy-gcp-production-us-central1` | `seo-local-proxy--nginx.us-central1.conveyor.prod.gcp.groupondev.com` |
| production-eu-west-1 | Production EMEA (legacy AWS) | AWS eu-west-1 | `seo-local-proxy-production-eu-west-1` | — |
| production-europe-west1 | Production EMEA (GCP) | GCP europe-west1 | `seo-local-proxy-gcp-production-europe-west1` | `seo-local-proxy--nginx.europe-west1.conveyor.prod.gcp.groupondev.com` |

**Legacy on-prem VIPs** (Capistrano-based, historical):

| Datacenter | Environment | Internal URL |
|------------|-------------|-------------|
| snc1 | production | `http://seo-local-proxy-vip.snc1` |
| snc1 | staging | `http://seo-local-proxy-staging-vip.snc1` |
| snc1 | uat | `http://seo-local-proxy-uat1.snc1` |
| sac1 | production | `http://seo-local-proxy-vip.sac1` |
| dub1 | production | `http://seo-local-proxy-vip.dub1` |

## CI/CD Pipeline

- **Tool**: Jenkins (cloud-jenkins) + Deploybot
- **Config**: `Jenkinsfile` (uses `rubyPipeline` shared library DSL)
- **Trigger**: Push to `main` branch (releasable branch); manual Deploybot dispatch
- **Slack channel**: `seo-deployments`

### Pipeline Stages

1. **Build**: Jenkins `rubyPipeline` builds the Docker image (`seo/seo-local-proxy`) via `cloud-jenkins.groupondev.com/job/seo/job/seo-local-proxy/`
2. **Test**: `.ci/docker-compose.yml` runs test container (Ruby RSpec specs in `scripts/` directory for sitemap and robots.txt validation)
3. **Publish**: Docker image pushed to `docker-conveyor.groupondev.com`
4. **Deploy to staging**: Deploybot auto-promotes to `staging-us-central1` and `staging-europe-west1`
5. **Deploy to production**: Manual promotion via Deploybot from staging (`promote_to` config in `.deploy_bot.yml`)
6. **Render & apply**: `deploy.sh` runs `helm3 template` for both `cron-job` and `nginx` components, applies with `krane deploy` (300s timeout)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Nginx (staging) | HPA | minReplicas: 1, maxReplicas: 2, target: 100% |
| Nginx (production) | Fixed | minReplicas: 1, maxReplicas: 1 |
| Cron Job | Fixed (single pod per run) | minReplicas: 1, maxReplicas: 1 |
| Staging cron job weekend scale-down | cronscaler | Friday 18:00 → 0 replicas; Monday 09:00 → 1–2 replicas |

## Resource Requirements

### Nginx Container

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 50m | — |
| CPU (envoy sidecar) | 500m | — |
| Memory (main) | 200Mi | 2Gi |
| Memory (envoy sidecar) | 500Mi | — |

### Cron Job Container (staging)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 500m | — |
| Memory (main) | 1Gi | 2Gi |

### Cron Job Container (production)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1300m | — |
| Memory (main) | 2Gi | 4Gi |

## Cron Schedule

| Region | Schedule (UTC) | Script |
|--------|---------------|--------|
| US production (us-central1) | `59 11 * * *` (daily at 11:59 UTC) | `daily_us.sh` |
| EMEA production (europe-west1 GCP) | `59 11 * * *` (daily at 11:59 UTC) | `daily_us.sh` (EMEA variant) |
| EMEA production (eu-west-1 AWS) | `59 13 * * *` (daily at 13:59 UTC) | `daily_emea.sh` |
| US staging (us-central1) | `59 11 * * *` | `daily_us_staging.sh` |
