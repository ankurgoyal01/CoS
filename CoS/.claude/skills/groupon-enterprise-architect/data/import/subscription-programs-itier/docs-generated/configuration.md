---
service: "subscription-programs-itier"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

subscription-programs-itier follows the I-Tier configuration pattern: the service reads environment variables at startup for runtime settings (ports, upstream service URLs, Memcached addresses) and loads static config files for division definitions. Feature flags are evaluated at runtime via Birdcage.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment designation (development, staging, production) | yes | — | env |
| `PORT` | HTTP port the Express server listens on | yes | 3000 | env |
| `MEMCACHED_HOSTS` | Comma-separated Memcached host:port endpoints for membership/flag caching | yes | — | env |
| `SUBSCRIPTIONS_API_URL` | Base URL for Groupon Subscriptions API | yes | — | env |
| `GROUPON_V2_API_URL` | Base URL for Groupon V2 API (Select Membership) | yes | — | env |
| `BIRDCAGE_URL` | Base URL for Birdcage feature flag service | yes | — | env |
| `GEO_DETAILS_URL` | Base URL for GeoDetails API | yes | — | env |
| `TRACKING_HUB_URL` | Base URL for Tracking Hub event endpoint | yes | — | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Birdcage-managed flags | Control which Select purchase variant page is shown (`purchg1`, `purchgg`, `purchge`); enable/disable enrollment flow features; manage A/B test assignments | Defined in Birdcage | per-tenant / per-region |

> Specific flag names are managed in Birdcage and are not enumerated in the service inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/divisions.json` | JSON | Division/locale definitions loaded by `itier-divisions` at startup |

> Exact config file paths are conventional for I-Tier services; confirm against the service repository.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SUBSCRIPTIONS_API_KEY` | Service credentials for Groupon Subscriptions API | env / secrets manager |
| `GROUPON_V2_API_KEY` | API credentials for Groupon V2 API (Select Membership) | env / secrets manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `NODE_ENV=development`; local Memcached instance; upstream service URLs point to development stubs or staging environments
- **Staging**: `NODE_ENV=staging`; shared staging Memcached; upstream URLs point to staging Subscriptions API and V2 API instances
- **Production**: `NODE_ENV=production`; production Memcached; all upstream URLs point to production service instances
