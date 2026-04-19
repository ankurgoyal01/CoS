---
service: "coupons-ui"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Coupons UI uses a layered YAML configuration system managed by the Configuration Loader component. At startup, the loader reads `config/base.yml` as the base configuration, then deep-merges the environment+region-specific file (e.g., `config/production-us-central1.yml`). String values containing `${VARIABLE_NAME}` placeholders are interpolated from process environment variables at runtime. The active environment and region are determined by `DEPLOY_ENV` and `DEPLOY_REGION` environment variables, which must both be present for the application to start.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DEPLOY_ENV` | Selects the environment tier (`local`, `staging`, `production`) | yes | none | env |
| `DEPLOY_REGION` | Selects the deployment region (e.g., `us-central1`, `europe-west1`) | yes | none | env |
| `VCAPI_US_API_KEY` | VoucherCloud API authentication key | yes | none | env / k8s-secret |
| `ALGOLIA_API_ID` | Algolia application ID for merchant search | yes | none | env / k8s-secret |
| `ALGOLIA_API_KEY` | Algolia API key for merchant search | yes | none | env / k8s-secret |
| `NODE_ENV` | Node.js runtime mode; set to `production` in Docker image | no | `development` | env |
| `HOST` | Server bind address | no | `0.0.0.0` | env (set in Dockerfile) |
| `PORT` | Astro server listen port (dev/preview only) | no | `3000` | env |
| `ASTRO_TELEMETRY_DISABLED` | Disables Astro telemetry collection | no | `1` (set in Dockerfile) | env |
| `UV_THREADPOOL_SIZE` | Node.js libuv thread pool size | no | `75` (set in `common.yml`) | env |
| `TELEGRAF_URL` | InfluxDB/Telegraf endpoint URL for metrics emission | no | none | env |
| `TELEGRAF_METRICS_ATOM` | Atom tag for Telegraf metrics | no | `test` | env |
| `DEPLOY_AZ` | Availability zone tag for Telegraf metrics | no | `test` | env |
| `DEPLOY_NAMESPACE` | Kubernetes namespace tag for Telegraf metrics | no | `test` | env |
| `DEPLOY_SERVICE` | Service name tag for Telegraf metrics | no | `test` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `gtm.enabled` | Enables Google Tag Manager script injection | `false` (base config) | per-region |

GTM is enabled in all production and staging environments by setting `gtm.enabled: true` in the region-specific config file. The `gtm.containerId` value selects the GTM container (`GTM-M9ZZMHWR` for NA, `GTM-M2V33QHP` for INTL).

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.yml` | YAML | Base configuration for all environments: Redis defaults, in-memory cache size, logging, VoucherCloud API host/timeouts/retries, country URL schemes, Algolia credentials placeholders |
| `config/production-us-central1.yml` | YAML | Production US overrides: Redis host (GCP Memorystore), GTM NA container, replica counts |
| `config/production-eu-west1.yml` | YAML | Production EU overrides: Redis host (GCP Memorystore), GTM INTL container |
| `config/staging-us-central1.yml` | YAML | Staging US overrides: Redis host, GTM container, staging country domains, staging Algolia index |
| `config/staging-europe-west1.yml` | YAML | Staging EU overrides: Redis host, GTM container |
| `config/local-us-central1.yml` | YAML | Local development overrides for US region |
| `config/docker-us-central1.yml` | YAML | Docker-local overrides for US region |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `VCAPI_US_API_KEY` | VoucherCloud API authentication | k8s-secret (managed by Raptor/Conveyor deployment) |
| `ALGOLIA_API_ID` | Algolia application ID | k8s-secret |
| `ALGOLIA_API_KEY` | Algolia search-only API key | k8s-secret |

> Secret values are never documented. Only names and purposes are listed.

## Per-Environment Overrides

| Setting | Local | Staging | Production |
|---------|-------|---------|------------|
| Redis host | `localhost` | `coupons-ui-memorystore.us-central1.caches.stable.gcp.groupondev.com` | `coupon-worker-memorystore.{region}.caches.prod.gcp.groupondev.com` |
| Redis max retries | `3` | `5` | `5` |
| GTM enabled | `false` | `true` | `true` |
| VoucherCloud host | `https://restfulapi.vouchercloud.com` | `https://staging-restfulapi.vouchercloud.com` | `https://restfulapi.vouchercloud.com` |
| Algolia index | `Merchants` | `Merchants_Staging` | `Merchants` |
| US country domain | `www.groupon.com` | `staging.groupon.com` | `www.groupon.com` |
| Log batch size | `1000` | `10` | `1000` |
