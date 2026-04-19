---
service: "ugc-moderation"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

UGC Moderation uses a layered CSON configuration system managed by `keldor-config`. Config files live in `config/` and are merged in order: `base.cson` provides defaults, then `config/node-env/<NODE_ENV>.cson` overlays runtime-environment-specific values, then `config/stage/<STAGE>.cson` applies stage-specific values (staging or production). The active config source is selected at runtime via the `KELDOR_CONFIG_SOURCE` environment variable injected by the Kubernetes deployment manifest.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Selects the keldor config stage (`{staging}` or `{production}`) | yes | none | helm (deploy config) |
| `NODE_ENV` | Node.js environment mode (`production`, `development`, `test`) | yes | `development` | env / helm |
| `NODE_OPTIONS` | Node.js heap size flag (e.g. `--max-old-space-size=1024`) | yes | none | helm (deploy config) |
| `PORT` | HTTP server listening port | yes | `8000` (base.cson) | helm (deploy config) |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for async I/O | yes | none (75 in deployments) | helm (deploy config) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `dynamicConfig.interval` | Polling interval (ms) for dynamic config refresh | 60000 ms | global |
| `templates.reload` | Hot-reload Mustache templates without restart | `true` (non-production) | per-environment |

> Feature flags are managed via the `itier-feature-flags` library. No named feature flags beyond the base configuration were identified in the source.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base defaults for all environments: API client IDs, Memcached, server port, UGC admin allowlist, image reason ID mappings |
| `config/node-env/development.cson` | CSON | Development-specific overrides |
| `config/node-env/production.cson` | CSON | Production-specific overrides (logging: tracky to file) |
| `config/node-env/test.cson` | CSON | Test-specific overrides |
| `config/stage/production.cson` | CSON | Production stage: CDN hosts (`www<1,2>.grouponcdn.com`), `serviceClient.globalDefaults.baseUrl: {production}`, full Okta admin/imageAdmin username allowlists |
| `config/stage/staging.cson` | CSON | Staging stage: CDN hosts (`staging<1,2>.grouponcdn.com`), staging service URLs |
| `.deploy-configs/production-us-west-1.yml` | YAML | Kubernetes deployment config for production us-west-1 (AWS) |
| `.deploy-configs/production-us-central1.yml` | YAML | Kubernetes deployment config for production us-central1 (GCP) |
| `.deploy-configs/staging-us-central1.yml` | YAML | Kubernetes deployment config for staging us-central1 (GCP) |
| `.deploy-configs/values.yaml` | YAML | Shared Helm values (resource limits, log config, service ID) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `api.base_urls.main.US.client_id` | API client ID for US region main API | keldor-config (CSON) |
| `serviceClient.globalDefaults.clientId` | Service-to-service client identity | keldor-config (CSON) |
| `serviceClient.grouponV2.clientId.US` | Groupon V2 API client identity for US | keldor-config (CSON) |
| `server.secret` | Express session / CSRF secret | keldor-config (CSON base — overridden in production) |

> Secret values are never documented here. Actual values are managed in keldor-config and the deployment secrets system.

## Per-Environment Overrides

- **Development**: Memcached at `localhost:11211`; templates hot-reload enabled; no Okta enforcement (`NODE_ENV !== 'production'`)
- **Staging**: `KELDOR_CONFIG_SOURCE={staging}`; CDN hosts `staging<1,2>.grouponcdn.com`; serviceClient baseUrl points to staging endpoints; min 1 replica, max 2 replicas per region
- **Production**: `KELDOR_CONFIG_SOURCE={production}`; CDN hosts `www<1,2>.grouponcdn.com`; `grouponBaseUrl=https://www.groupon.com`; full Okta admin allowlist enforced; min 2 replicas, max 3–4 replicas depending on region; Okta middleware fully active

## Notable Config Values

| Key | Value | Purpose |
|-----|-------|---------|
| `server.port` | 8000 | HTTP listen port |
| `server.child_processes` | 2 | Number of cluster worker processes |
| `memcached.poolSize` | 100 | Memcached connection pool size |
| `memcached.timeout` | 100 ms | Memcached operation timeout |
| `cache.'taxonomy:business'.expire` | 2592000 s (30 days) | Hard expiry for taxonomy cache entries |
| `cache.'taxonomy:business'.freshFor` | 864000 s (10 days) | Stale-while-revalidate freshness window |
| `tracing.sampleRate` | 1 | 100% trace sampling rate |
| `imageReasonIdToText.idToText` | 7 reason ID mappings | Human-readable labels for image rejection reason UUIDs |
