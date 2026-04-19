---
service: "deal"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, helm-values]
---

# Configuration

## Overview

The deal service is configured via environment variables injected at runtime, consistent with the I-Tier / Kubernetes deployment model used across Continuum services. Feature flags are evaluated at request time using `itier-feature-flags 2.2.2`. Webpack build configuration controls the static asset bundle.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment mode (development, production) | yes | `production` | env |
| `PORT` | HTTP port the Express server listens on | yes | `3000` | env |
| `GROUPON_V2_CLIENT_BASE_URL` | Base URL for Groupon V2 API calls | yes | None | env / helm |
| `GRAPHQL_API_URL` | Base URL for GraphQL API calls | yes | None | env / helm |
| `EXPERIMENTATION_SERVICE_URL` | Base URL for A/B test variant assignment service | yes | None | env / helm |
| `ONLINE_BOOKING_SERVICE_URL` | Base URL for the Online Booking Service (appointment availability) | yes | None | env / helm |
| `MAPPROXY_URL` | Base URL for MapProxy/Mapbox map tile proxy | no | None | env / helm |
| `LOG_LEVEL` | Log verbosity level | no | `info` | env |
| `ITIER_APP_NAME` | I-Tier application identifier used in instrumentation | yes | `deal` | env / helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| > No evidence found in codebase for specific flag names. Feature flags are evaluated via `itier-feature-flags 2.2.2` | Controls experiment-gated UI features and A/B test variants on the deal page | > No evidence found | per-tenant / per-region |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `webpack.config.js` | JavaScript | Webpack 4 build configuration for deal page static assets |
| `package.json` | JSON | Node.js dependency manifest and npm script definitions |
| `.nvmrc` | text | Pins Node.js version to 16.16.0 for local development |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GROUPON_V2_CLIENT_API_KEY` | API key for authenticating requests to Groupon V2 APIs | k8s-secret / vault |
| `GRAPHQL_API_AUTH_TOKEN` | Auth token for GraphQL API access | k8s-secret / vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `NODE_ENV=development`; Webpack runs in development mode with source maps; API base URLs point to local or staging backends.
- **Staging**: Helm values target staging API endpoints; replica counts reduced relative to production.
- **Production**: Helm values target production API endpoints; auto-scaling active (us-central1: 12–150 replicas, eu-west-1: 8–50 replicas); `NODE_ENV=production`.
