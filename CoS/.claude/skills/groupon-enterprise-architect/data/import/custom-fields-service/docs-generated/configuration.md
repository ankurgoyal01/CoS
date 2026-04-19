---
service: "custom-fields-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

Custom Fields Service is configured via a combination of YAML run-config files (one per environment, selected at startup via the `JTIER_RUN_CONFIG` environment variable) and Kubernetes secrets injected as environment variables at runtime. The run-config files are bundled in the application image under `src/main/resources/config/cloud/`. Sensitive credentials (database passwords, API keys) are never stored in the config files — they are referenced as `${VAR_NAME}` placeholders resolved from Kubernetes secrets.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the environment-specific YAML run-config file loaded at startup | yes | None | Kubernetes `envVars` in `.meta/deployment/cloud/components/app/{env}.yml` |
| `DAAS_APP_USERNAME` | PostgreSQL application user for DaaS connection | yes | None | Kubernetes secret |
| `DAAS_APP_PASSWORD` | PostgreSQL application user password for DaaS connection | yes | None | Kubernetes secret |
| `DAAS_DBA_USERNAME` | PostgreSQL DBA user (used for migrations) | yes | None | Kubernetes secret |
| `DAAS_DBA_PASSWORD` | PostgreSQL DBA user password | yes | None | Kubernetes secret |
| `USER_SERVICE_API_KEY` | API key passed as `X-API-KEY` header to Users Service | yes | None | Kubernetes secret |
| `CFS_ADMIN_KEY` | Admin secret key for authorizing `DELETE /v1/fields/{uuid}` operations | yes | None | Kubernetes secret |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

## Feature Flags

> No evidence found in codebase.

No feature flag system (LaunchDarkly, config-based flags, etc.) is present in the codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/cloud/production-us-west-1.yml` | YAML | Run-config for AWS us-west-1 production |
| `src/main/resources/config/cloud/production-eu-west-1.yml` | YAML | Run-config for AWS eu-west-1 production |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | Run-config for GCP us-central1 production |
| `src/main/resources/config/cloud/production-europe-west1.yml` | YAML | Run-config for GCP europe-west1 production |
| `src/main/resources/config/cloud/staging-us-west-1.yml` | YAML | Run-config for AWS us-west-1 staging |
| `src/main/resources/config/cloud/staging-us-west-2.yml` | YAML | Run-config for AWS us-west-2 staging |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | Run-config for GCP us-central1 staging |
| `src/main/resources/config/cloud/staging-europe-west1.yml` | YAML | Run-config for GCP europe-west1 staging |
| `src/main/resources/config/cloud/dev-us-west-1.yml` | YAML | Run-config for dev/local development |
| `src/main/resources/config/cloud/dev-us-west-2.yml` | YAML | Run-config for dev environment (us-west-2) |
| `src/main/resources/config/development.yml` | YAML | Local development configuration |
| `src/main/resources/metrics.yml` | YAML | Metrics reporting configuration |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Kubernetes deployment configuration (ports, probes, resources, logging) |
| `.meta/deployment/cloud/components/app/{env}.yml` | YAML | Per-environment Kubernetes overrides (region, VIP, replicas, resource limits) |

### Key run-config sections (from `production-us-west-1.yml`)

| Section | Key fields | Purpose |
|---------|-----------|---------|
| `server` | `maxThreads`, `minThreads` (500), `applicationConnectors.port` (8080), `adminConnectors.port` (8081) | Dropwizard server threading and port configuration |
| `postgres` | `host`, `database`, `transactionPort` (5432), `sessionPort` (6432) | DaaS PostgreSQL connection |
| `userServiceClient` | `url`, `authenticationOptions`, `connectTimeout` (PT1S), `readTimeout` (PT0.5S) | Outbound Users Service HTTP client |
| `userServiceClientCache` | `cacheSize` (10000), `cacheExpire` (5) | In-memory Guava cache for user profile responses |
| `localizedCustomFieldsFetcher` | `cacheSize` (0 in production) | In-memory cache for localized field sets |
| `customFieldsValidatorFetcher` | `cacheSize` (0 in production) | In-memory cache for validator instances |
| `adminSecretKey` | `${CFS_ADMIN_KEY}` | Admin API key for delete operations |
| `logging` | `level: INFO`, `type: steno-trace` | Steno structured logging configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DAAS_APP_USERNAME` / `DAAS_APP_PASSWORD` | PostgreSQL application-level DB credentials | Kubernetes secret |
| `DAAS_DBA_USERNAME` / `DAAS_DBA_PASSWORD` | PostgreSQL DBA credentials (schema migrations) | Kubernetes secret |
| `USER_SERVICE_API_KEY` | Authentication token for Users Service API | Kubernetes secret |
| `CFS_ADMIN_KEY` | Admin authorization key for template deletion endpoint | Kubernetes secret |

> Secret values are NEVER documented. Only names and purposes are listed.

## Per-Environment Overrides

| Environment | Key differences |
|-------------|----------------|
| Production (us-west-1, AWS) | `minReplicas: 2`, `maxReplicas: 12`, memory 3.5Gi–5Gi; DB host: `customfieldsapp-prod-1.czlsgz0xic0p.us-west-1.rds.amazonaws.com` |
| Production (eu-west-1, AWS) | `minReplicas: 6`, `maxReplicas: 20`, CPU target utilization 30%; DB host: `customfieldsapp-prod.cqgqresxrenm.eu-west-1.rds.amazonaws.com` |
| Production (us-central1, GCP) | `minReplicas: 2`, `maxReplicas: 12`, VPA enabled, memory 2.3Gi–5Gi; DB host: `custom-fields-service-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| Staging (us-west-1, AWS) | `minReplicas: 1`, `maxReplicas: 7`, memory 3Gi–5Gi |
| Common (all envs) | `httpPort: 8080`, `admin-port: 8081`, `minReplicas: 3` (default), health probe at `/grpn/healthcheck`, APM enabled |
