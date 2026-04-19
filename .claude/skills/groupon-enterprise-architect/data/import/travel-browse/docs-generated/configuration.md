---
service: "travel-browse"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, itier-server]
---

# Configuration

## Overview

travel-browse is configured primarily through environment variables injected at container start-up by the deployment pipeline. Feature flags are evaluated at runtime via the `optimizeService` integration using the itier-server feature flag module. The itier-server framework provides additional configuration for API endpoints, caching, and routing. No evidence of Consul or Vault direct integration is present in the architecture model.

## Environment Variables

> No evidence found for specific environment variable names in the architecture model. The variables below represent the categories expected for a service of this type based on the inventory; exact names should be confirmed with the service owner.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment identifier | yes | None | env |
| `PORT` | HTTP port the Express server listens on | yes | None | env |
| `RAPI_BASE_URL` | Base URL for RAPI deal search API | yes | None | env |
| `LPAPI_BASE_URL` | Base URL for LPAPI Pages landing page API | yes | None | env |
| `GROUPON_V2_API_BASE_URL` | Base URL for Groupon V2 API | yes | None | env |
| `GEODETAILS_API_BASE_URL` | Base URL for Geodetails V2 geo resolution API | yes | None | env |
| `MARIS_API_BASE_URL` | Base URL for Maris hotel availability API | yes | None | env |
| `GETAWAYS_API_BASE_URL` | Base URL for Getaways inventory API (`continuumGetawaysApi`) | yes | None | env |
| `MAP_PROXY_BASE_URL` | Base URL for Map Proxy service (`continuumMapProxyService`) | yes | None | env |
| `MEMCACHE_HOSTS` | Comma-separated list of Memcache node hostnames | yes | None | env |
| `OPTIMIZE_BASE_URL` | Base URL for Optimize experiment and flag evaluation service | yes | None | env |
| `USER_AUTH_BASE_URL` | Base URL for User Auth session resolution service | yes | None | env |
| `SUBSCRIPTIONS_API_BASE_URL` | Base URL for Subscriptions API | no | None | env |
| `REMOTE_LAYOUT_BASE_URL` | Base URL for Remote Layout shared header/footer service | yes | None | env |
| `CDN_BASE_URL` | Base URL for Groupon CDN static assets | yes | None | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Flags managed via itier-server feature flag integration | Feature flag names and values are evaluated at runtime from `optimizeService` | Off | per-region / per-tenant |

> Specific flag names are not statically defined in the architecture model. See `optimizeService` for the flag registry.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| itier-server configuration | JSON / properties | itier-server routing, API endpoint config, caching policy |
| `package.json` | JSON | npm dependency manifest and npm scripts |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| API service credentials | Authentication tokens for internal Continuum API calls | > No evidence found — managed by deployment infrastructure |
| Session signing secret | Signs user session cookies | > No evidence found — managed by deployment infrastructure |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: All API base URLs point to staging or mock endpoints; Memcache may be replaced with in-memory mock.
- **Staging**: Full integration with staging instances of all downstream APIs; Memcache cluster provisioned.
- **Production**: All env vars point to production API endpoints; CDN caching headers enabled.
