---
service: "deal-service"
title: Configuration
generated: "2026-03-02"
type: configuration
config_sources: [env-vars, keldor-config]
---

# Configuration

## Overview

Deal Service is configured via two mechanisms: environment variables injected at container startup (Kubernetes secrets and config maps), and runtime feature flags loaded from the Keldor Config Service via the `keldor-config` library. Environment variables cover infrastructure connectivity and API client credentials. Keldor-config provides operational knobs (batch sizes, polling intervals, on/off toggles) that can be changed without redeployment. The `configLoader_Dea` component loads keldor-config on startup and registers a `configUpdate` listener so that configuration changes take effect at the next polling cycle.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DEPLOY_ENV` | Deployment environment identifier (production / staging / dev / local) | yes | — | env |
| `REDIS_LOCAL_HOST` | Hostname of the local Redis instance (job queue + scheduler) | yes | — | env |
| `REDIS_LOCAL_PORT` | Port of the local Redis instance | yes | — | env |
| `REDIS_BTS_HOST` | Hostname of the BTS cache Redis instance | yes | — | env |
| `REDIS_BTS_PORT` | Port of the BTS cache Redis instance | yes | — | env |
| `MONGO_STR` | MongoDB connection string for deal metadata store | yes | — | env |
| `DEAL_CATALOG_CLIENT_ID` | Client ID for Deal Catalog API authentication | yes | — | env |
| `GOODS_STORES_CLIENT_ID` | Client ID for Goods Stores API authentication | yes | — | env |
| `GEO_SERVICES_CLIENT_ID` | Client ID for Geo Services / Bhuvan API authentication | yes | — | env |
| `DMAPI_CLIENT_ID` | Client ID for Deal Management API authentication | yes | — | env |
| `M3_PLACES_CLIENT_ID` | Client ID for M3 Place Read Service authentication | yes | — | env |
| `M3_MERCHANT_SERVICE_CLIENT_ID` | Client ID for M3 Merchant Service authentication | yes | — | env |
| `SALESFORCE_PASSWORD` | Salesforce API password (secret) | yes | — | k8s-secret |
| `KELDOR_CONFIG_SOURCE` | URL / source identifier for the Keldor Config Service | yes | — | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

All flags are loaded via keldor-config and can be updated at runtime without redeployment.

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `feature_flags.processDeals.active` | Enable or disable deal processing loop | — | global |
| `feature_flags.processDeals.intervalInSec` | Queue polling interval in seconds | 5 | global |
| `feature_flags.processDeals.limit` | Maximum number of deals processed per batch cycle | 400 | global |
| `feature_flags.updateCycle.updateActiveInHours` | How often active deals are refreshed (hours since last update) | 2 | global |
| `feature_flags.updateCycle.updateInactiveInHours` | How often inactive deals are refreshed (hours since last update) | 24 | global |
| `deal_option_inventory_update.mbus_producer.active` | Enable or disable publishing of `INVENTORY_STATUS_UPDATE` events to the message bus | — | global |
| `deal_option_inventory_update.mbus_producer.topic` | Message bus topic name for inventory update events | — | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.ci.yml` | YAML | CI pipeline definition (runs `npm test` via gulp) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SALESFORCE_PASSWORD` | Salesforce API authentication password | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- `DEPLOY_ENV` distinguishes between `production`, `staging`, `dev`, and `local` environments.
- Redis host/port, MongoDB connection string, and API client IDs are injected differently per environment via Kubernetes config maps and secrets.
- Keldor-config flags can be adjusted per-environment by targeting a different `KELDOR_CONFIG_SOURCE` endpoint; this allows staging to run with a smaller batch size or shorter polling interval than production.
- Production regions: `production-us-west-1`, `production-us-central1`. Staging regions: `staging-us-west-1`, `staging-us-central1`.
