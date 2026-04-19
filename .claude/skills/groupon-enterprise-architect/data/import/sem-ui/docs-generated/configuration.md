---
service: "sem-ui"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

SEM Admin UI follows the standard I-Tier configuration pattern: environment variables injected at container startup control service identity, upstream endpoints, and auth settings. No external config store (Consul, Vault) is directly evidenced in the inventory.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment designation (development, staging, production) | yes | none | env |
| `PORT` | HTTP port the I-Tier server listens on | yes | none | env |
| `SEM_KEYWORDS_SERVICE_URL` | Base URL for the SEM Keywords Service proxy target | yes | none | env |
| `SEM_BLACKLIST_SERVICE_URL` | Base URL for the SEM Blacklist Service proxy target | yes | none | env |
| `GPN_DATA_API_URL` | Base URL for the GPN Data API proxy target | yes | none | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

> No evidence found in codebase for exact variable names. The variables listed above are inferred from the proxy integration patterns described in the inventory. Service owners should verify against the actual `.env` or Helm values files.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | JSON | Node.js dependency manifest and npm scripts |
| `webpack.config.js` | JavaScript | Webpack 5 build configuration for client assets |

## Secrets

> No evidence found in codebase. Authentication credentials for downstream services are managed externally. Secret values are never documented.

## Per-Environment Overrides

> No evidence found in codebase. Environment-specific overrides are expected to follow the standard I-Tier pattern of environment variable injection per deployment target (development, staging, production).
