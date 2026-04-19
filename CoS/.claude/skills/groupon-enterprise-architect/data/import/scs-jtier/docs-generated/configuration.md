---
service: "scs-jtier"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets]
---

# Configuration

## Overview

scs-jtier is configured using a combination of environment variables and per-environment YAML config files. The YAML config file path is injected via the `JTIER_RUN_CONFIG` environment variable, which points to a mounted config file (e.g., `/var/groupon/jtier/config/cloud/production-us-central1.yml`). Secrets are stored separately in `.meta/deployment/cloud/secrets` and are not committed to the repository. Application-level settings are split between non-secret env vars (in the deployment manifests under `.meta/deployment/cloud/components/`) and the YAML config file.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the per-environment YAML config file | Yes | None | env (deployment manifest) |
| `IS_CRON_ENABLED` | Enables or disables Quartz scheduled jobs on this instance | Yes | `false` (app), `true` (worker) | env (deployment manifest) |
| `MIN_RAM_PERCENTAGE` | Minimum JVM heap RAM percentage threshold | Yes | `"70.0"` | env (deployment manifest) |
| `MAX_RAM_PERCENTAGE` | Maximum JVM heap RAM percentage threshold | Yes | `"70.0"` | env (deployment manifest) |
| `MALLOC_ARENA_MAX` | Limits glibc malloc arena count to reduce native memory usage | Yes | `4` | env (deployment manifest) |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Disables TLS certificate verification for Elastic APM agent | Yes (prod/staging) | `"false"` | env (deployment manifest) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `featureFlags.countriesForCheckAvailability` | List of country codes for which inventory availability checking is enabled during cart operations | Configured per environment in YAML | per-region |

The `countriesForCheckAvailability` flag is a list of country code strings defined under `featureFlags` in the YAML config. When a request arrives for a country in this list, the `PurchasabilityChecker` performs live inventory validation against the configured inventory services.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration (database URLs, client URLs, Mbus settings, Quartz settings) |
| `/var/groupon/jtier/config/cloud/production-us-central1.yml` | YAML | Production GCP US Central 1 runtime configuration (injected at deploy time) |
| `/var/groupon/jtier/config/cloud/production-eu-west-1.yml` | YAML | Production AWS EU West 1 runtime configuration |
| `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | YAML | Staging GCP US Central 1 runtime configuration |
| `/var/groupon/jtier/config/cloud/staging-europe-west1.yml` | YAML | Staging GCP Europe West 1 runtime configuration |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Kubernetes deployment config for the `app` component |
| `.meta/deployment/cloud/components/worker/common.yml` | YAML | Shared Kubernetes deployment config for the `worker` component |

The YAML config file provides the following top-level configuration keys (from `ScsJtierConfiguration`):

| Key | Type | Purpose |
|-----|------|---------|
| `readMySQL` | `MySQLConfig` | Connection config for the MySQL read replica |
| `writeMySQL` | `MySQLConfig` | Connection config for the MySQL primary |
| `dealServiceClient` | `RetrofitConfiguration` | HTTP client config for Deal Catalog Service |
| `goodsInventoryServiceClient` | `RetrofitConfiguration` | HTTP client config for Goods Inventory Service |
| `voucherInventoryServiceClient` | `RetrofitConfiguration` | HTTP client config for Voucher Inventory Service |
| `voucherInventoryServiceClient20` | `RetrofitConfiguration` | HTTP client config for Voucher Inventory Service v2.0 |
| `gliveInventoryServiceClient` | `RetrofitConfiguration` | HTTP client config for GLive Inventory Service |
| `getawaysInventoryServiceClient` | `RetrofitConfiguration` | HTTP client config for Getaways Inventory Service |
| `mrGetawaysInventoryServiceClient` | `RetrofitConfiguration` | HTTP client config for MrGetaways Inventory Service |
| `maxCartSize` | `int` | Maximum number of items allowed in a cart |
| `messagesByLocationAndCode` | `Map<String, Map<String, String>>` | Localized error messages keyed by country and code |
| `messageBus` | `MbusConfiguration` | Mbus connection and destination configuration |
| `quartz` | `QuartzConfiguration` | Quartz scheduler settings (job schedules, thread pool) |
| `isCronEnabled` | `boolean` | Whether to start Quartz jobs on this instance |
| `abandonedCartTimes` | `Map<String, String>` | `period` and `interval` in minutes for abandoned cart detection window |
| `inactiveCartPeriod` | `String` | Minutes offset for inactive cart lookback period |
| `featureFlags` | `FeatureFlags` | Feature flag values (e.g., `countriesForCheckAvailability`) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| MySQL read/write credentials | Database username and password for the DaaS MySQL connection | k8s-secret (path: `.meta/deployment/cloud/secrets`) |
| Mbus credentials | Authentication credentials for the Groupon message bus | k8s-secret |
| Downstream service credentials | Auth tokens/keys for Deal Catalog and Inventory Service clients | k8s-secret |
| Elastic APM secret token | APM agent authentication token | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies are listed above. Secret config is maintained in a separate repository: `https://github.groupondev.com/goods/shopping_cart_service-secrets/`.

## Per-Environment Overrides

- **Development**: `src/main/resources/config/development.yml` — uses local service URLs and in-memory/test databases.
- **Staging (GCP us-central1)**: `JTIER_RUN_CONFIG` points to `cloud/staging-us-central1.yml`; 1–10 replicas; 100m CPU request, 3 Gi memory.
- **Staging (GCP europe-west1)**: `JTIER_RUN_CONFIG` points to `cloud/staging-europe-west1.yml`; similar resource profile.
- **Production (GCP us-central1)**: `JTIER_RUN_CONFIG` points to `cloud/production-us-central1.yml`; 2–25 replicas; 500m CPU request, 4 Gi memory; APM endpoint `https://elastic-apm-http.logging-platform-elastic-stack-production.svc.cluster.local:8200`.
- **Production (AWS eu-west-1)**: `JTIER_RUN_CONFIG` points to `cloud/production-eu-west-1.yml`; 2–25 replicas; 100m CPU request, 3 Gi memory; region-specific APM endpoint.
- **Worker component (all envs)**: `IS_CRON_ENABLED=true` to activate Quartz jobs; `app` component has `IS_CRON_ENABLED=false`.
