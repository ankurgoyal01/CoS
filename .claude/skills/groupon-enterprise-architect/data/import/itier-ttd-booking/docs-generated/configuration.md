---
service: "itier-ttd-booking"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, itier-platform-config]
---

# Configuration

## Overview

`itier-ttd-booking` is configured primarily through environment variables injected at deployment time, following the standard ITier platform configuration pattern. Platform-level configuration (API proxy routing, Memcached endpoints, service discovery) is managed by `itier-server` and `itier-client-platform` conventions. Feature flag evaluation is handled via the Expy/Optimizely SDK.

## Environment Variables

> Specific environment variable names are not evidenced in the architecture model. The following represent standard ITier service configuration categories based on the known tech stack and integrations.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment (development, staging, production) | yes | — | env |
| `PORT` | HTTP port the service listens on | yes | — | env |
| `MEMCACHED_HOSTS` | Memcached endpoint(s) for session caching | yes | — | env |
| `API_PROXY_URL` | Base URL for `apiProxy` service-client gateway | yes | — | env |
| `GLIVE_INVENTORY_SERVICE_URL` | Base URL for `continuumGLiveInventoryService` | yes | — | env |
| `ALLIGATOR_CARDS_SERVICE_URL` | Base URL for Alligator Cards Service | yes | — | env |
| `EXPY_API_KEY` | API key for Expy/Optimizely experimentation SDK | no | — | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| GLive Booking Redesign experiment flags | Controls booking widget UI variant assignment via Expy/Optimizely | control | per-request (user-scoped) |

> Specific flag names are managed in the Expy/Optimizely experiment configuration, not in this repository.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | JSON | Node.js dependency manifest and npm scripts |

> Additional ITier platform config files (e.g., `config/default.json` or `config/{env}.json`) may exist in the service repository but are not evidenced in the architecture module.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Memcached credentials | Authentication for session cache cluster | Platform secrets management |
| API proxy service-client credentials | Service-to-service auth for downstream calls | Platform secrets management |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The service follows the standard Continuum platform pattern: `NODE_ENV` controls which configuration profile is active. API proxy URLs, Memcached endpoints, and service base URLs differ between development, staging, and production environments. Overrides are injected via environment variables at deployment time.
