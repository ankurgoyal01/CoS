---
service: "voucher-inventory-jtier"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

Voucher Inventory JTier is configured through a hierarchy of YAML config files loaded at startup, supplemented by environment variables injected by Kubernetes/Helm at deploy time. The primary config file path is set via the `JTIER_RUN_CONFIG` environment variable, which points to an environment-specific YAML file (e.g., `cloud/production-us-west-1.yml`). Secrets (database credentials, MessageBus passwords) are injected as environment variable references in the config files using the `${VAR_NAME}` syntax and supplied via Kubernetes secrets. Feature flags are embedded within the YAML config under `additionalServerConfig` and `workerConfig`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active YAML config file | yes | None | helm/env |
| `ENABLE_MBUS` | Enables MessageBus consumer on this pod (worker mode) | yes | `false` | helm/env |
| `ENABLE_OUROBOROS` | Enables the Ouroboros/replenishment Quartz job | yes | `false` | helm/env |
| `ENABLE_UNITREDEEM` | Enables the Unit Redeem Quartz job | yes | `false` | helm/env |
| `IS_FEATURE_UPDATE_ALLOWED` | Allows pricing feature control updates | yes | `false` | helm/env |
| `ENABLE_RW_DATABASE` | Enables writes to the RW MySQL database | yes | `false` | helm/env |
| `IS_RW_HOST` | Marks this pod as an RW-capable host | yes | `false` | helm/env |
| `USE_TELEGRAF_METRICS` | Enables Telegraf metrics sidecar | yes | `true` | helm/env |
| `MIN_RAM_PERCENTAGE` | JVM minimum heap percentage | yes | `67.0` | helm/env |
| `MAX_RAM_PERCENTAGE` | JVM maximum heap percentage | yes | `67.0` | helm/env |
| `VIS_DAAS_APP_USERNAME` | MySQL username for Product DB | yes | None | k8s-secret |
| `VIS_DAAS_APP_PASSWORD` | MySQL password for Product DB | yes | None | k8s-secret |
| `UNITS_DAAS_APP_USERNAME` | MySQL username for Units DB | yes | None | k8s-secret |
| `UNITS_DAAS_APP_PASSWORD` | MySQL password for Units DB | yes | None | k8s-secret |
| `VIS_RW_DAAS_APP_USERNAME` | MySQL username for RW DB | yes | None | k8s-secret |
| `VIS_RW_DAAS_APP_PASSWORD` | MySQL password for RW DB | yes | None | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `enableDynamicPricingResponse` | Enables dynamic pricing enrichment in API responses | `true` | global |
| `enableBulkPricingConsumption` | Enables bulk pricing data consumption from Pricing Service | `true` | global |
| `enableCalendarService` | Enables Calendar Service availability segment enrichment | `true` (cloud/EU), `false` (SNC1 on-prem) | per-region |
| `enableUniversalCart` | Enables Universal Cart support in responses | `true` (cloud) | global |
| `isFeatureUpdateAllowed` | Allows the API to push feature control updates to Pricing Service | `false` (cloud default), `true` (SNC1 on-prem prod) | per-host |
| `enableRwDatabase` | Enables writes to the RW MySQL database | `false` (cloud default), `true` (SNC1 on-prem prod) | per-host |
| `enableJedisCluster` | Enables Jedis cluster mode for Redis | `true` (cloud), `false` (on-prem) | per-env |
| `allISIDsSupportForEMEA` | Enables all IS IDs for EMEA region support | `false` | per-region |
| `isWorkerMachine` (via `ENABLE_MBUS`) | Controls whether this pod runs as a MessageBus consumer worker | `false` | per-pod |
| `canEnableReplenishment` (via `ENABLE_OUROBOROS`) | Controls whether the replenishment Quartz job runs | `false` | per-pod |
| `isUnitRedeemMachine` (via `ENABLE_UNITREDEEM`) | Controls whether the Unit Redeem job runs | `false` | per-pod |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration |
| `src/main/resources/config/snc1/production.yml` | YAML | SNC1 on-premises production config |
| `src/main/resources/config/snc1/staging.yml` | YAML | SNC1 staging config |
| `src/main/resources/config/sac1/production.yml` | YAML | SAC1 on-premises production config |
| `src/main/resources/config/dub1/production.yml` | YAML | DUB1 (EU) on-premises production config |
| `src/main/resources/config/cloud/production-us-west-1.yml` | YAML | AWS us-west-1 production cloud config |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | GCP us-central1 production cloud config |
| `src/main/resources/config/cloud/production-eu-west-1.yml` | YAML | AWS eu-west-1 production cloud config |
| `src/main/resources/config/cloud/production-europe-west1.yml` | YAML | GCP europe-west1 production cloud config |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | GCP us-central1 staging cloud config |
| `src/main/resources/config/cloud/staging-us-west-1.yml` | YAML | AWS us-west-1 staging cloud config |
| `src/main/resources/config/cloud/staging-us-west-2.yml` | YAML | AWS us-west-2 staging cloud config (EMEA) |
| `src/main/resources/config/cloud/staging-europe-west1.yml` | YAML | GCP europe-west1 staging cloud config |
| `src/main/resources/config/cloud/dev-us-west-1.yml` | YAML | AWS us-west-1 dev cloud config |
| `src/main/resources/config/businessConfiguration.yml` | YAML | Inventory unit template type mappings |
| `src/main/resources/config/pwaDeprecationFeatures/production.yml` | YAML | PWA deprecation feature flag overrides (production) |
| `src/main/resources/config/pwaDeprecationFeatures/staging.yml` | YAML | PWA deprecation feature flag overrides (staging) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `VIS_DAAS_APP_USERNAME` / `VIS_DAAS_APP_PASSWORD` | MySQL credentials for Product DB | k8s-secret (`.meta/deployment/cloud/secrets/`) |
| `UNITS_DAAS_APP_USERNAME` / `UNITS_DAAS_APP_PASSWORD` | MySQL credentials for Units DB | k8s-secret |
| `VIS_RW_DAAS_APP_USERNAME` / `VIS_RW_DAAS_APP_PASSWORD` | MySQL credentials for RW DB | k8s-secret |
| MessageBus password | Authentication to MessageBus destinations | Config file (secret path: `.meta/deployment/cloud/secrets/`) |
| SFTP private key | SSH authentication for Groupon Transfer SFTP | Pod volume (`~/.ssh-key/id_rsa`) |

> Secret values are NEVER documented. Only names and rotation policies. Secrets repo: `https://github.groupondev.com/sox-inscope/voucher-inventory-jtier-secret/`

## Per-Environment Overrides

- **Development**: Local YAML with tunnel-based staging database connections; staging MessageBus endpoints
- **Staging (cloud)**: Separate GCP/AWS clusters per region; staging MessageBus (`mbus-stg-na.us-central1.mbus.stable.gcp.groupondev.com`); staging Redis (`vis--redis.staging`); `enableCalendarService: true`
- **Production (on-prem, SNC1)**: On-premises VIPs for all dependencies; `enableJedisCluster: false`; `isFeatureUpdateAllowed: true`; `enableRwDatabase: true`; Quartz cron every 10 minutes
- **Production (cloud, NA)**: GCP us-central1 or AWS us-west-1 endpoints; `enableJedisCluster: true`; env vars control RW and feature update behavior; HPA min 5 / max 60 replicas
- **Production (cloud, EMEA)**: GCP europe-west1 or AWS eu-west-1 endpoints; same config pattern as NA cloud; separate SFTP path (`/groupon-transfer-prod-voucher-inventory/EMEA`)

### Key Config Values

| Config Key | Description | Example Value |
|------------|-------------|--------------|
| `additionalMbusConfig.inventoryProductTTL` | Redis TTL for inventory product cache entries | 10,800 seconds |
| `additionalMbusConfig.unitSoldCountTTL` | Redis TTL for unit sold count cache entries | 600 seconds |
| `additionalMbusConfig.mbusConsumerPollTime` | MessageBus consumer polling interval | 10,000ms |
| `additionalServerConfig.parallelThread` | Thread pool size for parallel processing | 65 |
| `additionalServerConfig.availabilitySegmentDefaultPeriod` | Default period (days) for availability segments | 30 |
| `server.maxThreads` | Jetty thread pool maximum | 500 (production) |
| `server.minThreads` | Jetty thread pool minimum | 50 (production) |
| `server.maxQueuedRequests` | Maximum queued requests | 50 |
| `redis.maxTotal` | Redis connection pool size | 2,000 |
| `quartz` | Ouroboros cron schedule (production SNC1) | Every 10 min (`0 2,12,22,30,48,58 * * * ?`) |
