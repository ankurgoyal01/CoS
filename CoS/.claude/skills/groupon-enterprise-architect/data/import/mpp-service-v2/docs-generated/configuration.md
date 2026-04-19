---
service: "mpp-service-v2"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

MPP Service V2 is configured through a JTier YAML configuration file whose path is specified by the `JTIER_RUN_CONFIG` environment variable at startup. Configuration is structured in top-level named blocks: `app`, `postgresql`, `mBus`, `domainLocales`, `localeDomain`, `quartz`, `indexSyncRateLimitMs`, and per-client Retrofit configuration blocks (`bhuvanClient`, `m3MerchantClient`, `m3PlaceClient`, `lpApiClient`, `taxonomyClient`, `salesForceAuthentication`, `salesforceClient`, `visClient`, `rapiClient`, `rapiClientEmea`). Non-secret deployment environment variables are set via the `.meta/deployment/cloud/components/app/` YAML files; secret values (database credentials, OAuth secrets) are injected via the JTier secrets management layer.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the JTier YAML configuration file for the environment | yes | — | env (set per environment in `.meta/deployment/cloud/`) |
| `MALLOC_ARENA_MAX` | Tune glibc memory arena count to prevent virtual memory explosion in containers | no | `4` | env (set in `common.yml`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `app.enableSitemapGeneration` | Enables or disables the sitemap generation Quartz job | — | global (per config file) |
| `app.useMockM3` | When true, uses a mock M3 output service for local development (uses place_id as merchant_place_id) | `false` | global (local dev only) |
| `mBus.isEnable` | Enables or disables MBus consumer registration | — | global (per config file) |
| `mBus.isWriteToM3` | When enabled, routes certain writes through M3 | — | global (per config file) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `JTIER_RUN_CONFIG` (env-specific path, e.g. `/var/groupon/jtier/config/cloud/production-us-central1.yml`) | YAML | Primary JTier configuration for the running environment — DB connections, client URLs, MBus destinations, Quartz config, app flags |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common deployment metadata: image, scaling defaults, port config, resource requests, logging config, `MALLOC_ARENA_MAX` |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging overrides: GCP us-central1, min 1 / max 2 replicas, `JTIER_RUN_CONFIG` path, VPA enabled |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging overrides: GCP europe-west1, min 1 / max 2 replicas, `JTIER_RUN_CONFIG` path, VPA enabled |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production overrides: GCP us-central1, min 3 / max 9 replicas, HPA target 60%, 1200m CPU, 4.6Gi–8Gi memory |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production overrides: GCP europe-west1, min 2 / max 9 replicas, HPA target 60%, 1200m CPU, 3Gi–8Gi memory |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production overrides: AWS eu-west-1, min 2 / max 9 replicas, HPA target 60%, 1400m CPU, 3Gi–8Gi memory |
| `conf/db_util/setup_local_db.sql` | SQL | Local development database setup — creates `mpp_service_local` DB, `mpp` user, `mpp_service` schema |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| PostgreSQL `readPostgres` credentials | Database username/password for the read replica | JTier secrets management |
| PostgreSQL `writePostgres` credentials | Database username/password for the write primary | JTier secrets management |
| Salesforce OAuth client credentials (`salesForceAuthentication`) | Client ID and secret for Salesforce OAuth token acquisition | JTier secrets management |
| Salesforce API credentials (`salesforceClient`) | Authentication for calling Salesforce Merchant URL APIs | JTier secrets management |
| MBus connection credentials | JMS broker authentication for message bus consumers | JTier secrets management |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging (GCP us-central1 / europe-west1)**: Scaled to min 1, max 2 replicas. VPA enabled. Low filebeat volume. Resource requests use common defaults (1000m CPU, 500Mi memory).
- **Production (GCP us-central1)**: Min 3, max 9 replicas. HPA target 60% CPU. 1200m CPU request, 4.6Gi memory request, 8Gi limit. VPA disabled. Medium filebeat volume.
- **Production (GCP europe-west1 / AWS eu-west-1)**: Min 2, max 9 replicas. HPA target 60% CPU. 1200–1400m CPU request, 3Gi memory request, 8Gi limit. VPA enabled (GCP) or enabled (AWS). Medium filebeat volume.
- **`indexSyncRateLimitMs`**: Controls the rate limit in milliseconds between index-sync batches; configured per-environment in the JTier YAML config.
