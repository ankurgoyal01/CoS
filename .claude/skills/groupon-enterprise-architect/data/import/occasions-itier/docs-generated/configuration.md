---
service: "occasions-itier"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

occasions-itier follows the I-Tier configuration pattern: the service reads environment variables at startup for runtime settings (ports, upstream URLs, Memcached addresses) and loads static config files for division and occasion definitions. Feature flags are resolved at runtime via Birdcage.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment designation (development, staging, production) | yes | — | env |
| `PORT` | HTTP port the Express server listens on | yes | 3000 | env |
| `MEMCACHED_HOSTS` | Comma-separated list of Memcached host:port endpoints for `continuumOccasionsMemcached` | yes | — | env |
| `CAMPAIGN_SERVICE_URL` | Base URL for Campaign Service (ArrowHead) polling endpoint | yes | — | env |
| `GROUPON_V2_API_URL` | Base URL for Groupon V2 API (deal data) | yes | — | env |
| `RAPI_URL` | Base URL for RAPI (Relevance API) recommendations endpoint | yes | — | env |
| `ALLIGATOR_URL` | Base URL for Alligator faceting service | yes | — | env |
| `GEO_DETAILS_URL` | Base URL for GeoDetails API | yes | — | env |
| `BIRDCAGE_URL` | Base URL for Birdcage feature flag service | yes | — | env |
| `CAMPAIGN_POLL_INTERVAL` | Background poll interval in seconds for Campaign Service refresh | no | 1800 | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Birdcage-managed flags | Control A/B tests, feature rollouts, and rendering variations on occasion pages | Defined in Birdcage | per-tenant / per-region |

> Specific flag names are managed in Birdcage and are not enumerated in the service inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/divisions.json` | JSON | Division/locale definitions loaded by `itier-divisions` at startup |
| `config/occasions.json` | JSON | Occasion slug-to-theme mappings and static occasion metadata |

> Exact config file paths are conventional for I-Tier services; confirm against the service repository.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GROUPON_V2_API_KEY` | API credentials for Groupon V2 API access | env / secrets manager |
| `CAMPAIGN_SERVICE_API_KEY` | Service credentials for Campaign Service (ArrowHead) | env / secrets manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `NODE_ENV=development`; local Memcached instance; upstream service URLs point to development stubs or staging environments
- **Staging**: `NODE_ENV=staging`; shared staging Memcached cluster; upstream URLs point to staging service instances
- **Production**: `NODE_ENV=production`; production Memcached cluster (`continuumOccasionsMemcached`); all upstream URLs point to production services; `CAMPAIGN_POLL_INTERVAL` tuned for production load
