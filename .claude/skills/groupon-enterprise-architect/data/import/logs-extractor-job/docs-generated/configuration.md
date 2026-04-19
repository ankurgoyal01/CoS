---
service: "logs-extractor-job"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "cli-args", "k8s-secret", "k8s-configmap"]
---

# Configuration

## Overview

Configuration is layered from three sources merged at startup: (1) environment-specific config files in `config/` via the `config` npm package (`default.js` base, overridden by `staging.js` or `production.js`), (2) environment variables loaded by `dotenv` from `.env`, and (3) CLI arguments parsed at runtime. CLI arguments take precedence over environment variables for dataset/database name overrides.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Selects config overlay (`local`, `staging`, `production`) | yes | `default` | env / k8s ConfigMap |
| `REGION` | Elasticsearch region to extract logs from (`us` or `eu`) | yes | `us` | env / k8s ConfigMap |
| `ENABLE_BIGQUERY` | Enables BigQuery upload when `true` | yes | `false` | env / k8s ConfigMap |
| `ENABLE_MYSQL` | Enables MySQL upload when `true` | no | `false` | env / k8s ConfigMap |
| `BQ_PROJECT_ID` | Google Cloud project ID for BigQuery | yes (if BigQuery enabled) | — | env / k8s ConfigMap |
| `BQ_DATASET_ID` | BigQuery dataset name | yes (if BigQuery enabled) | — | env / k8s ConfigMap |
| `BQ_KEY_FILE` | Path to Google Cloud service account JSON key file | yes (if BigQuery enabled) | — | env / k8s Secret volume |
| `MYSQL_HOST` | MySQL server hostname | yes (if MySQL enabled) | — | env / k8s ConfigMap |
| `MYSQL_PORT` | MySQL server port | no | `3306` | env / k8s ConfigMap |
| `MYSQL_DATABASE` | MySQL database name | yes (if MySQL enabled) | — | env / k8s ConfigMap |
| `MYSQL_USER` | MySQL username | yes (if MySQL enabled) | k8s Secret |
| `MYSQL_PASSWORD` | MySQL password | yes (if MySQL enabled) | — | k8s Secret |
| `LOG_LEVEL` | Logging verbosity (`debug`, `info`, `warn`, `error`) | no | `info` | env / k8s ConfigMap |
| `BATCH_SIZE` | Number of records per batch insert (MySQL) | no | `1000` | env / k8s ConfigMap |
| `ES_ENDPOINT_US` | Elasticsearch US cluster endpoint URL | yes (if region=us) | `https://prod-unified-es.us-central1.logging.prod.gcp.groupondev.com` | env (via logs-processor SDK) |
| `ES_ENDPOINT_EU` | Elasticsearch EU cluster endpoint URL | yes (if region=eu) | `https://logging-prod-eu-unified1.grpn-logging-prod.eu-west-1.aws.groupondev.com:9200` | env (via logs-processor SDK) |
| `ES_USERNAME` | Elasticsearch basic auth username | yes | `elastic` | env (via logs-processor SDK) |
| `ES_PASSWORD` | Elasticsearch basic auth password | yes | — | k8s Secret (via logs-processor SDK) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `ENABLE_BIGQUERY` | Controls whether BigQuery upload runs | `false` (true in production) | per-environment |
| `ENABLE_MYSQL` | Controls whether MySQL upload runs | `false` in staging and production | per-environment |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/default.js` | JavaScript (ESM) | Base configuration — app name, batch size, region, BigQuery options, MySQL options, logging level, time-range function, log type names |
| `config/staging.js` | JavaScript (ESM) | Staging overrides — BigQuery disabled, MySQL disabled, project `prj-grp-general-sandbox-7f70`, dataset `log_processor` |
| `config/production.js` | JavaScript (ESM) | Production overrides — BigQuery enabled, MySQL disabled, project `prj-grp-general-sandbox-7f70`, dataset `log_processor`, key file `config/grpn-sa-bq-conveyor-orders_dev.json` |
| `config/local.js` | JavaScript (ESM) | Local development overrides |
| `.env` / `env.example` | dotenv | Runtime environment variable injection (not committed; `env.example` is the reference template) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `ES_PASSWORD` | Elasticsearch basic auth password | k8s Secret (`log-extractor-secrets`) |
| `MYSQL_PASSWORD` | MySQL database password | k8s Secret (`log-extractor-secrets`) |
| `BQ_KEY_FILE` content | Google Cloud service account JSON for BigQuery auth | k8s Secret (`bigquery-service-account`), mounted as a volume at `/app/service-account.json` |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Local | Staging | Production |
|---------|-------|---------|------------|
| `NODE_ENV` | `local` | `staging` | `production` |
| `ENABLE_BIGQUERY` | `true` (via .env) | `false` | `true` |
| `ENABLE_MYSQL` | `false` (via .env) | `false` | `false` |
| `BQ_PROJECT_ID` | `prj-grp-datalake-dev-8876` | `prj-grp-general-sandbox-7f70` | `prj-grp-general-sandbox-7f70` |
| `BQ_DATASET_ID` | `log_processor` | `log_processor` | `log_processor` |
| MySQL host | `localhost` | `staging-mysql.internal` | `prod-mysql.internal` |
| CronJob schedule | N/A | `1 * * * *` (every hour at minute 1) | `1 * * * *` (every hour at minute 1) |

The `cron-job2` variant in production uses `--bq_dataset log_processor_v2` as a CLI argument to write to a separate BigQuery dataset, allowing parallel testing of schema changes.
