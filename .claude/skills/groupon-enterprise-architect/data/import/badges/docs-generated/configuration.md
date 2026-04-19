---
service: "badges-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, yaml-config-files, kubernetes-deployment-manifests]
---

# Configuration

## Overview

The Badges Service is configured through a layered system: a YAML configuration file (JTier convention) whose path is set by the `JTIER_RUN_CONFIG` environment variable, overlaid by Kubernetes deployment manifest values in `.meta/deployment/cloud/components/`. Configuration is split across two deployment components — `api` (REST server, ENABLE_JOBS=false) and `jobs` (background job runner, ENABLE_JOBS=true).

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the per-environment YAML configuration file loaded at startup | Yes | None (must be provided per env) | Kubernetes deployment manifest (`envVars`) |
| `ENABLE_JOBS` | Controls whether Quartz background jobs (LocalizationJob, MerchandisingBadgeJob) are active | Yes | `false` (api component), `true` (jobs component) | Kubernetes deployment manifest (`envVars`) |
| `MIN_RAM_PERCENTAGE` | JVM minimum heap as a percentage of container memory | No | `70.0` | `common.yml` (api component) |
| `MAX_RAM_PERCENTAGE` | JVM maximum heap as a percentage of container memory | No | `70.0` | `common.yml` (api component) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arenas to reduce off-heap fragmentation | No | `4` | `common.yml` (api component) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `ENABLE_JOBS` | Toggles all Quartz background jobs on or off for a given pod; the `jobs` component sets this `true`, the `api` component sets this `false`, ensuring job execution is isolated to a single-replica `jobs` pod | `false` (api), `true` (jobs) | per-deployment-component |
| `isBadgeJobEnabled` | Internal guard within `MerchandisingBadgeJob` — read from YAML config; gates whether the merchandising badge refresh loop executes | Configured per environment | global (per JVM) |
| `sellingFastDisableDistributionWindowEffects` | When enabled, removes distribution window constraints from Selling Fast badge computation | false | global (per JVM) |
| `obfuscationConfig` | Controls whether urgency-message quantity/count data is obfuscated in v3 responses (v4 bypasses obfuscation) | Configured per environment | per-request (v3 vs v4) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `JTIER_RUN_CONFIG` (e.g., `cloud/production-us-central1.yml`) | YAML | Per-environment JTier run configuration; contains Redis endpoints, Janus endpoint, taxonomy URL, localization config, context config, app thresholds, and job schedules |
| `.meta/deployment/cloud/components/api/common.yml` | YAML | Common Kubernetes deployment values for the API component (image, scaling, resource requests, log config, ports) |
| `.meta/deployment/cloud/components/api/production-us-central1.yml` | YAML | Production US Central1 overrides (min/max replicas, memory limits) |
| `.meta/deployment/cloud/components/api/production-europe-west1.yml` | YAML | Production Europe West1 overrides (min/max replicas, Filebeat Kafka endpoint) |
| `.meta/deployment/cloud/components/api/staging-us-central1.yml` | YAML | Staging US Central1 overrides |
| `.meta/deployment/cloud/components/api/staging-europe-west1.yml` | YAML | Staging Europe West1 overrides |
| `.meta/deployment/cloud/components/jobs/common.yml` | YAML | Common Kubernetes deployment values for the jobs component (ENABLE_JOBS=true, single replica) |
| `.meta/deployment/cloud/components/jobs/production-*.yml` | YAML | Per-region production overrides for jobs component |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Redis connection credentials | Authentication to STaaS Redis cluster; connection details in `redisConfig` and `redisClusterConfig` blocks of YAML run config | JTier secrets management / Kubernetes secret |
| Janus endpoint URL | Base URL for Janus deal-stats API; stored in `janusConfig.endpoint` of YAML run config | YAML run config (environment-specific file) |

> Secret values are NEVER documented. Only names and purposes are shown.

## Per-Environment Overrides

### Staging (us-central1 / europe-west1)
- Replicas: `minReplicas: 1`, `maxReplicas: 5`
- `JTIER_RUN_CONFIG` points to staging YAML file
- Reduced resource requests versus production

### Production (us-central1)
- Replicas: `minReplicas: 3`, `maxReplicas: 20`
- Memory: request `6Gi`, limit `8Gi`
- `JTIER_RUN_CONFIG`: `/var/groupon/jtier/config/cloud/production-us-central1.yml`

### Production (europe-west1)
- Replicas: `minReplicas: 3`, `maxReplicas: 20`
- Filebeat Kafka endpoint: `kafka-elk-broker.dub1`, env: `production`
- `JTIER_RUN_CONFIG`: `/var/groupon/jtier/config/cloud/production-europe-west1.yml`

### Key YAML config sections (from `BadgesConfiguration.java`)

| Config Block | Purpose |
|---|---|
| `redisConfig` | Primary Redis connection (single-node or sentinel) |
| `redisClusterConfig` | Redis cluster connection for Lettuce async client |
| `contextConfig` | Per-context badge rules map (channel/surface configuration) |
| `recentlyViewedServiceConfig` | Watson KV base URL and timeout settings |
| `badgesTaxonomyConfig` | Taxonomy API URL, refresh interval, and HTTP timeouts |
| `userItemBadgeCachingConfig` | TTL and behavior for user-item badge entries in Redis |
| `janusConfig` | Janus endpoint URL plus per-query cache TTLs and hard timeouts |
| `appConfig` | Badge threshold maps (daily views/purchases, selling fast ratios, quantity thresholds, country-to-locale map) |
| `dealCatalogConfig` | Deal Catalog Service endpoint and connection settings |
| `merchandisingTagConfig` | Map of `badgeType -> taxonomyUUID` used by `MerchandisingBadgeJob` |
| `quartz` | Quartz job schedule configuration (cron expressions for LocalizationJob and MerchandisingBadgeJob) |
| `featureToggleConfig` | Feature flags for badge logic overrides |
| `obfuscationConfig` | Urgency-message obfuscation rules |
| `pdsExclusion`, `umsExclusionConfig`, `umsTaxonomyConfig`, `umsMessagesConfig` | Urgency-message service exclusion lists and taxonomy/message rules |
