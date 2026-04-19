---
service: "goods-vendor-portal"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

The Goods Vendor Portal is configured through a combination of build-time environment variables (injected during the `ember build` Docker stage) and runtime Nginx configuration. Feature flags are loaded at runtime from GPAPI via the `/goods-gateway/features` endpoint and managed with `ember-feature-flags`. Secrets such as API credentials are not held by the portal — they are managed by GPAPI on the backend.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `GPAPI_BASE_URL` | Base URL for the GPAPI backend that Nginx proxies requests to | yes | None | env / helm |
| `NODE_ENV` | Controls build optimizations (`development`, `production`) | yes | `production` | env |
| `EMBER_ENV` | Ember build environment profile (`development`, `staging`, `production`) | yes | `production` | env |
| `AUTH_CALLBACK_URL` | OAuth2 callback URL used by `ember-simple-auth` | yes | None | env / helm |
| `APP_BASE_URL` | Public-facing base URL for the portal, used in redirect and link generation | yes | None | env / helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

Feature flags are managed via `ember-feature-flags` 2.0.1. Flag states are fetched from GPAPI at session initialization via `GET /goods-gateway/features` and applied client-side to show or hide portal capabilities.

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Feature flags are loaded dynamically from GPAPI | Flag names and states are vendor/environment-specific and owned by the GPAPI configuration service | — | per-tenant |

> Specific flag names are defined in the GPAPI configuration service. Consult the GPAPI team for the current flag catalog.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `ember-cli-build.js` | JavaScript | Ember CLI build pipeline configuration — asset fingerprinting, tree shaking, environment-specific options |
| `config/environment.js` | JavaScript | Ember environment configuration — API host, feature flag adapter setup, auth configuration per environment |
| `nginx.conf` | Nginx config | Nginx reverse proxy rules — upstream GPAPI URL, `/goods-gateway/*` proxy pass, static asset serving, gzip |
| `Dockerfile` | Dockerfile | Multi-stage build: Node.js 14.21 for `ember build`, Nginx for runtime serving |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GPAPI_AUTH_SECRET` | Shared secret or token used by the Nginx proxy to authenticate inter-service calls to GPAPI | k8s-secret / vault |
| `SESSION_SECRET` | Secret key used by the session management layer | k8s-secret / vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `EMBER_ENV=development` enables the Ember Inspector, live reload, and verbose logging. GPAPI_BASE_URL points to a local or dev-tier GPAPI instance.
- **Staging**: `EMBER_ENV=staging` uses staging GPAPI endpoints. Feature flags may differ from production to enable pre-release capabilities.
- **Production**: `EMBER_ENV=production` enables minification, fingerprinting, and source map upload. All URLs point to production GPAPI. SOX compliance controls are enforced at this tier.
