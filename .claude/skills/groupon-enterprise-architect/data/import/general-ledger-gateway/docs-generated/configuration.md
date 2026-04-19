---
service: "general-ledger-gateway"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

GLG is configured via YAML files (one per environment) combined with environment variable injection for all secrets. The active configuration file is selected at startup using the `JTIER_RUN_CONFIG` environment variable, which points to the correct cloud config file for the environment. Secrets (credentials, tokens, passwords) are never embedded in config files — all are referenced via `${VAR_NAME}` placeholders resolved at runtime.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the environment-specific YAML config file | yes | None | helm / k8s deployment |
| `ACCOUNTING_SERVICE_CLIENT_ID` | Client ID for authenticating with Accounting Service | yes | None | k8s-secret |
| `NORTH_AMERICA_LOCAL_NETSUITE_CONSUMER_KEY` | OAuth 1.0 consumer key for North America Local NetSuite | yes | None | k8s-secret |
| `NORTH_AMERICA_LOCAL_NETSUITE_CONSUMER_SECRET` | OAuth 1.0 consumer secret for North America Local NetSuite | yes | None | k8s-secret |
| `NORTH_AMERICA_LOCAL_NETSUITE_TOKEN` | OAuth 1.0 access token for North America Local NetSuite | yes | None | k8s-secret |
| `NORTH_AMERICA_LOCAL_NETSUITE_TOKEN_SECRET` | OAuth 1.0 token secret for North America Local NetSuite | yes | None | k8s-secret |
| `GOODS_NETSUITE_CONSUMER_KEY` | OAuth 1.0 consumer key for Goods NetSuite | yes | None | k8s-secret |
| `GOODS_NETSUITE_CONSUMER_SECRET` | OAuth 1.0 consumer secret for Goods NetSuite | yes | None | k8s-secret |
| `GOODS_NETSUITE_TOKEN` | OAuth 1.0 access token for Goods NetSuite | yes | None | k8s-secret |
| `GOODS_NETSUITE_TOKEN_SECRET` | OAuth 1.0 token secret for Goods NetSuite | yes | None | k8s-secret |
| `INTERNATIONAL_NETSUITE_CONSUMER_KEY` | OAuth 1.0 consumer key for International NetSuite | yes | None | k8s-secret |
| `INTERNATIONAL_NETSUITE_CONSUMER_SECRET` | OAuth 1.0 consumer secret for International NetSuite | yes | None | k8s-secret |
| `INTERNATIONAL_NETSUITE_TOKEN` | OAuth 1.0 access token for International NetSuite | yes | None | k8s-secret |
| `INTERNATIONAL_NETSUITE_TOKEN_SECRET` | OAuth 1.0 token secret for International NetSuite | yes | None | k8s-secret |
| `REDIS_NODE` | Redis host/port for NetSuite cache | yes | None | k8s-secret |
| `DATABASE_MAIN_USER` | PostgreSQL username (used for both RW and RO pools) | yes | None | k8s-secret |
| `DATABASE_MAIN_PASSWORD` | PostgreSQL password (used for both RW and RO pools) | yes | None | k8s-secret |
| `MALLOC_ARENA_MAX` | JVM memory arena tuning to prevent vmem explosion | no | `4` | deployment YAML |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `features.jobResourceEnabled` | Enables the Job Resource REST endpoint for triggering jobs | `true` (staging and production) | per-environment |
| `features.dryRunTestingAppliedInvoices` | When `true`, applied invoice imports run in dry-run mode (no writes to Accounting Service) | `true` (staging and production) | per-environment |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/cloud/production-us-west-1.yml` | YAML | Production US-West-1 configuration (AWS) |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | Production US-Central1 configuration (GCP) |
| `src/main/resources/config/cloud/staging-us-west-1.yml` | YAML | Staging US-West-1 configuration (AWS) |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | Staging US-Central1 configuration (GCP) |
| `src/main/resources/config/development.yml.example` | YAML | Local development template (gitignored after copying) |
| `src/test/resources/config/test.yml.example` | YAML | CI/test environment template (symlinked for CI) |
| `flyway.conf` | Properties | Flyway migration connection settings (generated from `flyway.conf.example`) |
| `src/main/resources/metrics.yml` | YAML | Telegraf/Codahale metrics flush configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| NetSuite OAuth credentials (6 env vars per instance, 3 instances) | OAuth 1.0 signing for NetSuite RESTlet API calls | k8s-secret (secrets submodule) |
| `ACCOUNTING_SERVICE_CLIENT_ID` | Service-to-service auth with Accounting Service | k8s-secret (secrets submodule) |
| `DATABASE_MAIN_USER` / `DATABASE_MAIN_PASSWORD` | PostgreSQL authentication | k8s-secret (secrets submodule) |
| `REDIS_NODE` | Redis cache connection string | k8s-secret (secrets submodule) |

> Secrets are managed in the `finance-engineering/general-ledger-gateway-secrets` git submodule, mounted into the deployment via Kubernetes secrets.

## Per-Environment Overrides

- **Staging vs. Production**: NetSuite instances point to sandbox realms (`4004600_SB1`, `3579761_SB1`, `1202613_SB1`) in staging and production realms in production. Accounting Service host differs (`accounting-service.staging.service` vs. `accounting-service.production.service`).
- **Staging connection pool**: Smaller pools (min 3, max 5) vs. production (min 8, max 32).
- **Quartz cron triggers**: Cron triggers are commented out in both staging and production configs — job execution is currently triggered only via the Job Resource REST endpoint.
- **GCP vs. AWS environments**: Separate config files exist for `us-central1` (GCP) and `us-west-1` (AWS) in both staging and production; they differ primarily in database URLs.
