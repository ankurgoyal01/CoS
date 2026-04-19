---
service: "coupons-revproc"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secret]
---

# Configuration

## Overview

coupons-revproc is configured through a combination of environment variables (injected by Kubernetes) and a YAML runtime configuration file referenced by the `JTIER_RUN_CONFIG` environment variable. The YAML file is environment-specific and contains all structured config blocks (MySQL, Redis, AffJet, Salesforce, VoucherCloud, MessageBus, Quartz, Dotidot, CouponsFeed, CouponsRedirectSanitizer). Secrets (credentials, tokens) are stored in a private secrets repository and injected as Kubernetes secrets at deploy time; they are never committed to this repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the environment-specific YAML config file | yes | `/var/groupon/jtier/config/cloud/<env>-<region>.yml` | Kubernetes env (deployment YAML) |
| `JTIER_RUN_CMD` | Command override for cron job containers (e.g., `coupons-feed-generator --`) | yes (cron containers only) | — | Kubernetes env (deployment YAML) |
| `IS_CRON_JOB` | Signals that the container is running as a batch job rather than a long-running API server | yes (cron containers only) | `false` | Kubernetes env (deployment YAML) |
| `ACTIVE_COLO` | Datacenter/colo identifier (legacy; set in base Dockerfile) | no | `snc1` | Dockerfile ENV |
| `ACTIVE_ENV` | Environment identifier (legacy; set in base Dockerfile) | no | `development` | Dockerfile ENV |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `affjet.enabled` | Enables or disables AffJet ingestion globally; set in the YAML config block | `true` (in production) | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `/var/groupon/jtier/config/cloud/production-us-central1.yml` | YAML | Production US config — referenced by `JTIER_RUN_CONFIG` in GCP us-central1 pods |
| `/var/groupon/jtier/config/cloud/production-europe-west1.yml` | YAML | Production EU config — referenced by `JTIER_RUN_CONFIG` in GCP europe-west1 pods |
| `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | YAML | Staging US config — referenced by `JTIER_RUN_CONFIG` in staging pods |
| `src/main/resources/config/development.yml.example` | YAML | Local development template (copy to `development.yml` before running locally) |
| `src/main/resources/config/flyway.properties.example` | properties | Flyway migration config template for local use |

### YAML Config Block Structure

The runtime YAML config (read by `CouponsRevprocConfiguration`) contains these top-level keys:

| Key | Type | Purpose |
|-----|------|---------|
| `mysql` | MySQLConfig | JDBC connection details for the `revproc` database |
| `affjet` | AffJetConfiguration | AffJet API HTTP clients and enabled flag per country |
| `salesforce` | SalesforceConfiguration | Salesforce OAuth2 credentials and endpoint URL |
| `orphanRefundMaxWaitTimeInHours` | Integer | Maximum wait time for orphan refund transactions |
| `messagebus` | MbusConfiguration | Mbus connection details and destination topic IDs |
| `clientId` | ClientIdConfiguration | Client-ID auth configuration (MySQL-backed) |
| `quartz` | QuartzConfiguration | Quartz scheduler configuration including per-country job definitions |
| `redis` | RedisConfiguration | Redis host and connection pool settings |
| `voucherCloudApi` | RetrofitConfiguration | VoucherCloud API base URL, timeout, and connection pool |
| `couponsInventoryService` | RetrofitConfiguration | Coupons inventory service HTTP client config |
| `couponsFeeds` | CouponsFeedConfiguration | VoucherCloud and Groupon feed domain configuration |
| `dotidot` | DotidotConfiguration | SFTP credentials for Dotidot feed upload (host, port, user, password) |
| `couponsRedirectSanitizer` | CouponsRedirectSanitizerConfiguration | Supported country list for redirect sanitization |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| AffJet API credentials | HTTP client authentication for each country/network AffJet endpoint | k8s-secret (via cap-secrets submodule) |
| Salesforce `clientId`, `clientSecret`, `username`, `password`, `securityToken` | OAuth2 authentication for Salesforce REST API | k8s-secret |
| VoucherCloud API auth credentials | HTTP client authentication for VoucherCloud API | k8s-secret |
| Dotidot SFTP `user` and `password` | SFTP authentication for coupon feed upload | k8s-secret |
| MySQL credentials | JDBC connection authentication | k8s-secret |
| Redis credentials | Redis connection authentication | k8s-secret |
| Mbus credentials | Message bus connection authentication | k8s-secret |

> Secret values are NEVER documented. Secrets are managed in a private secrets repository referenced as a git submodule (`cap-secrets`). See [Handling Credentials](https://groupondev.atlassian.net/wiki/spaces/EN/pages/15679404422/Secrets) for the full rotation process.

## Per-Environment Overrides

- **Staging (us-central1)**: 1 replica, VPA enabled, `vpc: stable`, `JTIER_RUN_CONFIG` points to `staging-us-central1.yml`
- **Production (us-central1)**: 2 replicas (min/max), VPA enabled, APM enabled, `vpc: prod`, `JTIER_RUN_CONFIG` points to `production-us-central1.yml`
- **Production (europe-west1)**: 2–15 replicas (HPA), APM enabled, `vpc: prod`, `JTIER_RUN_CONFIG` points to `production-europe-west1.yml`
- **Production (eu-west-1 / AWS)**: Separate deployment config in `.meta/deployment/cloud/components/coupons-revproc/production-eu-west-1.yml`
- Cron jobs (`coupons-feed-generator`, `redirect-sanitizer`, `redirect-cache-prefill`) use the same Docker image as the API service but override `JTIER_RUN_CMD` and `IS_CRON_JOB` to select the appropriate Dropwizard command
