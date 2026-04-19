---
service: "getaways-accounting-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets]
---

# Configuration

## Overview

The service is configured via YAML config files (one per environment, mounted at container startup via `JTIER_RUN_CONFIG`) combined with environment variable overrides for secrets and environment-specific values. Secrets are injected as environment variables by the Kubernetes platform. The active configuration file is selected by the `JTIER_RUN_CONFIG` environment variable pointing to the mounted config path. The cron-job component additionally uses `IS_JOB=true` to signal job-mode execution.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active YAML config file for the runtime environment | yes | none | Kubernetes env (deployment manifest) |
| `TISPOSTGRES_DATABASE` | TIS PostgreSQL database name | yes | none | Kubernetes secret |
| `TISPOSTGRES_APP_USER` | TIS PostgreSQL application username | yes | none | Kubernetes secret |
| `TISPOSTGRES_APP_PASSWORD` | TIS PostgreSQL application password | yes | none | Kubernetes secret |
| `SFTP_CLOUD_USERNAME` | SFTP server username for file uploads | yes | none | Kubernetes secret |
| `SFTP_PRIVATE_KEY` | SSH private key for SFTP authentication | yes | none | Kubernetes secret |
| `SFTP_PUBLIC_KEY` | SSH public key for SFTP authentication | yes | none | Kubernetes secret |
| `SFTP_PASS_PHRASE` | SSH key passphrase for SFTP authentication | yes | none | Kubernetes secret |
| `CONTENTSERVICE_AUTH_PARAMETER_CLIENT_ID` | `client_id` query parameter for Content Service auth | yes | none | Kubernetes secret |
| `CONTENTSERVICE_AUTH_HEADER_OLYMPIA_ADMIN` | `Olympia-Admin` header value for Content Service | yes | none | Kubernetes secret |
| `CONTENTSERVICE_AUTH_HEADER_OLYMPIA_AUTH_TOKEN` | `Olympia-Auth-Token` header value for Content Service | yes | none | Kubernetes secret |
| `TISSERVICE_AUTH_PARAMETER_CLIENT_ID` | `client_id` parameter for TIS service HTTP calls | yes | none | Kubernetes secret |
| `MALLOC_ARENA_MAX` | Limits glibc memory arenas to prevent VMem explosion in containers | no | 4 | Deployment manifest |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Disables APM TLS certificate verification | no | "false" | Deployment manifest |
| `IS_JOB` | Signals cron-job execution mode | no | none (cron-job only) | Deployment manifest |
| `HOSTNAME` | Used as `csvJobScheduler.activeHost` to ensure only one pod runs the CSV job | yes (production) | none | Pod environment |

> IMPORTANT: Secret values are never documented here. Only variable names and purposes are listed.

## Feature Flags

> No evidence found of feature flags or runtime toggles in the codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration with dev database, SFTP, and service URLs |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | GCP production (us-central1) configuration — database host, SFTP server, service URLs |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | GCP staging (us-central1) configuration — database host, SFTP server, service URLs |
| `src/main/resources/config/snc1/production.yml` | YAML | On-prem SNC1 production config (defers to secret repo) |
| `src/main/resources/config/snc1/staging.yml` | YAML | On-prem SNC1 staging config (defers to secret repo) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Kubernetes app component common config (image, ports, scaling, resources) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | GCP production Kubernetes overrides (namespace, scaling, APM endpoint) |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | GCP staging Kubernetes overrides (namespace, scaling, APM endpoint) |
| `.meta/deployment/cloud/components/cron-job/common.yml` | YAML | Kubernetes cron-job component common config (image, resources, schedule) |
| `.meta/deployment/cloud/components/cron-job/production-us-central1.yml` | YAML | GCP production cron-job overrides (schedule: `20 0 * * *`, APM endpoint) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `TISPOSTGRES_APP_USER` / `TISPOSTGRES_APP_PASSWORD` | TIS PostgreSQL credentials | Kubernetes secret (via `.meta/deployment/cloud/secrets`) |
| `TISPOSTGRES_DATABASE` | Database name for TIS PostgreSQL | Kubernetes secret |
| `SFTP_CLOUD_USERNAME` | SFTP server login username | Kubernetes secret |
| `SFTP_PRIVATE_KEY` | SSH private key for SFTP | Kubernetes secret |
| `SFTP_PUBLIC_KEY` | SSH public key for SFTP | Kubernetes secret |
| `SFTP_PASS_PHRASE` | SSH passphrase for SFTP key | Kubernetes secret |
| `CONTENTSERVICE_AUTH_*` | Content Service authentication credentials | Kubernetes secret |
| `TISSERVICE_AUTH_PARAMETER_CLIENT_ID` | TIS Service client ID | Kubernetes secret |

> Secret values are NEVER documented. Secret files are located at `.meta/deployment/cloud/secrets` (not committed to this repository).

## Per-Environment Overrides

| Configuration Key | Development | Staging (GCP) | Production (GCP) |
|-------------------|-------------|---------------|------------------|
| `database.tisPostgres.host` | `localhost` | `getaways-accounting-service-ro-na-staging-db.gds.stable.gcp.groupondev.com` | `getaways-accounting-service-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| `sftp.servers[cloud].host` | `getaways-ftp1-uat.snc1` | `s-bf7136d54cfa4597b.server.transfer.us-west-2.amazonaws.com` | `transfer.groupondev.com` |
| `sftp.servers[cloud].remoteFolder` | `/tmp/daily_reports` | `/groupon-transfer-sandbox-getaways-report-staging/groupon/getaways/gas_daily_reports` | `/groupon-transfer-prod-getaways-report/groupon/getaways/gas_daily_reports` |
| `contentService.url` | `http://getaways-travel-content-uat-vip.snc1` | `http://getaways-content.staging.service` | `http://getaways-content.production.service` |
| `tisService.url` | `http://getaways-itinerary-uat-vip.snc1` | `http://travel-itinerary-service.staging.service` | `http://travel-itinerary-service.production.service` |
| `csvJobScheduler.activeHost` | `localhost` | `${HOSTNAME}` | `${HOSTNAME}` |
| `server.applicationConnectors[0].port` | 9000 | 8080 | 8080 |
| `server.adminConnectors[0].port` | 9001 | 8081 | 8081 |
| `server.maxThreads` | 50 | 500 | 500 |
| Cron-job schedule | N/A | Configured in `cron-job/staging` | `20 0 * * *` (daily at 00:20 UTC) |
