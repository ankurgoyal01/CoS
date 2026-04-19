---
service: "vespa-indexer"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

Configuration is managed via Pydantic `BaseSettings` (`pydantic-settings` 2.2.1). The service loads environment variables from a `.env` file whose path is resolved hierarchically: if `ENV_FILE` is set (Kubernetes deployments), that file is used; otherwise it falls back to a local `.env` in the project root. In Kubernetes, each environment's deployment YAML sets `ENV_FILE` to point to the environment-specific config file under `/app/resources/config/`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENV_FILE` | Path to environment-specific `.env` config file | No | `.env` | helm |
| `APP_NAME` | Application name for logging | No | `Vespa Indexer` | env |
| `DEBUG` | Enable debug mode | No | `false` | env |
| `LOG_LEVEL` | Logging level | No | `INFO` | env |
| `API_HOST` | Uvicorn bind address | No | `0.0.0.0` | env |
| `API_PORT` | Uvicorn bind port | No | `8000` | env |
| `VESPA_URL` | Vespa cluster HTTP endpoint | Yes | `http://localhost:8080` | env |
| `VESPA_TOKEN` | Vespa bearer token for authentication | No | None | env |
| `VESPA_CERT_PATH` | Path to mTLS certificate for Vespa | No | None | env |
| `VESPA_KEY_PATH` | Path to mTLS key for Vespa | No | None | env |
| `GCP_BUCKET_NAME` | GCS bucket containing MDS feed files | Yes | `test-bucket` | env |
| `GCP_PROJECT_ID` | GCP project ID | Yes | `test-project` | env |
| `GCP_CREDENTIALS_PATH` | Path to GCP service account JSON | No | None | env |
| `BIGQUERY_PROJECT_ID` | BigQuery project ID | No | `test-project` | env |
| `BIGQUERY_CREDENTIALS_PATH` | Path to BigQuery service account JSON | No | None | env |
| `DEAL_FEATURE_TABLE` | Fully qualified BigQuery deal features table (`project.dataset.table`) | No | `deal_features` | env |
| `DEAL_OPTION_FEATURE_TABLE` | Fully qualified BigQuery option features table | No | `deal_option_features` | env |
| `DEAL_DISTANCE_BUCKET_TABLE` | Fully qualified BigQuery distance bucket table | No | `prj-grp-relevance-dev-2867.fs.deal_distance_bucket_prior_v2` | env |
| `CATEGORY_FEATURE_TABLE` | Fully qualified BigQuery category features table | No | `category_features` | env |
| `MDS_FEED_FILE_NAME` | GCS blob name for MDS feed | No | `deals.json` | env |
| `MBUS_HOST` | MessageBus STOMP broker host | Yes | `localhost` | env |
| `MBUS_PORT` | MessageBus STOMP broker port | No | `61613` | env |
| `MBUS_USERNAME` | MessageBus authentication username | No | None | env |
| `MBUS_PASSWORD` | MessageBus authentication password | No | None | env |
| `MBUS_TOPIC_NAME` | MessageBus topic to subscribe for deal updates | No | `deal.updates` | env |
| `MBUS_USE_SSL` | Enable SSL for MessageBus connection | No | `false` | env |
| `ALLOWED_DISTRIBUTION_REGIONS` | JSON list of region codes to accept from MessageBus | No | `["US"]` | env |
| `MDS_REST_API_URL` | MDS REST API base URL | No | `https://mds.groupondev.com` | env |
| `MDS_REST_CLIENT_ID` | Client ID sent to MDS REST API | No | `vespa-indexer` | env |
| `MDS_REST_TIMEOUT_SECONDS` | HTTP timeout for MDS REST requests (seconds) | No | `30` | env |
| `MDS_REST_MAX_RETRIES` | Maximum retries for MDS REST requests | No | `3` | env |
| `MDS_MAX_UUIDS_PER_REQUEST` | Max deal UUIDs per MDS API batch request | No | `50` | env |
| `REFRESH_BATCH_SIZE` | Deal UUID batch size for feed refresh | No | `50` | env |
| `FEATURE_BATCH_SIZE` | Batch size for BigQuery feature queries | No | `500` | env |
| `FEATURE_REFRESH_MAX_WORKERS` | Max concurrent asyncio tasks for feature refresh | No | `10` | env |
| `USE_MOCK_VESPA` | Use mock Vespa client (dev/test only) | No | `false` | env |
| `USE_MOCK_GCS` | Use mock GCS client (dev/test only) | No | `false` | env |
| `USE_MOCK_BIGQUERY` | Use mock BigQuery client (dev/test only) | No | `false` | env |
| `USE_MOCK_MBUS` | Use mock MessageBus client (dev/test only) | No | `false` | env |
| `USE_MOCK_MDS` | Use mock MDS REST client with static data (dev/test only) | No | `false` | env |
| `MOCK_VESPA_OUTPUT_FILE` | File path for mock Vespa to write indexed documents (dev/test only) | No | None | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `USE_MOCK_VESPA` | Swap live Vespa client for an in-memory mock | `false` | global |
| `USE_MOCK_GCS` | Swap live GCS client for sample-data mock | `false` | global |
| `USE_MOCK_BIGQUERY` | Swap live BigQuery client for test-data mock | `false` | global |
| `USE_MOCK_MBUS` | Swap live MessageBus client for a no-op mock | `false` | global |
| `USE_MOCK_MDS` | Swap live MDS REST client for static-data mock | `false` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `resources/config/development.env` | env | Development environment settings |
| `resources/config/staging-us-central1.env` | env | Staging (US Central1) settings |
| `resources/config/staging-europe-west1.env` | env | Staging (Europe West1) settings |
| `resources/config/production-us-central1.env` | env | Production (US Central1) settings |
| `.meta/deployment/cloud/components/app/common.yml` | yaml | Helm values common to all environments |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | yaml | Helm values for staging (US Central1) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | yaml | Helm values for production (US Central1) |
| `.meta/deployment/cloud/components/cronjob-deal-refresh/common.yml` | yaml | Helm values for deal-refresh CronJob |
| `.meta/deployment/cloud/components/cronjob-feature-refresh/common.yml` | yaml | Helm values for feature-refresh CronJob |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `VESPA_TOKEN` | Vespa API bearer token | k8s-secret |
| `VESPA_CERT_PATH` / `VESPA_KEY_PATH` | Vespa mTLS certificate and key paths | k8s-secret / mounted volume |
| `GCP_CREDENTIALS_PATH` | GCP service account JSON path | k8s-secret / mounted volume |
| `BIGQUERY_CREDENTIALS_PATH` | BigQuery service account JSON path | k8s-secret / mounted volume |
| `MBUS_PASSWORD` | MessageBus authentication password | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies are referenced.

## Per-Environment Overrides

- **Staging (us-central1)**: `ENV_FILE=/app/resources/config/staging-us-central1.env`; 1 replica (minReplicas=1, maxReplicas=1)
- **Production (us-central1)**: `ENV_FILE=/app/resources/config/production-us-central1.env`; 6–10 replicas; CPU request 1000m; memory 2 Gi request / 3 Gi limit
- **Development**: Local `.env` file; `USE_MOCK_*` flags can be set individually to avoid requiring external services
- The deal-refresh CronJob runs at 10:00 UTC (`0 10 * * *`); the feature-refresh CronJob runs at 04:00, 16:00, and 22:00 UTC (`0 4,16,22 * * *`) — values from `.meta/deployment/cloud/components/cronjob-*/common.yml`
