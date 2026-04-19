---
service: "itier-mobile"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, cson-config-files, helm-values, keldor-config]
---

# Configuration

## Overview

`itier-mobile` uses a layered configuration system based on CSON files managed by `keldor` / `keldor-config`. Base configuration (`config/base.cson`) is overridden by node-env overlays (`config/node-env/*.cson`) and stage overlays (`config/stage/*.cson`). Kubernetes environment variables are injected at runtime via Helm values in `.deploy-configs/*.yml`. The active config source at runtime is selected by the `KELDOR_CONFIG_SOURCE` environment variable.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Selects the keldor configuration environment (`{staging}` or `{production}`) | Yes | None | Helm (`.deploy-configs/*.yml`) |
| `NODE_OPTIONS` | Node.js runtime tuning, e.g., `--max-old-space-size=1024` | Yes | None | Helm (`.deploy-configs/*.yml`) |
| `PORT` | HTTP port the service listens on | Yes | `8000` | Helm (`.deploy-configs/*.yml`) |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for async I/O | Yes | `75` | Helm (`.deploy-configs/*.yml`) |
| `TLS_CERT_CHECK_MS` | Interval (ms) for TLS certificate validity checks | Yes | `300000` | Helm (`.deploy-configs/*.yml`) / `package.json` napistrano envVars |
| `IAM_METADATA` | Optional IAM metadata injected at Docker build time for CI | No | None | Docker build-arg |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `UL_flashdeal` | Enables Universal Links for flash deal routing | `country: US, CA` | per-region |
| `UL_gamification_challenge` | Enables Universal Links for gamification challenges | `brand: groupon AND country: US, CA` | per-brand, per-region |
| `UL_landing` | Enables Universal Links for landing pages | `true` | global |
| `UL_merchant_deals` | Enables Universal Links for merchant deal pages | `true` | global |
| `UL_merchant_inbox` | Enables Universal Links for merchant inbox | `true` | global |
| `UL_merchant_inbox_details` | Enables Universal Links for merchant inbox details | `true` | global |
| `UL_merchant_support` | Enables Universal Links for merchant support | `true` | global |
| `UL_merchant_2fa_enrollment` | Enables Universal Links for merchant 2FA enrollment | `true` | global |
| `UL_merchant_2fa_de_enrollment` | Enables Universal Links for merchant 2FA de-enrollment | `true` | global |
| `email_to_app_browse_ipad` | Enables email-to-app browse experience on iPad | `true` | global |
| `feature_flag_switcher` | Runtime flag switcher UI | `false` | global |
| `rate_limiter` | Enables rate limiting on SMS endpoints to prevent abuse | `true` | global |
| `itier_browser_test` | Client-side experiment flag for browser testing | — | per-user (Expy) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base configuration: asset hosts, dispatch env, feature flags, service client defaults, per-country site URLs, steno transport |
| `config/node-env/development.cson` | CSON | Development overrides |
| `config/node-env/production.cson` | CSON | Production overrides (enables file-based tracky logging) |
| `config/node-env/test.cson` | CSON | Test environment overrides |
| `config/stage/production.cson` | CSON | Production stage: asset CDN hosts (`www<1,2>.grouponcdn.com`), production site URLs per country, `dispatch.env: production` |
| `config/stage/staging.cson` | CSON | Staging stage: asset CDN hosts (`staging<1,2>.grouponcdn.com`), staging site URLs per country, `dispatch.env: staging` |
| `config/stage/uat.cson` | CSON | UAT stage configuration |
| `.deploy-configs/values.yaml` | YAML | Base Helm values for napistrano deployments |
| `.deploy-configs/production-us-central1.yml` | YAML | Production GCP us-central1 Helm overrides |
| `.deploy-configs/staging-us-central1.yml` | YAML | Staging GCP us-central1 Helm overrides |
| `doc/openapi.yml` | YAML | OpenAPI 3.0.0 schema for this service |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Twilio Account SID | Authenticates Twilio REST API calls for SMS sending | `itier_shared_user_secrets` repo (not in this codebase) |
| Twilio Auth Token | Authenticates Twilio REST API calls for SMS sending | `itier_shared_user_secrets` repo (not in this codebase) |
| `apiProxyClientId` | Client ID for internal API proxy calls (`D06D437DF42195EC4F7AA6BA9440E92A` in staging) | `config/base.cson` (client ID only — non-secret identifier) |

> Secret values are NEVER documented here. Only names and rotation policies are tracked.

## Per-Environment Overrides

- **Development**: Uses `config/node-env/development.cson` overlaid on base; `KELDOR_CONFIG_SOURCE` points to a local or staging backend
- **Staging**: `config/stage/staging.cson` overrides asset CDN to `staging<1,2>.grouponcdn.com`, all site URLs point to `staging.groupon.*` domains; `KELDOR_CONFIG_SOURCE: "{staging}"`; Kubernetes: 1–3 replicas in `itier-mobile-staging` namespace
- **Production**: `config/stage/production.cson` overrides asset CDN to `www<1,2>.grouponcdn.com`, all site URLs point to `www.groupon.*` domains; `KELDOR_CONFIG_SOURCE: "{production}"`; Kubernetes: 2–20 replicas (HPA target 100%) in `itier-mobile-production` namespace
- **UAT**: `config/stage/uat.cson`; base URLs at `uat.groupon.com`
