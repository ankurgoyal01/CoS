---
service: "merchant-booking-tool"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

The Merchant Booking Tool follows standard I-tier configuration conventions for Node.js applications within the Continuum Platform. Configuration is injected via environment variables at runtime. No specific configuration files, Consul entries, or Vault paths are directly visible in the architecture DSL. The service requires configuration for connecting to the Universal Merchant API booking service, the Layout Service, and the external OAuth/Inbenta integrations.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `MERCHANT_API_BASE_URL` | Base URL for the Universal Merchant API (booking service) used by `mbtMerchantApiClient` and `mbtProxyController` | yes | — | env |
| `LAYOUT_SERVICE_URL` | URL of the `continuumLayoutService` for merchant shell rendering | yes | — | env |
| `GOOGLE_OAUTH_CLIENT_ID` | Client ID for Google OAuth 2.0 calendar sync authentication | yes | — | env / vault |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Client secret for Google OAuth 2.0 calendar sync authentication | yes | — | env / vault |
| `INBENTA_API_KEY` | API key for Inbenta support client authentication token requests | yes | — | env / vault |
| `NODE_ENV` | Runtime environment designation (development, staging, production) | yes | — | env |

> IMPORTANT: Actual secret values are never documented. Only variable names and purposes are listed. The above variable names are inferred from the architecture DSL integration descriptions; confirm exact names against the service repository configuration.

## Feature Flags

> No evidence found in codebase. No feature flags are visible in the architecture DSL for this service.

## Config Files

> No evidence found in codebase. Configuration files are not visible in the architecture DSL. I-tier applications typically use environment-injected configuration rather than checked-in config files.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Google OAuth client secret | Enables OAuth 2.0 authorization code flow for Google Calendar sync | vault / env |
| Inbenta API key | Authenticates `mbtInbentaClient` token requests to Inbenta support API | vault / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The service operates across development, staging, and production environments following standard Continuum I-tier deployment conventions. The `NODE_ENV` variable controls environment-specific behavior. The `MERCHANT_API_BASE_URL` and `LAYOUT_SERVICE_URL` values differ per environment to point to the appropriate Continuum service endpoints. OAuth and Inbenta credentials are environment-scoped.
