---
service: "clo-ita"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

`clo-ita` follows the standard itier-server configuration model. Runtime behavior is controlled through environment variables (injected at deployment time) and itier platform configuration files. Feature flags are managed via `itier-feature-flags` 3.1.2, which evaluates flags at request time. Localization is configured via `itier-localization` 10.3.0.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment selector (development, staging, production) | yes | — | env |
| `PORT` | HTTP port the Express server listens on | yes | — | env |
| `CLO_API_BASE_URL` | Base URL for the CLO Backend API via apiProxy | yes | — | env |
| `MARKETING_DEAL_SERVICE_URL` | Base URL for continuumMarketingDealService | yes | — | env |
| `USERS_SERVICE_URL` | Base URL for continuumUsersService | yes | — | env |
| `ORDERS_SERVICE_URL` | Base URL for continuumOrdersService | yes | — | env |
| `GEO_DETAILS_SERVICE_URL` | Base URL for continuumGeoDetailsService | yes | — | env |
| `DEAL_CATALOG_SERVICE_URL` | Base URL for continuumDealCatalogService | yes | — | env |
| `ITIER_FEATURE_FLAGS_*` | Feature flag configuration for itier-feature-flags | no | — | env |
| `REDIS_URL` | Redis connection URL used by itier-cached for response caching | no | — | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

> Note: Exact variable names are not declared in the architecture DSL inventory. The names above reflect the standard itier-server convention for this class of BFF service. Confirm exact names in the service repository.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| CLO feature flags (via itier-feature-flags 3.1.2) | Gate CLO experiences such as bulk claim, SMS consent, tutorial, and consent cards | varies | per-tenant / per-region |

> Specific flag names are not documented in the architecture inventory. See the service repository for the full flag registry.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/` (itier-server convention) | JSON / YAML | Per-environment service configuration for itier runtime |
| `webpack.config.js` | JavaScript | Webpack 4 build configuration for Preact UI bundle |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| CLO API credentials | Authentication to CLO Backend API via apiProxy | Managed externally (vault or k8s-secret) |
| User auth session keys | Session validation for itier-user-auth 8.1.0 | Managed externally |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The itier-server platform supports per-environment config overrides via environment-specific config files (e.g., `config/development.json`, `config/production.json`). Downstream service base URLs, feature flag defaults, and caching TTLs are expected to differ between environments. Specific values are managed outside this architecture inventory.
