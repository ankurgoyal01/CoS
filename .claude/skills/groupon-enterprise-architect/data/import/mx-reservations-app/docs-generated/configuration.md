---
service: "mx-reservations-app"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, itier-feature-flags]
---

# Configuration

## Overview

MX Reservations App is configured through environment variables injected at container startup and feature flags evaluated at runtime via itier-feature-flags. The itier-server framework enforces standard Groupon configuration conventions. Per-environment overrides are managed through the Kubernetes deployment manifests for snc1 and dub1 environments.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment designation (development, staging, production) | yes | — | env |
| `PORT` | Port on which the Express server listens | yes | — | env |
| `ITIER_DIVISION` | itier division identifier for locale/region resolution | yes | — | env |
| `API_PROXY_BASE_URL` | Base URL for the API Proxy target for `/reservations/api/v2/*` proxying | yes | — | env |
| `AUTH_SECRET` | Secret used by itier-user-auth for session token validation | yes | — | env / k8s-secret |
| `FEATURE_FLAGS_SERVICE_URL` | Endpoint for itier-feature-flags service | yes | — | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are recorded here. Actual values are managed in Kubernetes secrets and are not stored in this repository.

> Note: Specific environment variable names above are inferred from itier-server and itier-user-auth conventions. Verify exact names against the deployment manifests.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Feature flags managed via itier-feature-flags (v1.5.0) | Control progressive rollout of booking, calendar, workshop, and redemption features | — | per-tenant / per-region |

> Specific flag names are not enumerated in the architecture inventory. Flag definitions are managed in the itier-feature-flags configuration service.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | JSON | Node.js dependency manifest and npm scripts |
| `webpack.config.js` | JavaScript | Webpack 4 build configuration for SPA bundle |
| `tsconfig.json` | JSON | TypeScript 3.7.2 compiler options |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `AUTH_SECRET` | itier-user-auth session signing secret | k8s-secret |
| API credentials for downstream services | Authentication tokens for API Proxy calls | k8s-secret |

> Secret values are NEVER documented. Only names and purposes are listed.

## Per-Environment Overrides

- **Development**: Local overrides via `.env` file or environment variables; Memory Server Adapter may be enabled for demo mode, bypassing live API calls
- **Staging**: Deployed to Kubernetes in snc1/dub1 with staging API Proxy endpoint; feature flags configured for partial rollout
- **Production**: Deployed to Kubernetes in snc1 (primary) and dub1 (secondary) data centres; all feature flags at production defaults; secrets injected via Kubernetes secrets
