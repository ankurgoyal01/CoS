---
service: "ad-inventory"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars, k8s-secret]
---

# Configuration

## Overview

Ad Inventory uses YAML configuration files loaded by the Dropwizard/JTier framework at startup. The active configuration file path is controlled by the `JTIER_RUN_CONFIG` environment variable, which differs per environment. Secret values (credentials, private keys, API tokens) are injected via Kubernetes secrets mounted into the container at the config file path. Non-secret environment variables are declared in `.meta/deployment/cloud/components/*/common.yml`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active YAML config file for the running environment | yes | `/var/groupon/jtier/config/cloud/production-us-central1.yml` | env (Kubernetes deployment manifest) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent virtual memory explosion and OOM kills | yes | `4` | env (`.meta/deployment/cloud/components/*/common.yml`) |
| `HIVE_GCP_ENV` | Enables GCP-backed Hive connectivity (as opposed to on-prem Hadoop) | yes | `true` | env (`.meta/deployment/cloud/components/*/common.yml`) |

> IMPORTANT: Actual secret values are never documented here. Only variable names and purposes are listed.

## Feature Flags

> No evidence found in codebase for a runtime feature flag system. Behavioral toggles are achieved via YAML config values (e.g., `configDetail` block).

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration (referenced via symlink `development.yml`) |
| `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | YAML | Staging environment configuration (mounted via Kubernetes secret) |
| `/var/groupon/jtier/config/cloud/production-us-central1.yml` | YAML | Production environment configuration (mounted via Kubernetes secret) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `dfp.jsonKeyFilepath` / `dfp.jsonKeyFile` | Google Ad Manager OAuth2 service account JSON key | k8s-secret (mounted into config YAML) |
| `dfp.networkCode` | DFP network code identifying the Groupon Ad Manager account | k8s-secret |
| `amsConfig.na.url` | AMS service URL for North America region | k8s-secret |
| `amsConfig.intl.url` | AMS service URL for International region | k8s-secret |
| `liveIntent.token_uri` | LiveIntent token authentication endpoint | k8s-secret |
| `liveIntent.reports_uri` | LiveIntent reports API endpoint | k8s-secret |
| `liveIntent.user` | LiveIntent API username | k8s-secret |
| `liveIntent.password` | LiveIntent API password | k8s-secret |
| `rokt.accessId` | AWS access key ID for S3 bucket access (Rokt reports) | k8s-secret |
| `rokt.secretAccessKey` | AWS secret access key for S3 bucket access (Rokt reports) | k8s-secret |
| `rokt.s3BucketName` | S3 bucket name containing Rokt report CSVs | k8s-secret |
| `adsgcpclientconfig.clientId` | GCS service account client ID | k8s-secret |
| `adsgcpclientconfig.clientEmail` | GCS service account email | k8s-secret |
| `adsgcpclientconfig.privateKey` | GCS service account private key | k8s-secret |
| `adsgcpclientconfig.privateKeyId` | GCS service account private key ID | k8s-secret |
| `adsgcpclientconfig.projectId` | GCP project ID | k8s-secret |
| `adsgcpclientconfig.bucketName` | GCS bucket name for bloom filters and staged reports | k8s-secret |
| `redis.endpoint` | Redis host and port | k8s-secret |
| `redis.password` | Redis authentication password | k8s-secret |
| `mysql.*` | MySQL DaaS connection details (host, port, user, password, database) | k8s-secret |
| `citrusAd.baseUrl` | CitrusAd API base URL | k8s-secret |
| `email.*` | SMTP server hostname, port, username, password | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Configuration Sections (YAML structure)

The `AdInventoryConfiguration` class maps the following top-level YAML keys:

| YAML Key | Type | Purpose |
|----------|------|---------|
| `mysql` | `MySQLConfig` | DaaS MySQL connection pool settings |
| `redis` | `RedisConfig` | Redis connection (endpoint, password, pool size, timeout, SSL) |
| `configDetail` | `ConfigDetail` | General service config details |
| `citrusAd` | `CitrusAdConfig` | CitrusAd base URL and click report path |
| `smaConfig` | `SmaConfig` | SMA metrics submission configuration |
| `amsConfig` | `AMSConfig` | AMS URL config for NA and INTL regions |
| `nodeConfig` | `NodeConfiguration` | Node/cluster configuration |
| `quartz` | `QuartzConfiguration` | Quartz scheduler thread pool and job store settings |
| `env` | `String` | Deployment environment name (e.g., `production`, `staging`) |
| `email` | `EmailConfiguration` | SMTP configuration for report notifications |
| `dfp` | `DFPConfiguration` | Google Ad Manager credentials and network settings |
| `liveIntent` | `LiveIntentConfiguration` | LiveIntent API credentials and endpoints |
| `hive` | `HiveConfig` | Hive JDBC connection settings |
| `rokt` | `RoktConfig` | AWS S3 credentials and bucket name for Rokt reports |
| `reportVerification` | `ReportVerificationConfig` | Report verification thresholds and parameters |
| `customizedHttpClient` | `HttpClientConfig` | Tuned OkHttp client settings for outbound calls |
| `adsgcpclientconfig` | `GCPClientConfig` | GCS service account and bucket configuration |

## Per-Environment Overrides

| Environment | `JTIER_RUN_CONFIG` | Min Replicas (api) | Max Replicas (api) | Memory (api) |
|-------------|---------------------|--------------------|--------------------|--------------|
| Staging | `staging-us-central1.yml` | 1 | 2 | 3Gi request / 4Gi limit |
| Production | `production-us-central1.yml` | 3 | 15 | 4Gi request / 5Gi limit |

The staging environment also enables the Hybrid Boundary gateway (`enableGateway: true`), while production has it disabled.
