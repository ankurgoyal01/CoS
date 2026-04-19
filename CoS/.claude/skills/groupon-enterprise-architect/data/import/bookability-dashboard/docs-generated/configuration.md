---
service: "bookability-dashboard"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-config-js, vite-env-vars]
---

# Configuration

## Overview

The Bookability Dashboard uses a two-tier configuration strategy. Build-time configuration is provided via Vite environment variables (`VITE_APP_ENV`). Runtime configuration is injected by the deployment pipeline as `window._env_` via a `env-config.js` file that is loaded in `index.html` before the React application boots. Environment-specific `env-config.js` files are stored under `.meta/deployment/cloud/components/app/` and copied into the build artifact during deployment.

## Environment Variables

### Runtime (injected via `window._env_` in `env-config.js`)

| Variable | Purpose | Required | Default (development) | Source |
|----------|---------|----------|-----------------------|--------|
| `NAME` | Environment name (`development`, `staging`, `production`). Used to determine if the app should render or show a black screen when `DOORMAN_URL` is absent. | yes | `development` | `.meta/deployment/cloud/components/app/{env}.js` |
| `BASE_PATH` | Base URL path prefix for the SPA (e.g., `/bookability/dashboard/`) | yes | `/bookability/dashboard/` | `.meta/deployment/cloud/components/app/{env}.js` |
| `STATIC_PATH` | Static asset base path | yes | `/bookability/dashboard` | `.meta/deployment/cloud/components/app/{env}.js` |
| `API_URL` | Base URL for all Partner Service API calls. Prefixed to all backend requests. | yes | `/bookability/dashboard/api` | `.meta/deployment/cloud/components/app/{env}.js` |
| `DOORMAN_URL` | URL of the Doorman (internal auth) service. When present, enables the authentication flow. When absent in a protected environment, the app renders a black screen. | yes (staging/prod) | `https://doorman-staging-na.groupondev.com` | `.meta/deployment/cloud/components/app/{env}.js` |
| `UMAPI_URL` | Base URL for UMAPI requests | yes | `/bookability/dashboard/api` | `.meta/deployment/cloud/components/app/{env}.js` |
| `MC_UMAPI_URL` | Base URL for Merchant Center UMAPI requests | yes | `/merchant/admin/api` | `.meta/deployment/cloud/components/app/{env}.js` |
| `PARTNER_SERVICE_URL` | Explicit Partner Service base URL. Falls back to `API_URL + /partner-service` if not set. | no | Derived from `API_URL` | `src/config/api.ts` |

### Build-time (Vite env vars — local development only)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `VITE_APP_ENV` | Selects which proxy target to use in local dev (`staging`, `production`). Unset = local partner-service on `localhost:9000`. | no | unset (local) | Shell / `.env` file |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No feature flag system is implemented in this service. Partner discovery is entirely dynamic (driven by `GET /v1/partner_configurations?monitoring=true` at runtime) and does not require flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/staging-us-central1.js` | JavaScript (`window._env_` assignment) | Runtime config injected for staging US region |
| `.meta/deployment/cloud/components/app/staging-europe-west1.js` | JavaScript (`window._env_` assignment) | Runtime config injected for staging EU region |
| `.meta/deployment/cloud/components/app/production-us-central1.js` | JavaScript (`window._env_` assignment) | Runtime config injected for production US region |
| `.meta/deployment/cloud/components/app/production-europe-west1.js` | JavaScript (`window._env_` assignment) | Runtime config injected for production EU region |
| `public/env-config.js` | JavaScript (`window._env_` assignment) | Default development config (served by Vite dev server) |
| `src/config/api.ts` | TypeScript | Reads `window._env_` at startup and constructs `apiConfig.partner.baseUrl` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.secrets/dev/servicekey.json` | GCP service account key for CI/CD authentication (used by Jenkins build to upload artifacts to GCS) | Jenkins credential store / file secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Environment | `NAME` | `DOORMAN_URL` | GCP Project |
|-------------|--------|---------------|-------------|
| Development (local) | `development` | `https://doorman-staging-na.groupondev.com` | — |
| Staging (US / EU) | `staging` | `https://doorman-staging-na.groupondev.com` | `prj-grp-book-dash-stable-2265` |
| Production (US / EU) | `production` | `https://doorman-na.groupondev.com` | `prj-grp-book-dash-prod-a776` |

In staging and production, if `DOORMAN_URL` is missing and `NAME` is not `development`, the application renders a black screen as a protection mechanism (`src/App.tsx`). All other `window._env_` values are identical across environments except for `NAME` and `DOORMAN_URL`.
