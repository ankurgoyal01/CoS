---
service: "marketing-and-editorial-content-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

MECS is configured through YAML config files bundled in the application JAR under `src/main/resources/config/`. The active config file is selected at runtime via the `JTIER_RUN_CONFIG` environment variable, which Kubernetes sets per-environment. Secret credential values are injected as environment variables referenced using `${VAR_NAME}` substitution in the YAML files. Non-secret values are embedded directly in the per-environment YAML files.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the active environment YAML config file | yes | none | Kubernetes env (`envVars` in deployment YAML) |
| `DAAS_APP_USERNAME` | PostgreSQL application user for read and write connections | yes | none | Kubernetes secret |
| `DAAS_APP_PASSWORD` | PostgreSQL application password for read and write connections | yes | none | Kubernetes secret |
| `DAAS_DBA_USERNAME` | PostgreSQL DBA user for schema migrations | yes | none | Kubernetes secret |
| `DAAS_DBA_PASSWORD` | PostgreSQL DBA password for schema migrations | yes | none | Kubernetes secret |
| `ADMIN_CLIENT_ID` | Admin ClientId credential for privileged API operations | yes | none | Kubernetes secret |
| `GISC_CLIENT_ID` | Global Image Service client identifier for image upload requests | yes | none | Kubernetes secret |
| `GISC_API_KEY` | Global Image Service API key for image upload authentication | yes | none | Kubernetes secret |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Disable TLS certificate verification for the Elastic APM server | no | `"true"` (default) | Kubernetes env (set to `"false"` in production) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase. No feature flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration with localhost PostgreSQL and hardcoded dev credentials |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | Staging (US Central 1) environment config — PostgreSQL hosts, GIMS URL, profanity settings |
| `src/main/resources/config/cloud/staging-europe-west1.yml` | YAML | Staging (Europe West 1) environment config |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | Production (US Central 1) environment config — `editorial_content_prod` database |
| `src/main/resources/config/cloud/production-europe-west1.yml` | YAML | Production (Europe West 1) environment config |
| `src/main/resources/config/cloud/production-eu-west-1.yml` | YAML | Production (EU West 1 / AWS) environment config |
| `src/main/resources/metrics.yml` | YAML | Metrics reporting — destination URL for Telegraf and Codahale flush frequency |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DAAS_APP_USERNAME` / `DAAS_APP_PASSWORD` | PostgreSQL application credentials | Kubernetes secret |
| `DAAS_DBA_USERNAME` / `DAAS_DBA_PASSWORD` | PostgreSQL DBA credentials for Flyway migrations | Kubernetes secret |
| `ADMIN_CLIENT_ID` | Admin API access credential | Kubernetes secret |
| `GISC_CLIENT_ID` | Global Image Service client ID | Kubernetes secret |
| `GISC_API_KEY` | Global Image Service API key | Kubernetes secret |

> Secret values are never documented here. Rotation policies are managed by the MARS team.

## Per-Environment Overrides

Key differences across environments:

| Setting | Development | Staging | Production |
|---------|-------------|---------|------------|
| PostgreSQL host (write) | `localhost` | `marketing-and-editorial-content-service-rw-na-staging-db.gds.stable.gcp.groupondev.com` | `marketing-and-editorial-content-service-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| PostgreSQL host (read) | same as write | `marketing-and-editorial-content-service-ro-na-staging-db.gds.stable.gcp.groupondev.com` | `marketing-and-editorial-content-service-ro-na-production-db.gds.prod.gcp.groupondev.com` |
| Database name | `test_dev` | `mecs_stg` | `editorial_content_prod` |
| PostgreSQL port | 16010/16011/16012 | 5432 | 5432 |
| `clientId.permitAll` | `false` | `false` | `false` |
| `profanity.refreshIntervalInMillis` | 86400000 (daily) | 86400000 (daily) | 86400000 (daily) |
| `profanity.fallbackLanguage` | `en` | `en` | `en` |
| Global Image Service URL | `https://img.grouponcdn.com` | `https://img.grouponcdn.com` | `https://img.grouponcdn.com` |
| GIMS timeouts (read/write/connect) | 180000 ms | 180000 ms | 180000 ms |
| Elastic APM endpoint | not configured | not configured | `https://elastic-apm-http.logging-platform-elastic-stack-production.svc.cluster.local:8200` |
| Logging appenders | steno-trace + console | steno-trace | steno-trace |

Additional tunable Dropwizard server settings (same across cloud environments):
- `server.maxThreads`: 50
- `server.minThreads`: 8
- `logging.level`: INFO
