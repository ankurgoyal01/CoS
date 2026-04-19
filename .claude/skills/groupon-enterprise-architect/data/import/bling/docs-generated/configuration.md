---
service: "bling"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

bling is configured at build time (Ember CLI environment config) and at runtime via Nginx proxy configuration. Build-time configuration controls API endpoint paths, OAuth settings, and feature toggles baked into the compiled SPA bundle. Runtime configuration for the Nginx reverse proxy is provided through environment variables and Nginx config files. There are no server-side environment variables injected into the SPA at request time beyond what Nginx proxying handles.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ACCOUNTING_SERVICE_URL` | Upstream URL for Nginx to proxy `/api/*` requests to Accounting Service | yes | none | env |
| `FILE_SHARING_SERVICE_URL` | Upstream URL for Nginx to proxy `/file-sharing-service/*` requests | yes | none | env |
| `HYBRID_BOUNDARY_URL` | OAuth/Okta proxy endpoint for authentication redirects | yes | none | env |
| `OKTA_CLIENT_ID` | Okta application client ID for OAuth2 flow | yes | none | env |
| `OKTA_ISSUER` | Okta issuer URL for token validation | yes | none | env |
| `NGINX_PORT` | Port on which Nginx listens | no | `80` | env |
| `NODE_ENV` | Node.js environment for Ember CLI build | yes | `development` | env |
| `EMBER_ENV` | Ember CLI environment (development, staging, production) | yes | `development` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. No dedicated feature flag system is identified in the bling inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/environment.js` | JavaScript | Ember CLI environment configuration; sets API base URLs, OAuth settings, and environment-specific options at build time |
| `nginx.conf` | Nginx config | Nginx reverse proxy rules for `/api/*` and `/file-sharing-service/*` paths; static asset serving |
| `package.json` | JSON | npm dependency manifest and Ember CLI scripts |
| `bower.json` | JSON | Bower frontend dependency manifest (Ember.js 0.2.7 ecosystem) |
| `.ember-cli` | JSON | Ember CLI local development options |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `OKTA_CLIENT_ID` | OAuth2 client identifier for Okta authentication | env |
| `OKTA_ISSUER` | Okta issuer URL (may contain tenant-specific path) | env |
| `ACCOUNTING_SERVICE_URL` | Internal service URL (may include auth tokens in some configurations) | env |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

- **Development**: Ember CLI dev server runs with `NODE_ENV=development`; API proxy configured via `http-proxy` (v1.11.1) in the Ember CLI dev server against local or staging Accounting Service URLs; Okta uses a development application client ID
- **Staging**: Compiled SPA deployed to `blingNginx`; Nginx proxies to staging Accounting Service and File Sharing Service URLs; Okta uses staging application credentials
- **Production**: Compiled SPA deployed to `blingNginx`; Nginx proxies to production Accounting Service and File Sharing Service URLs; all OAuth credentials are live production values; `broccoli-asset-rev` fingerprinted assets enable long-duration browser caching
