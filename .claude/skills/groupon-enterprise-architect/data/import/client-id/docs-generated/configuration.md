---
service: "client-id"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets]
---

# Configuration

## Overview

Client ID Service is configured through a hierarchy of YAML files loaded at startup. The active config file is selected by the `JTIER_RUN_CONFIG` environment variable, which resolves to a region- and environment-specific YAML file under `src/main/resources/config/cloud/`. Secret credentials (database passwords) are injected via Kubernetes secrets and referenced as `${VAR_NAME}` substitutions within the YAML files. Non-secret configuration is embedded directly in the config files or passed as environment variables in the Kubernetes deployment manifests.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the active YAML configuration file | Yes | None | Kubernetes env (`.meta/deployment/cloud/components/app/*.yml`) |
| `HEAP_SIZE` | JVM heap size passed to the JVM startup | Yes | None | Kubernetes env (`.meta/deployment/cloud/components/app/*.yml`) |
| `DAAS_APP_USER` | MySQL application username for both primary and read-replica pools | Yes | None | Kubernetes secret (client-id-secrets repo) |
| `DAAS_APP_PASSWORD` | MySQL application password for both primary and read-replica pools | Yes | None | Kubernetes secret (client-id-secrets repo) |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Disable TLS cert verification for APM agent in staging | No | `true` | Kubernetes env (staging only) |

> IMPORTANT: Secret values are never documented here. Only variable names and purposes are listed.

## Feature Flags

> No evidence found in codebase of a feature-flag system (LaunchDarkly, Unleash, etc.). Behaviour variations are controlled through per-environment YAML configuration values.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | Production GCP US-Central1 config (MySQL hosts, thread pool, rate limits, region=NA) |
| `src/main/resources/config/cloud/production-eu-west-1.yml` | YAML | Production AWS EU-West-1 config (MySQL hosts, thread pool, region) |
| `src/main/resources/config/cloud/production-europe-west1.yml` | YAML | Production GCP Europe-West1 config |
| `src/main/resources/config/cloud/production-us-west-1.yml` | YAML | Production GCP US-West-1 config |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | Staging GCP US-Central1 config (includes APM endpoint) |
| `src/main/resources/config/cloud/staging-europe-west1.yml` | YAML | Staging GCP Europe-West1 config |
| `src/main/resources/config/cloud/staging-us-west-1.yml` | YAML | Staging GCP US-West-1 config |
| `src/main/resources/config/cloud/staging-us-west-2.yml` | YAML | Staging AWS US-West-2 config |
| `src/main/resources/config/cloud/dev-us-west-1.yml` | YAML | Dev GCP US-West-1 config |
| `src/main/resources/config/development.yml` | YAML | Local development config (UAT MySQL, debug logging) |
| `src/main/resources/metrics.yml` | YAML | Telegraf/InfluxDB metrics reporter configuration |

### Notable config values (from `production-us-central1.yml`)

| Config key | Value | Purpose |
|------------|-------|---------|
| `server.maxThreads` / `minThreads` | 512 | Jetty thread pool size for production |
| `httpClient.connectTimeout` | 2s | Connection timeout for Jira HTTP client |
| `httpClient.readTimeout` | 1s | Read timeout for Jira HTTP client |
| `httpClient.writeTimeout` | 2s | Write timeout for Jira HTTP client |
| `httpClient.maxRequestsPerHost` | 50 | Max concurrent requests to a single host |
| `httpClient.maxConcurrentRequests` | 500 | Max total concurrent outbound HTTP requests |
| `mysql.poolSize` | 5 | Primary write connection pool size |
| `mysqlRead.poolSize` | 30 | Read replica connection pool size |
| `mysql.properties.connectionTimeout` | 40000 ms | HikariCP connection acquisition timeout |
| `mysql.properties.leakDetectionThreshold` | 10000 ms | HikariCP connection leak detection window |
| `region` | `NA` | Region tag used for reCAPTCHA config region filtering |
| `jiraServiceClientHost` | `http://jira.production.service/` | Base URL for Jira REST API calls |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DAAS_APP_USER` | MySQL username for primary and read-replica connections | Kubernetes secret (client-id-secrets repo: `github.groupondev.com/groupon-api/client-id-secrets`) |
| `DAAS_APP_PASSWORD` | MySQL password for primary and read-replica connections | Kubernetes secret (client-id-secrets repo) |

> Secret values are NEVER documented. Only names and purposes are listed.

## Per-Environment Overrides

| Setting | Development | Staging | Production |
|---------|-------------|---------|------------|
| MySQL host (primary) | `gds-snc1-client-id-db-uat-rw-vip.snc1.` | Region-specific staging host | `client-id-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| MySQL database | `client_id_uat` | `client_id_staging` (inferred) | `client_id_production` |
| Server thread pool | 8 min / 50 max | — | 512 min / 512 max |
| Log level | DEBUG | INFO | INFO |
| APM | Not configured | Enabled (staging APM endpoint) | Enabled |
| Pod replicas | — | 1–2 | 4–20 (region-dependent) |
| `JTIER_RUN_CONFIG` | `./development.yml` (local) | `/var/groupon/jtier/config/cloud/staging-*.yml` | `/var/groupon/jtier/config/cloud/production-*.yml` |
