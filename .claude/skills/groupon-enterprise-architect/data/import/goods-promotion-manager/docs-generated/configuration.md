---
service: "goods-promotion-manager"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secret]
---

# Configuration

## Overview

Goods Promotion Manager is configured through a combination of JTier YAML configuration files (per-environment) and Kubernetes environment variables injected at runtime. The active configuration file is selected by the `JTIER_RUN_CONFIG` environment variable. Secrets (database credentials, client-ID keys) are managed via Kubernetes secrets referenced in `.meta/deployment/cloud/secrets`. Feature flags controlling ILS business rules are embedded in the JTier YAML config as top-level boolean fields.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active JTier YAML config file for the current environment | Yes | None | Kubernetes (env in deployment YAML) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arenas to prevent virtual memory explosion and container OOM kills | No | `4` | `.meta/deployment/cloud/components/app/common.yml` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

These flags are defined as top-level boolean fields in the JTier YAML config file and injected into the application at startup via `GoodsPromotionManagerConfiguration`.

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `ilsFeatureFlagEnabled` | Master toggle for ILS (Inventory Lifecycle Staging) feature processing | Not specified in code; set per environment | global |
| `ils50PercentRuleFlagEnabled` | Enables the ILS 50% Rule check in deal promotion eligibility evaluation (an inventory product may not be on promotion more than 50% of a 90-day window) | Not specified in code; set per environment | global |
| `ilsRestingRuleFlagEnabled` | Enables the ILS Resting Rule check in eligibility evaluation (an inventory product must not have been on promotion within a 2-day window) | Not specified in code; set per environment | global |
| `ilsTagFeatureFlagEnabled` | Enables ILS tag-based features | Not specified in code; set per environment | global |

Additionally, an `ARCHIVE` feature flag record stored in the `feature_flag` database table controls whether promotion list queries are filtered to a configurable number of recent months.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/` (JTier convention) | YAML | Per-environment JTier runtime config containing `postgres`, `quartz`, `dealManagementApiClient`, `corePricingApiClient`, `clientId`, `clientIds`, ILS feature flags, and `dmapiBatchSize` |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Kubernetes deployment common config: `httpPort: 8080`, `admin-port: 8081`, `jmx-port: 8009`, `MALLOC_ARENA_MAX: 4`, HPA and VPA settings |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging-specific K8s config: GCP `stable` VPC, `us-central1`, 1–2 replicas, 500m CPU request, 2Gi–6Gi memory |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production-specific K8s config: GCP `prod` VPC, `us-central1`, 2–10 replicas, 2000m CPU request, 10Gi–30Gi memory |
| `.deploy_bot.yml` | YAML | Deploybot pipeline configuration: staging promotes to production, Kubernetes cluster targets |
| `doc/swagger/config.yml` | YAML | Swagger UI configuration for API documentation |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.meta/deployment/cloud/secrets` | Database credentials, client-ID authentication keys, and other service secrets | Kubernetes secrets (path defined in `.meta/.raptor.yml`) |

> Secret values are NEVER documented. Only paths and purposes are listed.

## Per-Environment Overrides

| Setting | Staging (`staging-us-central1`) | Production (`production-us-central1`) |
|---------|--------------------------------|--------------------------------------|
| `JTIER_RUN_CONFIG` | `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | `/var/groupon/jtier/config/cloud/production-us-central1.yml` |
| GCP VPC | `stable` | `prod` |
| Kubernetes namespace | `goods-promotion-manager-staging-sox` | `goods-promotion-manager-production-sox` |
| Min / Max replicas | 1 / 2 | 2 / 10 |
| CPU request | 500m | 2000m |
| Memory request / limit | 2Gi / 6Gi | 10Gi / 30Gi |
| VIP (internal URL) | `goods-promotion-manager.us-central1.conveyor.stable.gcp.groupondev.com` | `goods-promotion-manager.us-central1.conveyor.prod.gcp.groupondev.com` |

The `dmapiBatchSize` configuration controls the batch size for Deal Management API calls during the Import Product Job and is set per environment in the JTier config YAML.
