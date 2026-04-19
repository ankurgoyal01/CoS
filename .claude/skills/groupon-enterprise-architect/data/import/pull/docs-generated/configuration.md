---
service: "pull"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, feature-flags]
---

# Configuration

## Overview

Pull is configured primarily via environment variables injected at runtime into the Node.js process, following standard I-Tier platform conventions. Feature flag and experiment configuration is resolved dynamically at request time from Birdcage via `itier-feature-flags`. No evidence of Consul, Vault, or Helm-specific config files was found in the service DSL inventory.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment mode (development, production) | yes | — | env |
| `PORT` | HTTP server listen port for the I-Tier application | yes | — | env |
| `API_PROXY_URL` | Base URL for the internal API Proxy gateway | yes | — | env |
| `BIRDCAGE_URL` | Base URL for the Birdcage feature flag service | yes | — | env |
| `GEOPLACES_URL` | Base URL for the GeoPlaces geographic resolution service | yes | — | env |
| `LAYOUT_SERVICE_URL` | Base URL for the Layout Service | yes | — | env |
| `RELEVANCE_API_URL` | Base URL for the Relevance API | yes | — | env |
| `LPAPI_URL` | Base URL for the LPAPI landing page service | yes | — | env |
| `UGC_URL` | Base URL for the UGC ratings and reviews service | yes | — | env |
| `WISHLIST_URL` | Base URL for the Wishlist service | yes | — | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here. Actual values are managed by the platform deployment pipeline.

> Note: Specific environment variable names above are inferred from the service integration inventory and I-Tier platform conventions. Confirm exact names against the service's deployment manifests.

## Feature Flags

Feature flags are resolved dynamically per-request via `itier-feature-flags 3.2.0` by the `pullFeatureFlagClient` component, which calls `continuumBirdcageService` at request time.

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| (experiment flags) | Control rendering variants, UI branches, and feature availability for Homepage, Browse, Search, Local, Goods, and Gifting pages | fail-open to baseline | per-request |

> Specific flag names are managed in Birdcage and are not enumerated in the service DSL inventory. See the Birdcage service documentation for the full flag catalog applicable to Pull.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `webpack.config.js` | JavaScript | Webpack 5 build configuration for server and client asset bundling |

> Additional config files (e.g., TypeScript config, ESLint, itier-server config) are standard I-Tier project files and are not architecture-relevant.

## Secrets

> No evidence found of secrets managed directly by Pull. API authentication to internal services (API Proxy, Birdcage, etc.) is handled via platform-level service identity or network policy rather than application-level secrets.

## Per-Environment Overrides

Environment-specific configuration (service URLs, logging levels, feature flag defaults) is injected via environment variables by the I-Tier deployment platform. Development environments typically point to local or staging instances of upstream services. Production environments use production endpoints for all dependencies.
