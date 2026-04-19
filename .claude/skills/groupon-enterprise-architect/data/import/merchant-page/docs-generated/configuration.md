---
service: "merchant-page"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

The merchant-page service uses the `keldor` / `keldor-config` runtime configuration system. CSON configuration files are layered by environment: `config/base.cson` provides defaults, `config/node-env/{development,production,test}.cson` applies Node environment overlays, and `config/stage/{staging,production}.cson` applies deployment-stage overrides. At runtime, `KELDOR_CONFIG_SOURCE` selects the active stage config. Additional runtime tuning (memory limits, thread pool size, port) is delivered via Kubernetes environment variables defined in the Helm deploy configs.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Selects the keldor stage config (`{staging}` or `{production}`) | Yes | `{staging}` (base) | helm / deploy config |
| `NODE_OPTIONS` | Node.js runtime options (e.g., heap size) | Yes | `--max-old-space-size=1024` | helm / deploy config |
| `PORT` | HTTP port the service listens on | Yes | `8000` | helm / deploy config |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for async I/O | Yes | `75` | helm / deploy config |
| `NODE_ENV` | Node environment (`development`, `test`, `production`) | Yes | `production` in containers | container runtime |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

Feature flags are managed via `itier-feature-flags` and configured in `config/base.cson` under the `feature_flags` key. The `catfood` environment can override flags via `keldor_feature_flags__feature_flag_switcher: true`.

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `multi_place_id_deals` | Enables multi-place-ID deal matching for the merchant | `true` | global |
| `proxy_deal` | When enabled and merchant has exactly one deal, proxies the request to the deal page | `true` | global |
| `show_miles` | Controls whether distances are displayed in miles (vs. km) | `['country', 'US', 'GB']` | per-country |
| `show_non_affiliation` | Controls display of the non-affiliation banner and popover for non-Groupon merchants | `['country', 'US']` | per-country |
| `show_related_places` | Enables the related places crosslinks module | `false` | global |
| `megamind_widgets` | (Legacy) Enables/disables megamind widget and deal calls | referenced in OWNERS_MANUAL | global |
| `nearby_deals_map` | (Legacy) Enables/disables nearby deals map API call | referenced in OWNERS_MANUAL | global |
| `merchant_specials` | (Legacy) Enables/disables merchant specials API call | referenced in OWNERS_MANUAL | global |
| `coupons` | (Legacy) Enables/disables coupons API call | referenced in OWNERS_MANUAL | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base configuration: cache TTLs, card UI settings, feature flags, map config, service client defaults |
| `config/node-env/production.cson` | CSON | Production Node env: enables file-based tracky logging |
| `config/node-env/development.cson` | CSON | Development Node env overrides |
| `config/node-env/test.cson` | CSON | Test Node env overrides |
| `config/stage/production.cson` | CSON | Production stage: CDN hosts, merchant cache TTL (3600s), service client timeouts and socket limits |
| `config/stage/staging.cson` | CSON | Staging stage: staging CDN hosts |
| `.deploy-configs/values.yaml` | YAML | Helm chart baseline values (napistrano-managed) |
| `.deploy-configs/production-us-central1.yml` | YAML | Production GCP us-central1 deploy config: replicas, resource requests, env vars |
| `.deploy-configs/production-eu-west-1.yml` | YAML | Production AWS eu-west-1 deploy config: replicas, resource requests, env vars |
| `.deploy-configs/staging-us-central1.yml` | YAML | Staging GCP us-central1 deploy config |
| `.deploy-configs/staging-us-west-2.yml` | YAML | Staging AWS us-west-2 deploy config |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `secretEnvVars` (empty list) | No secrets injected via Kubernetes secret env vars | k8s-secret |
| `secretFiles` (empty map) | No secret files mounted | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies. The deploy configs show `secretEnvVars: []` and `secretFiles: {}`, indicating no secrets are currently injected at the Kubernetes level. API client credentials (`apiProxyClientId`, `clientId`) are embedded in CSON config and managed through the keldor configuration system.

## Per-Environment Overrides

| Setting | Base / Staging | Production |
|---------|---------------|------------|
| `serviceClient.globalDefaults.baseUrl` | `{staging}` | `{production}` |
| `serviceClient.globalDefaults.apiProxyBaseUrl` | `{staging}` | `{production}` |
| `serviceClient.globalDefaults.maxSockets` | not set | `150` |
| `serviceClient.globalDefaults.connectTimeout` | not set | `10000` ms |
| `serviceClient.globalDefaults.timeout` | not set | `10000` ms |
| `serviceClient.remoteLayout.timeout` | not set | `15000` ms |
| `serviceClient.dealProxy.timeout` | not set | `20000` ms |
| `cache.merchant.freshFor` | `60` seconds | `3600` seconds |
| `assets.hosts` | `staging<1,2>.grouponcdn.com` | `www<1,2>.grouponcdn.com` |
| `KELDOR_CONFIG_SOURCE` | `{staging}` | `{production}` |
| `keldor_feature_flags__feature_flag_switcher` | `true` (catfood only) | not set |
