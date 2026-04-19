---
service: "file-sharing-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

File Sharing Service is configured exclusively through environment variables. The `src/file_sharing_service/config.clj` file defines all variables with default values. The active environment is controlled by `CLJ_ENV`. Per-environment deployment configuration (VIP, replicas, resource limits) is stored in `.meta/deployment/cloud/components/api/` YAML files. Secrets (Google credentials, database passwords) are stored in `.meta/deployment/cloud/secrets/` and are not committed in plaintext.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `CLJ_ENV` | Active environment name (`development`, `staging`, `production`, `test`) | yes | `development` | env |
| `DATABASE_HOST` | MySQL hostname | no | `localhost` | env |
| `DATABASE_PORT` | MySQL port | no | `3306` | env |
| `DATABASE_NAME` | MySQL database name | no | `file_sharing_service` | env |
| `DATABASE_SUBNAME` | Full JDBC subname (overrides host/port/name if set) | no | derived | env |
| `DATABASE_USER` | MySQL username | no | `root` | env |
| `DATABASE_PASSWORD` | MySQL password | no | `""` (empty) | env / k8s-secret |
| `DATABASE_USE_SSL` | Enable MySQL SSL (`true`/`false`) | no | `false` | env |
| `DATABASE_TIMEZONE` | MySQL server timezone | no | `UTC` | env |
| `GOOGLE_AUTH_MODE` | Google Drive authentication mode (`auto`, `oauth`, `service-account`, `delegation`) | no | `auto` | env |
| `GOOGLE_SERVICE_ACCOUNT_EMAIL` | Service account email address | no | see `config.clj` | env / k8s-secret |
| `GOOGLE_PROJECT_ID` | Google Cloud project ID | no | `clever-aleph-427` | env |
| `GOOGLE_SERVICE_ACCOUNT_JSON_PATH` | Path to service account JSON key file | no | derived from `CLJ_ENV` | env / k8s-secret |
| `GOOGLE_DELEGATED_USER_EMAIL` | Email to impersonate via domain-wide delegation | no | `c_brada@groupon.com` | env |
| `GOOGLE_SHARED_DRIVE_ID` | Google Shared Drive root ID | no | `0AJYp1jrjLdzlUk9PVA` | env |
| `GOOGLE_SHARED_DRIVE_FOLDER_ID` | Target folder ID inside the shared drive | no | `12kqzOi6OrmVp2NJn2vv0gZBiAbZF3B-z` | env |
| `GOOGLE_ACCESS_ID` | HMAC access ID (Cloud Storage, optional) | no | `example-google-access-id` | env / k8s-secret |
| `GOOGLE_SECRET_KEY` | HMAC secret key (Cloud Storage, optional) | no | `example-google-secret-key` | env / k8s-secret |
| `GOOGLE_CLIENT_ID` | Legacy OAuth2 client ID | no | `example-google-client-id` | env / k8s-secret |
| `GOOGLE_SECRET` | Legacy OAuth2 client secret | no | `example-google-secret` | env / k8s-secret |
| `TELEGRAF_URL` | InfluxDB/Telegraf endpoint URL | no | `http://localhost:8086/` | env |
| `DEPLOY_AZ` | Availability zone tag for metrics | no | `-` | env |
| `DEPLOY_ENV` | Environment tag for metrics | no | `-` | env |
| `DEPLOY_SERVICE` | Service name tag for metrics | no | `-` | env |
| `DEPLOY_REGION` | Region tag for metrics | no | `-` | env |
| `DEPLOY_NAMESPACE` | Kubernetes namespace tag for metrics | no | `-` | env |
| `DEPLOY_COMPONENT` | Component tag for metrics | no | `-` | env |
| `DEPLOY_INSTANCE` | Instance tag for metrics | no | `-` | env |
| `DEPLOY_MONITORING_GROUP` | Monitoring group tag for metrics | no | `-` | env |
| `TELEGRAF_METRICS_ATOM` | Metrics atom tag | no | `-` | env |
| `PORT` | HTTP server port (set in Dockerfile) | no | `5001` | env / Dockerfile |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `GOOGLE_AUTH_MODE=auto` | Enables three-tier Google Drive auth fallback (service account → delegation → OAuth) | `auto` | global |
| `GOOGLE_AUTH_MODE=service-account` | Forces service account without delegation | — | global |
| `GOOGLE_AUTH_MODE=delegation` | Forces service account with domain-wide delegation | — | global |
| `GOOGLE_AUTH_MODE=oauth` | Forces per-user OAuth only (personal drive) | — | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/file_sharing_service/config.clj` | Clojure | Defines all configuration with `System/getenv` reads and defaults |
| `.meta/deployment/cloud/components/api/common.yml` | YAML | Shared deployment config: image name, replicas, port (`5001`), health probe paths, resource requests |
| `.meta/deployment/cloud/components/api/staging-us-central1.yml` | YAML | Staging overrides: GCP `us-central1`, VIP `file-sharing-service.staging.service.us-central1.gcp.groupondev.com`, `CLJ_ENV=staging` |
| `.meta/deployment/cloud/components/api/production-us-central1.yml` | YAML | Production overrides: GCP `us-central1`, VIP `file-sharing-service.production.service.us-central1.gcp.groupondev.com`, `CLJ_ENV=production` |
| `resources/log4j.properties` | Properties | Log4j rolling file appender config — outputs to `file-sharing-service.log` |
| `.meta/.raptor.yml` | YAML | Raptor/Conveyor Cloud component definition (`api`, archetype `java`) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GOOGLE_CLIENT_ID` | OAuth2 client ID for legacy per-user Drive access | k8s-secret (`.meta/deployment/cloud/secrets/`) |
| `GOOGLE_SECRET` | OAuth2 client secret for legacy per-user Drive access | k8s-secret (`.meta/deployment/cloud/secrets/`) |
| `GOOGLE_SERVICE_ACCOUNT_JSON_PATH` | Path to mounted JSON key file for service account auth | k8s-secret / volume mount |
| `DATABASE_PASSWORD` | MySQL password | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Staging | Production |
|---------|---------|------------|
| `CLJ_ENV` | `staging` | `production` |
| Cloud provider | GCP | GCP |
| Region | `us-central1` | `us-central1` |
| Min replicas | 1 | 1 |
| Max replicas | 2 | 3 |
| CPU request (main) | `1000m` | `100m` |
| CPU limit (main) | `4000m` | `700m` |
| Memory request (main) | `800Mi` | `2Gi` |
| Memory limit (main) | `4Gi` | `2Gi` |
| VIP | `file-sharing-service.staging.service.us-central1.gcp.groupondev.com` | `file-sharing-service.production.service.us-central1.gcp.groupondev.com` |
