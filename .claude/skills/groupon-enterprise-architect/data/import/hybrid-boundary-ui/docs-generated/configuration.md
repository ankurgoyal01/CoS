---
service: "hybrid-boundary-ui"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

Hybrid Boundary UI is an Angular SPA. Runtime configuration for a browser-delivered Angular application is typically baked into the build output as environment-specific `environment.ts` files or injected via a server-side configuration endpoint. Nginx serves the compiled assets and may be configured via its own configuration file. Specific variable names are not visible in the architecture DSL.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `HYBRID_BOUNDARY_API_BASE_URL` | Base URL for the Hybrid Boundary API (`/release/v1`) | yes | none | env / build config |
| `PAR_API_BASE_URL` | Base URL for the PAR Automation API (`/release/par`) | yes | none | env / build config |
| `OKTA_ISSUER` | Groupon Okta OIDC issuer URL for `angular-oauth2-oidc` | yes | none | env / build config |
| `OKTA_CLIENT_ID` | OAuth2 client ID for Groupon Okta | yes | none | env / build config |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed. Variable names above are inferred from the technology stack (Angular + angular-oauth2-oidc + external APIs). Confirm exact names against the Angular environment files in the service source.

## Feature Flags

> No evidence found of feature flags in the architecture inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/environments/environment.ts` | TypeScript | Development-time environment configuration (API URLs, Okta settings) |
| `src/environments/environment.prod.ts` | TypeScript | Production build environment configuration |
| `nginx.conf` | Nginx config | Static asset serving, SPA fallback routing (`try_files`) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `OKTA_CLIENT_ID` | OAuth2 client identifier for Groupon Okta OIDC | env / build config |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Angular environment files (`environment.ts` vs `environment.prod.ts`) provide build-time separation between development and production. Production API base URLs and Okta issuer details differ from development values. The Angular CLI `--configuration production` flag selects the appropriate environment file at build time.
