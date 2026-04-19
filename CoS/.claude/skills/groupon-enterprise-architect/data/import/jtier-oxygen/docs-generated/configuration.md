---
service: "jtier-oxygen"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

JTier Oxygen is configured via a layered YAML config system managed by the JTier framework. The active config file is selected by the `JTIER_RUN_CONFIG` environment variable, which points to an environment-specific YAML file bundled in the service image (e.g., `src/main/resources/config/cloud/production-us-central1.yml`). Secrets (database credentials) are injected as environment variables at runtime via the DaaS secret infrastructure. The development config (`src/main/resources/config/development.yml`) provides defaults for local runs.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the active YAML config file for this environment | Yes | `src/main/resources/config/development.yml` (local) | helm (via deployment YAML `envVars`) |
| `SERVER_PORT` | HTTP listener port | No | `8080` | env |
| `HTTPS_PORT` | HTTPS listener port | No | `8443` | env |
| `ADMIN_PORT` | Dropwizard admin port | No | `9001` | env |
| `DAAS_APP_USERNAME` | Postgres application user name | Yes (cloud) | `test_dev_dba` (local) | DaaS secrets injection |
| `DAAS_APP_PASSWORD` | Postgres application user password | Yes (cloud) | `dba` (local) | DaaS secrets injection |
| `DAAS_DBA_USERNAME` | Postgres DBA user name | Yes (cloud) | `test_dev_dba` (local) | DaaS secrets injection |
| `DAAS_DBA_PASSWORD` | Postgres DBA user password | Yes (cloud) | `dba` (local) | DaaS secrets injection |
| `EXCLUSIVE_MEMBER` | Controls whether this instance runs the exclusive Quartz scheduler | No | `false` | env |
| `JTIER_RUN_CMD` | Override for the JTier service run command (used by schedule component) | No | — | helm (schedule component) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase of feature flag infrastructure beyond the `EXCLUSIVE_MEMBER` env var that enables the exclusive Quartz scheduler on a per-instance basis.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development defaults (ports, local Postgres/Redis/MessageBus endpoints, Quartz cron config) |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | Production GCP US-Central1 config (Postgres host, Redis endpoint, GitHub URL) |
| `src/main/resources/config/cloud/production-us-west-1.yml` | YAML | Production AWS US-West-1 config |
| `src/main/resources/config/cloud/production-us-west-2.yml` | YAML | Production AWS US-West-2 config |
| `src/main/resources/config/cloud/production-eu-west-1.yml` | YAML | Production AWS EU-West-1 config |
| `src/main/resources/config/cloud/production-europe-west1.yml` | YAML | Production GCP Europe-West1 config |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | Staging GCP US-Central1 config |
| `src/main/resources/config/cloud/staging-us-west-1.yml` | YAML | Staging AWS US-West-1 config |
| `src/main/resources/config/cloud/staging-us-west-2.yml` | YAML | Staging AWS US-West-2 config |
| `src/main/resources/config/cloud/staging-europe-west1.yml` | YAML | Staging GCP Europe-West1 config |
| `src/main/resources/config/cloud/dev-us-central1.yml` | YAML | Dev GCP US-Central1 config |
| `src/main/resources/config/cloud/dev-us-west-2.yml` | YAML | Dev GCP US-West-2 config |
| `src/main/resources/metrics.yml` | YAML | Codahale/Telegraf metrics flush config (`destinationUrl: http://localhost:8186/`, `codahaleFlushFrequencySeconds: 10`) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DAAS_APP_USERNAME` / `DAAS_APP_PASSWORD` | Postgres application credentials | DaaS (JTier-managed secrets injection) |
| `DAAS_DBA_USERNAME` / `DAAS_DBA_PASSWORD` | Postgres DBA credentials for migrations | DaaS (JTier-managed secrets injection) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The active config file is selected by `JTIER_RUN_CONFIG`. Key differences across environments:

- **Development (local)**: Uses Docker-hosted DaaS Postgres (`localhost:12700`), local MessageBus (`localhost:12704/12705`), and local Redis (`localhost:12703`). Quartz cron runs every minute. HTTPS with a local JKS keystore.
- **Staging (GCP us-central1)**: Postgres at `jtier-oxygen-rw-na-staging-db.gds.stable.gcp.groupondev.com`, database `oxygen_stg`. Redis at GCP Memorystore. MessageBus config is commented out in cloud configs (disabled in staging/production).
- **Production (GCP us-central1)**: Postgres at `jtier-oxygen-rw-na-production-db.gds.prod.gcp.groupondev.com`, database `oxygen_prod`. Redis at `oxygen-memorystore.us-central1.caches.prod.gcp.groupondev.com:6379`.
- **Server thread pool**: `maxThreads: 50`, `minThreads: 8` (all cloud environments)
- **HTTP client timeouts**: `connectTimeout: 10s`, `readTimeout: 10s`, `writeTimeout: 10s`, `maxRequestsPerHost: 50`, `maxConcurrentRequests: 500`
