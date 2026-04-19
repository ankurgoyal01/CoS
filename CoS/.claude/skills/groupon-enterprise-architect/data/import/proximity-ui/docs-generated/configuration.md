---
service: "proximity-ui"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Proximity UI is configured through a combination of the `NODE_ENV` environment variable and per-environment JavaScript config files located in `server/config/environment/`. At startup, the server loads `server/config/environment/index.js`, which merges a base config object with the file matching the current `NODE_ENV` value. The only runtime-configurable value is the upstream Hotzone API base URL (`hotzoneApiEndpoint`). The server listen port is configurable via the `PORT` environment variable, defaulting to `3000`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Selects the per-environment config file from `server/config/environment/` | yes | none | env |
| `PORT` | TCP port the Express server listens on | no | `3000` | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `server/config/environment/index.js` | JavaScript (CommonJS) | Base config loader; merges shared defaults with the NODE_ENV-selected file |
| `server/config/environment/development.js` | JavaScript (CommonJS) | Sets `hotzoneApiEndpoint` to `http://localhost:9000/v1/proximity/location/hotzone` |
| `server/config/environment/staging.js` | JavaScript (CommonJS) | Sets `hotzoneApiEndpoint` to `http://ec-proximity-app-staging-vip.snc1/v1/proximity/location/hotzone` |
| `server/config/environment/staging_emea.js` | JavaScript (CommonJS) | Sets `hotzoneApiEndpoint` to `http://proximity-emea-staging-vip.snc1/v1/proximity/location/hotzone` |
| `server/config/environment/production.js` | JavaScript (CommonJS) | Sets `hotzoneApiEndpoint` to `http://ec-proximity-vip.snc1/v1/proximity/location/hotzone` |
| `server/config/environment/production_dub1.js` | JavaScript (CommonJS) | Sets `hotzoneApiEndpoint` to `http://ec-proximity-vip.dub1/v1/proximity/location/hotzone` |
| `server/config/environment/production_sac1.js` | JavaScript (CommonJS) | Sets `hotzoneApiEndpoint` to `http://ec-proximity-vip.sac1/v1/proximity/location/hotzone` |
| `config/index.js` | JavaScript (CommonJS) | Webpack build configuration (asset paths, source maps, gzip options) |
| `.babelrc` | JSON | Babel transpilation presets (es2015, stage-2) |
| `.eslintrc.js` | JavaScript | ESLint rules for source and test files |

## Secrets

> No evidence found in codebase. No secret management system (Vault, AWS Secrets Manager, etc.) is referenced. The `client_id=ec-team` query parameter used for upstream API authentication is hardcoded in the proxy controllers.

## Per-Environment Overrides

The sole per-environment configuration variable is `hotzoneApiEndpoint`, which is set to a different VIP hostname for each deployment target:

| NODE_ENV | hotzoneApiEndpoint |
|----------|--------------------|
| `development` | `http://localhost:9000/v1/proximity/location/hotzone` |
| `staging` | `http://ec-proximity-app-staging-vip.snc1/v1/proximity/location/hotzone` |
| `staging_emea` | `http://proximity-emea-staging-vip.snc1/v1/proximity/location/hotzone` |
| `production` | `http://ec-proximity-vip.snc1/v1/proximity/location/hotzone` |
| `production_dub1` | `http://ec-proximity-vip.dub1/v1/proximity/location/hotzone` |
| `production_sac1` | `http://ec-proximity-vip.sac1/v1/proximity/location/hotzone` |
