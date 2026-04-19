---
service: "coupons-itier-global"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

`coupons-itier-global` follows the I-Tier platform configuration pattern, using environment variables for runtime secrets and connection strings, and configuration files for feature flags and service settings. The `itier-feature-flags` library (v3.3.0) provides feature flag evaluation at runtime. Specific variable names are not captured in the architecture model; the entries below reflect what can be inferred from the service's dependencies and integration points.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `REDIS_URL` | Connection string for `continuumCouponsRedisCache` | yes | None | env |
| `VOUCHERCLOUD_API_URL` | Base URL for Vouchercloud API requests | yes | None | env |
| `VOUCHERCLOUD_API_KEY` | Authentication credential for Vouchercloud API | yes | None | vault |
| `GAPI_URL` | Base URL for GAPI (GraphQL) requests | yes | None | env |
| `GAPI_API_KEY` | Authentication credential for GAPI | yes | None | vault |
| `NODE_ENV` | Runtime environment (`development`, `staging`, `production`) | yes | `development` | env |
| `PORT` | HTTP port the I-Tier server listens on | no | `3000` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Feature flags are managed via `itier-feature-flags` v3.3.0 | Enables runtime toggling of service behaviour across environments | — | — |

> Specific flag names are not captured in the architecture model. Flags are evaluated by the `itierServer` component at request time.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | JSON | Dependency manifest, engine constraints (Node.js 14.19.3), npm scripts |
| Webpack config | JavaScript | Build configuration for Preact UI assets via Webpack 5.73.0 |
| I-Tier server config | JavaScript/JSON | I-Tier routing, middleware, and SSR configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Vouchercloud API key | Authenticates requests to Vouchercloud API | vault |
| GAPI API key | Authenticates requests to GAPI (GraphQL) | vault |
| Redis connection credentials | Authenticates and authorises Redis connections | vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `NODE_ENV=development`; local Redis and stubbed upstream APIs may be used; `/graphiql` endpoint enabled
- **Staging**: `NODE_ENV=staging`; connected to staging Vouchercloud and GAPI instances; Akamai CDN not active
- **Production**: `NODE_ENV=production`; full Akamai CDN in front; all secrets sourced from vault; 11-country locale routing active

> Detailed per-environment configuration is managed externally to this repository.
