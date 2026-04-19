---
service: "PizzaNG"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

PizzaNG follows the standard I-Tier configuration pattern: environment variables injected at container startup control service identity, downstream service URLs, and auth settings. The `continuumPizzaNgConfigComponent` serves configuration-backed runtime data (VAS settings, website links) to the UI. No external config store is directly evidenced in the inventory.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment designation (development, staging, production) | yes | none | env |
| `PORT` | HTTP port the I-Tier/Express server listens on | yes | none | env |
| `CAAP_BASE_URL` | Base URL for CAAP service integration | yes | none | env |
| `CYCLOPS_BASE_URL` | Base URL for Cyclops service integration | yes | none | env |
| `CFS_SERVICE_URL` | Base URL for CFS (Content Flagging Service) NLP scoring | yes | none | env |
| `DEAL_CATALOG_URL` | Base URL for Deal Catalog service | yes | none | env |
| `API_PROXY_URL` | Base URL for API Proxy / Lazlo | yes | none | env |
| `ZENDESK_API_URL` | Base URL for Zendesk API | yes | none | env |
| `DOORMAN_URL` | Base URL for Doorman auth endpoint resolution | yes | none | env |
| `INGESTION_SERVICE_URL` | Base URL for Zendesk ticket ingestion service | yes | none | env |
| `MERCHANT_SUCCESS_URL` | Base URL for Merchant Success APIs | yes | none | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

> No evidence found in codebase for exact variable names. Variables listed above are inferred from the integration patterns described in the inventory and DSL. Service owners should verify against the actual `.env` or Helm values files.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | JSON | Node.js dependency manifest and npm scripts |
| `webpack.config.js` | JavaScript | Webpack 4 build configuration for React/Preact client assets |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `ZENDESK_API_TOKEN` | Authenticates calls to Zendesk API | No evidence found in codebase — managed externally |
| `CAAP_AUTH_TOKEN` | Authenticates calls to CAAP | No evidence found in codebase — managed externally |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> No evidence found in codebase. Environment-specific overrides are expected to follow the standard I-Tier pattern of environment variable injection per deployment target (development, staging, production). The `continuumPizzaNgRegionsComponent` resolves per-region locale and domain data at runtime.
