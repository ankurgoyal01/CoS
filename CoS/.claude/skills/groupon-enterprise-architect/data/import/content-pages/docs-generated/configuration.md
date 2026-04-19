---
service: "content-pages"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

The service is configured via environment variables injected at runtime, following standard Continuum/iTier deployment conventions. No external config stores (Consul, Vault) or file-based configuration beyond standard iTier defaults were identified in the architecture inventory.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment name (development, staging, production) | yes | — | env |
| `PORT` | HTTP server port for the iTier application | yes | 3000 | env |
| `CONTENT_PAGES_API_URL` | Base URL for the Content Pages GraphQL API | yes | — | env |
| `IMAGE_SERVICE_URL` | Base URL for the Image Service (`continuumImageService`) | yes | — | env |
| `ROCKETMAN_API_URL` | Base URL for the Rocketman Email Service | yes | — | env |
| `MEMCACHED_HOSTS` | Comma-separated list of Memcached host:port endpoints for page caching | no | — | env |
| `CDN_BASE_URL` | Base URL for the Groupon CDN static asset delivery | no | — | env |
| `DEFAULT_LOCALE` | Default locale code for `itier-localization` rendering | no | `en-US` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No specific feature flag names are discoverable from the architecture DSL. Feature flag behavior is managed through standard iTier feature flag conventions. Consult the service repository for the full list of flags.

## Config Files

> No file-based configuration beyond standard iTier/webpack build defaults was identified in the inventory.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Content Pages API credentials | Authenticate requests to the Content Pages GraphQL API | env / k8s-secret |
| Image Service credentials | Authenticate `image-service-client` upload requests | env / k8s-secret |
| Rocketman API credentials | Authenticate `@grpn/rocketman-client` email send requests | env / k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

All environment-specific values (API base URLs, credentials, CDN origin, Memcached hosts) are injected via environment variables. The `NODE_ENV` variable controls environment-specific behavior within the iTier application shell. Webpack build outputs may vary by environment for source maps and asset optimization.
