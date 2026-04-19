---
service: "seo-local-proxy"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values, yaml-config-files]
---

# Configuration

## Overview

SEO Local Proxy is configured through a combination of Kubernetes deployment YAML files (under `.meta/deployment/cloud/`), environment variables injected at deploy time via Helm chart templates, and Nginx configuration embedded in the `common.yml` deployment manifest. Secrets (AWS IAM role ARNs, GCP service accounts) are handled through Kubernetes secrets managed by the Convey platform and referenced by name in deployment YAMLs.

## Environment Variables

### Cron Job Component

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Selects the Node.js environment for `groupon-site-maps` scripts (`production`, `staging`, `dev`) | yes | none | helm / `.meta/deployment/cloud/components/cron-job/{env}.yml` |
| `CLOUD_ENV_REGION` | Identifies the deployment region (e.g., `production-us-central1`) | yes | none | helm / region-specific yml |
| `GCP_BUCKET_PROJECT_NAME` | GCP project hosting the Cloud Storage bucket | yes (GCP envs) | none | helm / region-specific yml |
| `GCP_BUCKET_NAME` | Name of the GCP Cloud Storage bucket for uploads | yes (GCP envs) | none | helm / region-specific yml |
| `SEO_LOCAL_PROXY_S3_BUCKET_NAME` | AWS S3 bucket name for uploads and verification | yes (AWS envs) | none | helm / region-specific yml or pod env |
| `AWS_DEFAULT_REGION` | AWS region for S3 operations | yes (AWS envs) | none | helm / region-specific yml |
| `AWS_REGION` | AWS region (alternate var used by AWS SDK) | yes (AWS envs) | none | helm / region-specific yml |
| `AWS_PAGER` | Disables paging output from AWS CLI | no | `""` | `.meta/deployment/cloud/components/cron-job/common.yml` |
| `JAVA_HOME` | Path to OpenJDK installation for Hadoop/Hive | yes | `/root/local_proxy/jdk-11.0.2` | `common.yml` |
| `HADOOP_HOME` | Path to Hadoop installation | yes | `/root/local_proxy/hadoop-2.7.4` | `common.yml` |
| `HIVE_HOME` | Path to Apache Hive installation | yes | `/root/local_proxy/apache-hive-1.2.2-bin` | `common.yml` |

### Nginx Component

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Environment identifier passed into Nginx container | yes | none | helm / region-specific yml |

### Nginx Runtime Variables (resolved per-request, not env vars)

| Variable | Purpose | Source |
|----------|---------|--------|
| `$http_x_forwarded_host` | Incoming host header set by `routing-service`; used to derive `$country` and `$website` | Nginx header map |
| `$country` | ISO 2-letter country code resolved from `$http_x_forwarded_host` TLD (e.g., `US`, `DE`, `GB`) | Nginx `map` directive |
| `$website` | Brand directory resolved from `$http_x_forwarded_host` (one of: `https`, `livingsocial`, `speedgroupon`) | Nginx `map` directive |
| `$environment` | `production` or `staging` resolved from `$host` | Nginx `map` directive |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. No feature flag system (LaunchDarkly, Unleash, etc.) is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/nginx/common.yml` | YAML | Nginx container Helm values — image version, resource limits, full Nginx configuration block, Hybrid Boundary settings, log config |
| `.meta/deployment/cloud/components/nginx/{env-region}.yml` | YAML | Environment/region overrides for Nginx (VIP, replica counts, NODE_ENV) |
| `.meta/deployment/cloud/components/cron-job/common.yml` | YAML | Cron job Helm values — app image, env vars (JAVA_HOME, HADOOP_HOME, HIVE_HOME), resource limits, log config, probes |
| `.meta/deployment/cloud/components/cron-job/{env-region}.yml` | YAML | Environment/region overrides for cron job (jobSchedule, NODE_ENV, bucket names, mainContainerCommand) |
| `cloud/cloud-crontab-us` | cron | Legacy crontab expression for US generation: `59 11 * * *` (runs `daily_us.sh`) |
| `cloud/cloud-crontab-emea` | cron | Legacy crontab expression for EMEA generation: `59 12 * * *` (runs `daily_emea.sh`) |
| `.deploy_bot.yml` | YAML | Deploybot targets — Kubernetes cluster, context, region, and deployment command per environment |
| `Jenkinsfile` | Groovy | Jenkins pipeline — `rubyPipeline` DSL, targets `staging-us-central1` and `staging-europe-west1` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| GCP Service Account `con-sa-seo-local-proxy@prj-grp-central-sa-prod-0b25.iam.gserviceaccount.com` | Authorises cron job to write to GCP Cloud Storage buckets | GCP IAM / k8s-secret (Conveyor-managed) |
| AWS IAM Role `arn:aws:iam::497256801702:role/grpn-conveyor-seo-sitemap-s3-production-eu-west-1` | Authorises cron job to write to AWS S3 bucket in eu-west-1 | AWS IAM / k8s-secret (Conveyor-managed) |
| `.meta/deployment/cloud/secrets/cloud/{env}.yml` | Per-environment secret values injected via Helm at deploy time | k8s-secret (Conveyor-managed) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Staging (us-central1) | Production (us-central1) | Production (europe-west1 / eu-west-1 EMEA) |
|---------|----------------------|--------------------------|---------------------------------------------|
| `NODE_ENV` | `staging` | `production` | `production` |
| `GCP_BUCKET_NAME` | `con-stable-usc1-seo-local-proxy` | `con-prod-usc1-seo-local-proxy` | `con-prod-euw1-seo-local-proxy-emea` |
| `GCP_BUCKET_PROJECT_NAME` | `con-grp-seo-proxy-stable-b3f4` | `con-grp-seo-proxy-prod-c1b3` | `con-grp-seo-proxy-prod-c1b3` |
| `jobSchedule` | `59 11 * * *` | `59 11 * * *` | `59 11 * * *` (GCP) / `59 13 * * *` (AWS eu-west-1) |
| `mainContainerCommand` | `daily_us_staging.sh` | `daily_us.sh` | `daily_emea.sh` |
| CPU request (cron job) | 500m | 1300m | 1300m |
| Memory request/limit (cron job) | 1Gi / 2Gi | 2Gi / 4Gi | 2Gi / 4Gi |
| Nginx VIP | `seo-local-proxy--nginx.us-central1.conveyor.staging.stable.gcp.groupondev.com` | `seo-local-proxy--nginx.us-central1.conveyor.prod.gcp.groupondev.com` | `seo-local-proxy--nginx.europe-west1.conveyor.prod.gcp.groupondev.com` |
| Nginx replicas | 1–2 (HPA) | 1 (fixed) | 1 (fixed) |
