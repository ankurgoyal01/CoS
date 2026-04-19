---
service: "product-bundling-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

Product Bundling Service uses Dropwizard YAML configuration files loaded at startup. The active config file path is supplied via the `JTIER_RUN_CONFIG` environment variable, which points to an environment-specific YAML file (e.g., `cloud/production-us-central1.yml` or `cloud/staging-us-central1.yml`). Secrets such as database credentials and client IDs are embedded in the environment-specific config files managed outside this repository. The development config is `src/main/resources/config/development.yml`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active runtime YAML configuration file | yes | None | env (set by Kubernetes deployment manifest) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `isCronEnabled` | Enables or disables all Quartz scheduler cron triggers | `true` (implied) | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration with localhost database hosts and staging service URLs |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Kubernetes deployment settings (scaling, resource requests, port config, log config) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | GCP production overrides (VIP, scaling limits, `JTIER_RUN_CONFIG` path) |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | GCP staging overrides (VIP, scaling limits, `JTIER_RUN_CONFIG` path) |

## Key Configuration Properties

| Property | Purpose | Example Value (dev) |
|----------|---------|---------------------|
| `readPostgres` | PostgreSQL read-replica connection settings (host, port, database, user) | `localhost:5432/pbs_development` |
| `writePostgres` | PostgreSQL write-primary connection settings | `localhost:5432/pbs_development` |
| `allowedBundleTypes` | Ordered allowlist of valid bundle types; order indicates priority | `["warranty", "item-authority", "acquisition", "retention", "battery", "combo", "fbt"]` |
| `allowedRefreshTypes` | Allowlist of valid refresh types for the refresh endpoint | `["warranty", "customer_also_bought", "customer_also_bought_2", "customer_also_viewed", "sponsored_similar_item"]` |
| `maxBundleValuesAllowed` | Maximum number of bundle values permitted per bundle | `6` |
| `cacheControlMaxAgeInDays` | `max-age` days for `Cache-Control` headers on GET responses | `5` |
| `isCronEnabled` | Toggle for Quartz scheduler cron activation | `true` |
| `dealCatalogServiceClient.url` | Base URL for Deal Catalog Service HTTP client | `http://deal-catalog-staging.snc1` |
| `voucherInventoryServiceClient.url` | Base URL for Voucher Inventory Service HTTP client | `http://voucher-inventory-ht-staging.snc1` |
| `goodsInventoryServiceClient.url` | Base URL for Goods Inventory Service HTTP client | `http://goods-inventory-service-vip-staging.snc1` |
| `fluxServiceClient.url` | Base URL for Flux API HTTP client | Environment-specific |
| `pollingLimit` | Maximum number of polling attempts for Flux run status | Environment-specific |
| `pollingInterval` | Milliseconds between Flux run status polls | Environment-specific |
| `fluxModelId` | Map of refresh type to Flux model UUID | Environment-specific |
| `kafkaConfig` | Watson KV Kafka producer settings (broker, topic, etc.) | Environment-specific |
| `hadoopInputClient` | HDFS input client configuration (Cerebro cluster URI, credentials) | Environment-specific |
| `hadoopOutputClient` | HDFS output client configuration (Gdoop cluster URI, credentials) | Environment-specific |
| `warrantyEligiblePdsCategories` | List of product/deal-structure category UUIDs eligible for warranty bundles | ~50 UUIDs (see development.yml) |
| `warrantyOptions` | Map of product UUID to min/max warranty price range | Environment-specific |
| `inputHeader` | Map of refresh type to HDFS input header columns for parsing | Environment-specific |
| `DCSDAGConfiguration.pbsBaseUrl` | PBS base URL used by Deal Catalog DAG to retrieve bundle data | `product-bundling-service-staging-vip.snc1/v1/bundles/` |
| `DCSDAGConfiguration.requestTimeoutMs` | Timeout in ms for DCS DAG requests | `999` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `readPostgres.app.pass` | PostgreSQL read user password | Environment config file (managed externally) |
| `writePostgres.app.pass` | PostgreSQL write user password | Environment config file (managed externally) |
| `dealCatalogServiceClient.authenticationOptions.value` | Client ID value for DCS authentication | Environment config file |
| `voucherInventoryServiceClient.authenticationOptions.value` | Client ID value for VIS authentication | Environment config file |
| `goodsInventoryServiceClient.authenticationOptions.value` | Client ID value for GIS authentication | Environment config file |
| `productBundlingServiceClient.authenticationOptions.value` | Client ID used by the warranty job to call the internal PBS API | Environment config file |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Uses `localhost` for PostgreSQL and staging service URLs. Cron expressions set for development testing times.
- **Staging (GCP us-central1)**: `JTIER_RUN_CONFIG` points to `cloud/staging-us-central1.yml`; 1–2 Kubernetes replicas; VIP: `product-bundling-service.us-central1.conveyor.stable.gcp.groupondev.com`
- **Production (GCP us-central1)**: `JTIER_RUN_CONFIG` points to `cloud/production-us-central1.yml`; 2–50 Kubernetes replicas (HPA); VIP: `product-bundling-service.us-central1.conveyor.prod.gcp.groupondev.com`
- **Production (snc1 on-prem)**: VIP: `http://product-bundling-service-vip.snc1`
- **Staging (snc1 on-prem)**: VIP: `http://product-bundling-service-staging-vip.snc1`

## Quartz Scheduler Configuration

| Trigger Name | Job | Cron Expression (dev) | Purpose |
|---|---|---|---|
| `WarrantyBundlesRefreshTrigger` | `WarrantyBundlesRefreshJob` | `0 33 09 * * ?` | Daily warranty bundle refresh |
| `customer_also_bought` | `RecommendationsRefreshJob` | `0 26 08 * * ?` | Daily customer-also-bought recommendation refresh |
| `customer_also_bought_2` | `RecommendationsRefreshJob` | `0 26 06 * * ?` | Secondary daily customer-also-bought recommendation refresh |
| `customer_also_viewed` | `RecommendationsRefreshJob` | `0 33 08 * * ?` | Daily customer-also-viewed recommendation refresh |
| `sponsored_similar_item` | `RecommendationsRefreshJob` | `0 30 09 * * ?` | Daily sponsored-similar-item recommendation refresh |
