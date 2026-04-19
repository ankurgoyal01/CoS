---
service: "my_appointments_client"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, cson-config-files, helm-values]
---

# Configuration

## Overview

My Appointments Client is configured through three layered sources. CSON configuration files under `config/` are loaded and merged by `keldor-config` at startup, with the active environment determined by the `KELDOR_CONFIG_SOURCE` environment variable. Kubernetes deploy-time environment variables (set via napistrano-generated Helm values in `.deploy-configs/`) override or supplement the CSON config. Feature flags are evaluated at request time from the config-loaded flag map.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Selects the active config environment (`{staging}`, `{production}`) | Yes | `{staging}` (dev default) | Helm / `.deploy-configs/*.yml` |
| `PORT` | HTTP port the server listens on | Yes | `8000` | Helm / `Dockerfile` |
| `NODE_OPTIONS` | Node.js runtime options (e.g., heap size) | No | `--max-old-space-size=1024` | Helm / `.deploy-configs/*.yml` |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for async I/O | No | `75` | Helm / `.deploy-configs/*.yml` |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `availabilityPreviewEnhancements` | Enables enhanced availability preview UI in the booking widget | `true` | global |
| `emeaRedirectEnabled` | Redirects EMEA post-purchase bookings to the EMEA booking tool | `false` | global |
| `touch_enabled` | Enables the touch/mobile reservation page variant | `true` | global |
| `new_app_landing_page` | Enables a new landing page flow | `false` | global |
| `feature_flag_switcher` | Enables the runtime feature flag override switcher | `true` | global |
| `query_country_switcher` | Enables country switching via query parameter | `true` | global |
| `bookingConstraint` | Restricts booking to a specific region (e.g., `['region', 'US']`) | `['region', 'US']` | global |

Feature flag values are evaluated via `itier-feature-flags` at request time and exposed to the frontend widget via the `/mobile-reservation/next/jsapi-script-url` payload.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base configuration shared across all environments (server port, feature flags, service client defaults, steno transport) |
| `config/node-env/development.cson` | CSON | Development environment overrides |
| `config/node-env/production.cson` | CSON | Production log config (disables log-to-process, enables tracky file logging) |
| `config/node-env/test.cson` | CSON | Test environment overrides |
| `config/stage/production.cson` | CSON | Production stage overrides: CDN hosts (`www<1,2>.grouponcdn.com`), remote layout version, API timeouts (connectTimeout: 1000ms, timeout: 6000ms) |
| `config/local.cson.na-prod-overrides` | CSON | Local dev overrides pointing to NA production endpoints |
| `config/local.cson.emea-prod-overrides` | CSON | Local dev overrides pointing to EMEA production endpoints |
| `.deploy-configs/values.yaml` | YAML | Napistrano Helm chart base values (service ID, Filebeat config, resource limits) |
| `.deploy-configs/production-us-central1.yml` | YAML | GCP us-central1 production deploy config (replicas, DNS, VIP, HB ingress) |
| `.deploy-configs/production-eu-west-1.yml` | YAML | AWS eu-west-1 production deploy config |
| `.deploy-configs/production-europe-west1.yml` | YAML | GCP europe-west1 production deploy config |
| `.deploy-configs/staging-us-central1.yml` | YAML | GCP us-central1 staging deploy config |
| `.deploy-configs/staging-us-west-2.yml` | YAML | AWS us-west-2 staging deploy config |
| `.deploy-configs/staging-europe-west1.yml` | YAML | GCP europe-west1 staging deploy config |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `apiProxyClientId` | Service client ID for Groupon V2 API calls | Baked into base config (non-secret client ID) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development / Staging**: `KELDOR_CONFIG_SOURCE={staging}`. CDN hosts point to `staging<1,2>.grouponcdn.com`. `apiProxyBaseUrl` and `baseUrl` resolve to staging endpoints. Service client timeouts use base defaults.
- **Production**: `KELDOR_CONFIG_SOURCE={production}`. CDN hosts switch to `www<1,2>.grouponcdn.com`. `connectTimeout` is set to 1000 ms and `timeout` to 6000 ms. Log-to-process is disabled; tracky logs written to file.
- **Key behavioral difference**: The `emeaRedirectEnabled` feature flag is `false` by default and must be explicitly enabled per-environment to route EMEA post-purchase bookings to the external EMEA booking tool.

## Notable Config Values (`config/base.cson`)

| Key | Value | Purpose |
|-----|-------|---------|
| `server.port` | `8080` | Internal server port (overridden to `8000` by `PORT` env var in production) |
| `steno.transport` | `file` | Steno log transport mode |
| `tracing.sampleRate` | `0` | Distributed tracing sample rate (disabled by default) |
| `feature_flags.reserve.default_duration` | `7200` | Default reservation duration in seconds (2 hours) |
| `feature_flags.mobileSettings.maxOrderStatusFetch` | `5` | Maximum number of order status polls on mobile |
| `feature_flags.mobileSettings.orderStatusfetchInterval` | `1000` | Order status poll interval in milliseconds |
| `feature_flags.bookingToolPath` | `/reservations` | Path used for the booking tool redirect |
| `feature_flags.touch_version` | `1.1` | Touch page version identifier |
