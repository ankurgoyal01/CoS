---
service: "suggest"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The service is configured through a combination of environment variables and INI-format config files. The active config file is selected at startup based on the `DEPLOY_ENV` environment variable: `app/conf/config.production.ini` when `DEPLOY_ENV=production`, otherwise `app/conf/config.staging.ini`. Both files currently contain identical values. All INI settings are parsed into typed Python dataclasses by `app/core/config.py`. Observability settings (APM server URL, environment labels) are supplied as environment variables injected at the Kubernetes/Helm layer.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DEPLOY_ENV` | Selects the INI config file (`production` or `staging`) | no | `staging` | env |
| `FULL_SHA` | Git commit SHA exposed via `GET /grpn/versions` | no | `None` | env (set at build time by CI) |
| `ELASTIC_APM_SERVICE_NAME` | APM service identifier | yes | `suggest` | env (Helm/common.yml) |
| `ELASTIC_APM_SERVER_URL` | APM server endpoint | yes | — | env (per-environment deployment YAML) |
| `ELASTIC_APM_ENVIRONMENT` | APM environment label | yes | — | env (per-environment deployment YAML) |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Whether to verify APM server TLS cert | no | `false` | env (common.yml) |
| `ELASTIC_APM_TRANSACTION_SAMPLE_RATE` | APM trace sampling rate | no | `1.0` | env (common.yml) |
| `ELASTIC_APM_TRANSACTION_IGNORE_URLS` | URL patterns excluded from APM tracing | no | `*/metrics*,*/healthcheck*` | env (common.yml) |
| `LOGFILE` | Path to log file | no | `/var/groupon/logs/logfile.log` | env (common.yml) |
| `PYTHONPATH` | Python module search path | no | `/app` | env (Dockerfile) |
| `PYTHONUNBUFFERED` | Disables Python output buffering | no | `1` | env (Dockerfile) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `QueryPreprocessing.disabled_features` (INI) | Comma-separated list of preprocessing feature names to globally disable (e.g., `radius_prediction,adult_detection`) | `""` (all features enabled) | global |
| `SuggestionsIndexScheduler.enabled` (INI) | Enables/disables the daily query-index refresh job | `true` | global |
| `SuggestionsRankingIndexScheduler.enabled` (INI) | Enables/disables the daily ranking-index refresh job | `true` | global |
| `SuggestPrefixIndexScheduler.enabled` (INI) | Enables/disables the daily prefix-index refresh job | `true` | global |
| `query_preprocessing_enabled` (API param) | Per-request flag enabling typo correction and locality detection in `GET /suggestions` | `false` | per-request |
| `debug_mode` (API param) | Per-request flag enabling debug information in the response | `false` | per-request |
| `exclude_adult_content` (API param) | Per-request flag filtering adult-content query suggestions | `false` | per-request |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `app/conf/config.production.ini` | INI | Production runtime configuration (server, BigQuery table names, scheduler intervals, file paths, Sheets integration) |
| `app/conf/config.staging.ini` | INI | Staging runtime configuration (identical to production values) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes/Helm deployment settings shared across environments |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production-specific resource limits and APM settings |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging-specific scaling and APM settings |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Europe staging environment settings |
| `app.yaml` | YAML | Health check configuration for Groupon platform orchestration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `resources/service-account-key.json` | GCP service account credentials for BigQuery access | Kubernetes secret / mounted volume |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Staging | Production |
|---------|---------|------------|
| `ELASTIC_APM_ENVIRONMENT` | `staging-us-central1` | `production-us-central1` |
| `ELASTIC_APM_SERVER_URL` | `https://elastic-apm-http.logging-platform-elastic-stack-staging.svc.cluster.local:8200` | `https://elastic-apm-http.logging-platform-elastic-stack-production.svc.cluster.local:8200` |
| `minReplicas` | `1` | `2` |
| `maxReplicas` | `1` | `5` |
| CPU request | Not explicitly set | `1000m` |
| Memory request | Not explicitly set | `1Gi` |
| Memory limit | Not explicitly set | `2Gi` |

INI config files (`config.production.ini` and `config.staging.ini`) are currently identical — both point to the same production BigQuery project (`prj-grp-dataview-prod-1ff9`) and local data files under `data/`.

### Key INI Settings Reference

| INI Section | Key | Value |
|-------------|-----|-------|
| `Server` | `host` | `0.0.0.0` |
| `Server` | `port` | `8080` |
| `BigQuery` | `suggestions_index_table` | `prj-grp-dataview-prod-1ff9.product_analytics.query_by_division_index` |
| `BigQuery` | `suggestions_ranking_index_table` | `prj-grp-dataview-prod-1ff9.product_analytics.suggestion_ranking_index` |
| `BigQuery` | `suggest_prefix_table` | `prj-grp-relevance-dev-2867.fs.suggest_prefix` |
| `BigQuery` | `project_id` | `prj-grp-dataview-prod-1ff9` |
| `BigQuery` | `key_path` | `resources/service-account-key.json` |
| `SuggestionsIndexScheduler` | `interval_seconds` | `86400` |
| `SuggestionsRankingIndexScheduler` | `interval_seconds` | `86400` |
| `SuggestPrefixIndexScheduler` | `interval_seconds` | `86400` |
| `Sheets` | `sheet_id` | `1ZRW4pf3OPAObRHKBaEzatGTzigg1U2bKXqTnMg-eBwI` |
| `Sheets` | `SCOPES` | `https://www.googleapis.com/auth/spreadsheets.readonly` |
