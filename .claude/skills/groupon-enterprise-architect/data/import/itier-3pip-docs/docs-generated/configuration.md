---
service: "itier-3pip-docs"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "helm-values", "k8s-secret"]
---

# Configuration

## Overview

`itier-3pip-docs` uses the Keldor configuration system (`keldor-config` ^4.19.0). Configuration is layered: base CSON files (`config/base.cson`) are merged with environment-specific overrides (`config/node-env/` and `config/stage/`), and the active config source is selected via the `KELDOR_CONFIG_SOURCE` environment variable. Secrets (partner service credentials) are injected from Kubernetes secrets at deploy time via napistrano. Feature flags are defined in the config files and evaluated at runtime via `itier-feature-flags`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Selects the config environment (`{staging}` or `{production}`) | yes | None | helm (deploy-configs) |
| `NODE_OPTIONS` | Node.js runtime options (e.g. `--max-old-space-size=1024`) | yes | None | helm (deploy-configs) |
| `PORT` | HTTP server listen port | yes | `8000` | helm (deploy-configs) |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for async I/O operations | yes | `75` | helm (deploy-configs) |
| `PS_AUTH_USERNAME` | Partner service simulator basic auth username | yes | None | k8s-secret (`simulator`) |
| `PS_AUTH_PASSWORD` | Partner service simulator basic auth password | yes | None | k8s-secret (`simulator`) |
| `NODE_ENV` | Node.js environment mode (`development`, `test`, `production`) | yes | `development` (local) | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `cancellation_tab` | Enables the cancellations tab in the simulator UI | `true` (base) | global |
| `customer_cancellation` | Enables customer self-cancellation UI | `true` (base) | global |
| `customer_service_cancellation` | Enables customer service cancellation UI | `false` (base) | global |
| `merchant_cancellation` | Enables merchant-initiated cancellation UI | `true` (base) | global |
| `bypassMerchantAuth` | Bypasses merchant authentication (enabled in production for partner OAuth flow) | `false` (base) | per-environment |

> Source: `config/base.cson` (base flags), `config/stage/production.cson` (`bypassMerchantAuth: true`)

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base configuration for all environments: CDN asset hosts, feature flags, partner service basic auth (staging), redirect routes, service client URLs, steno transport |
| `config/node-env/development.cson` | CSON | Development-specific overrides |
| `config/node-env/production.cson` | CSON | Production-specific overrides (log tracky to file) |
| `config/node-env/test.cson` | CSON | Test environment overrides |
| `config/stage/production.cson` | CSON | Production stage overrides: CDN hosts, `bypassMerchantAuth`, Groupon login URL, base URL |
| `config/stage/uat.cson` | CSON | UAT stage overrides |
| `.deploy-configs/staging-us-central1.yml` | YAML | Kubernetes deploy config for staging US Central 1 (GCP) |
| `.deploy-configs/staging-europe-west1.yml` | YAML | Kubernetes deploy config for staging Europe West 1 (GCP) |
| `.deploy-configs/staging-us-west-2.yml` | YAML | Kubernetes deploy config for staging US West 2 (AWS) |
| `.deploy-configs/production-us-central1.yml` | YAML | Kubernetes deploy config for production US Central 1 (GCP) |
| `.deploy-configs/production-eu-west-1.yml` | YAML | Kubernetes deploy config for production EU West 1 (AWS) |
| `.deploy-configs/values.yaml` | YAML | Shared Helm chart values (logging, resource limits) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `simulator.username` (env: `PS_AUTH_USERNAME`) | Partner service simulator basic auth username | k8s-secret (name: `simulator`) |
| `simulator.password` (env: `PS_AUTH_PASSWORD`) | Partner service simulator basic auth password | k8s-secret (name: `simulator`) |

> Secret values are NEVER documented. Only names and rotation policies are listed above.

## Per-Environment Overrides

- **Development**: `KELDOR_CONFIG_SOURCE` not set; uses local config. Steno transport is `file`. Ghost CMS `baseUrl` is `null`. Partner service auth uses staging credentials from env vars.
- **Staging**: `KELDOR_CONFIG_SOURCE={staging}`. CDN assets served from `staging<1,2>.grouponcdn.com`. Partner service basic auth uses staging credentials. Groupon login redirect targets `staging.groupon.com`. `bypassMerchantAuth` is `false`.
- **Production**: `KELDOR_CONFIG_SOURCE={production}`. CDN assets served from `www<1,2>.grouponcdn.com`. Partner service basic auth credentials are empty (OAuth takes over). Groupon login redirect targets `groupon.com`. `bypassMerchantAuth` is `true` (OAuth cookie-based auth used instead).
- **All environments**: `PORT=8000`, `NODE_OPTIONS=--max-old-space-size=1024`, `UV_THREADPOOL_SIZE=75`.
