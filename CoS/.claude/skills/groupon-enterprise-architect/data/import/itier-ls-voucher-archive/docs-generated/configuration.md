---
service: "itier-ls-voucher-archive"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, itier-server-config]
---

# Configuration

## Overview

itier-ls-voucher-archive is configured through environment variables injected at deploy time, consistent with the Groupon interaction tier standard. The `itier-server` framework reads environment-based configuration for port, environment tier, downstream service URLs, and Memcached connection details. Feature flags are evaluated at request time via `itier-feature-flags`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Node.js environment mode (production, development) | yes | none | env |
| `PORT` | HTTP listen port for the Express server | yes | none | env |
| `MEMCACHED_HOSTS` | Comma-separated Memcached host:port list for `continuumLsVoucherArchiveMemcache` | yes | none | env |
| `VOUCHER_ARCHIVE_API_URL` | Base URL for the Voucher Archive Backend service | yes | none | env |
| `LAZLO_API_URL` | Base URL for the Groupon v2 API (Lazlo / `continuumApiLazloService`) | yes | none | env |
| `UNIVERSAL_MERCHANT_API_URL` | Base URL for the Universal Merchant API (`continuumUniversalMerchantApi`) | yes | none | env |
| `BHUVAN_API_URL` | Base URL for the Bhuvan geo service (`continuumBhuvanService`) | yes | none | env |
| `API_PROXY_URL` | Base URL for the internal API Proxy | yes | none | env |
| `SUBSCRIPTIONS_API_URL` | Base URL for the Subscriptions API | yes | none | env |
| `GRAPHQL_GATEWAY_URL` | Base URL for the GraphQL Gateway | yes | none | env |
| `SESSION_SECRET` | Secret key for session cookie signing (itier-user-auth) | yes | none | env |
| `CSRF_SECRET` | Secret for CSRF token generation (csurf) | yes | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Feature flags evaluated via `itier-feature-flags` 1.5.0 | Control feature availability per request context | varies | per-tenant / per-region |

> Specific flag names are managed by the `itier-feature-flags` service and are not statically defined in this repository. Flag evaluation occurs at request time.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | JSON | Node.js package manifest, dependency versions, npm scripts |
| `webpack.config.js` | JavaScript | Client-side asset bundling configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SESSION_SECRET` | Signing key for user session cookies | env (injected at deploy) |
| `CSRF_SECRET` | Secret for CSRF token generation and validation | env (injected at deploy) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Service URLs (`VOUCHER_ARCHIVE_API_URL`, `LAZLO_API_URL`, etc.) and Memcached hosts differ between development, staging, and production environments. All overrides are applied via environment variable injection at deploy time. There are no environment-specific config files bundled with the application.
