---
service: "next-pwa-app"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "keldor-config"]
---

# Configuration

## Overview

next-pwa-app uses a layered configuration approach. Runtime environment variables are managed through JSON config files in `apps/next-pwa/env-variables/` (merged base -> staging/production -> local). The `keldor-config` library (Groupon's ITier config system) provides runtime-resolved configuration for service discovery and environment-specific settings. Feature flags are managed via GrowthBook and the `itier-feature-flags` library.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment mode | yes | -- | env |
| `KELDOR_CONFIG_SOURCE` | Selects config environment (`{production}`, `{staging}`) | yes | -- | env |
| `PORT` | HTTP listening port | no | 8000 | env |
| `WATT_WORKERS` | Number of wattpm worker processes | no | 1 | env |
| `FULL_SHA` | Git commit SHA for version tracking | yes (build) | -- | Docker build-arg |
| `IAM_METADATA` | IAM metadata for authenticated API calls | yes (runtime) | -- | Docker build-arg / env |
| `REDIS_CONNECTION_URL` | Redis cache connection string | no | (empty -- falls back to in-memory) | env |
| `ELASTIC_APM_SERVER_URL` | Elastic APM collector URL | no | (per env config) | config-file |
| `ELASTIC_APM_ENVIRONMENT` | APM environment label | no | us-central1 | config-file |
| `NEXT_PUBLIC_SKIP_SENTRY` | Disable Sentry instrumentation | no | false | env |
| `NEXT_PUBLIC_SKIP_SENTRY_CLOUD` | Disable sending events to Sentry cloud | no | false | env |
| `NEXT_PUBLIC_SPOTLIGHT` | Enable Sentry Spotlight (dev only) | no | false | env |
| `NEXT_PUBLIC_DISABLE_LOGS_API` | Disable client log API | no | false | env |
| `NEXT_PUBLIC_DISABLE_PARTYTOWN` | Disable Partytown script offloading | no | false | env |
| `NEXT_USE_WEBPACK` | Force Webpack bundler instead of Turbopack | no | false | env |
| `BUILD_STANDALONE` | Enable standalone output mode | no | false | env |
| `LOCAL_BUILD` | Flag for local development builds | no | false | env |
| `CI_BUILD_LOCALES` | Comma-separated locale subset for CI builds | no | (all locales) | env |
| `ANALYZE` | Enable Statoscope analysis | no | false | env |
| `ANALYZE_BUNDLES` | Enable Webpack Bundle Analyzer | no | false | env |
| `MBNXT_JS_RUNTIME` | Target JS runtime (node/edge/browser) -- set via DefinePlugin | no | -- | auto (build) |
| `MBNXT_BUILD_TYPE` | Build type (development/production) -- set via compiler.define | no | -- | auto (build) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| GrowthBook experiments | A/B testing and feature rollouts across all user-facing features | per-experiment | per-user / per-session |
| `itier-feature-flags` | ITier-level feature flags for service capabilities | per-flag | per-service |
| `optimize-itier-bindings` | Optimize ITier client bindings | -- | global |

Feature flags are evaluated via the `libs/api/growthbook/` library, which wraps the GrowthBook SDK. Experiments are mapped to user attributes and evaluated server-side during SSR and in GraphQL resolvers.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `apps/next-pwa/env-variables/base.json` | JSON | Base environment variables (shared across all environments) |
| `apps/next-pwa/env-variables/staging.json` | JSON | Staging-specific overrides (APM URL, Redis) |
| `apps/next-pwa/env-variables/production.json` | JSON | Production-specific overrides (APM URL, Redis) |
| `apps/next-pwa/env-variables/local.json` | JSON | Local development overrides (gitignored) |
| `apps/next-pwa/watt.json` | JSON | Wattpm process manager configuration (port, workers, logging, metrics) |
| `apps/next-pwa/next.config.ts` | TypeScript | Next.js configuration (composed from base + sentry + itier) |
| `apps/next-pwa/config/` | CSON/JSON | Legacy ITier config files (base, local_e2e, node-env, stage) |
| `nx.json` | JSON | Nx workspace configuration |
| `biome.json` | JSON | Biome formatter configuration |
| `graphql.config.yaml` | YAML | GraphQL schema discovery configuration |
| `knip.jsonc` | JSONC | Unused dependency detection configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `IAM_METADATA` | Service authentication credentials for ITier APIs | Docker build-arg (injected by Napistrano/Conveyor CI) |
| Sentry DSN | Error tracking endpoint identifier | Hardcoded in source (public DSN -- not a secret) |
| GrowthBook API key | Feature flag service access | keldor-config / env |
| MapTiler API key | Map tile service access | keldor-config / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `KELDOR_CONFIG_SOURCE` not set, `NODE_ENV=development`. Uses local defaults, Sentry can be enabled via Spotlight, Turbopack for fast dev builds, filesystem-based webpack cache.
- **Staging**: `KELDOR_CONFIG_SOURCE='{staging}'`, `NODE_ENV=production`. APM pointed to stable APM cluster. Redis URL may be empty (falling back to in-memory cache). Deployed automatically on PR merge to main.
- **Production**: `KELDOR_CONFIG_SOURCE='{production}'`, `NODE_ENV=production`. APM pointed to production APM cluster. Full locale set built. MaxMind GeoIP database included.
