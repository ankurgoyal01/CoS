---
service: "control-center-ui"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Control Center UI is an Ember CLI application. Configuration is provided at build time via Ember's environment configuration system (`config/environment.js`) and at runtime via Nginx proxy configuration. Backend proxy paths (`/__/proxies/dpcc-service/v1.0/sales`, `/__/proxies/pccjt-service`) are configured in the Nginx reverse proxy layer. AWS SDK credentials for S3 uploads are injected as environment variables.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DPCC_SERVICE_URL` | Upstream URL for the DPCC Service; used by Nginx proxy | yes | None | env |
| `PCCJT_SERVICE_URL` | Upstream URL for the Pricing Control Center Jtier Service; used by Nginx proxy | yes | None | env |
| `DOORMAN_SSO_URL` | Doorman SSO authentication endpoint | yes | None | env |
| `AWS_ACCESS_KEY_ID` | AWS credentials for S3 upload (bulk sale uploader) | no | None | env |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials for S3 upload (bulk sale uploader) | no | None | env |
| `AWS_S3_BUCKET` | Target S3 bucket name for bulk sale CSV uploads | no | None | env |
| `AWS_REGION` | AWS region for S3 bucket | no | None | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

> No evidence found in codebase for the exact variable names above; names are inferred from the inventory-listed integrations and standard Ember CLI / Nginx conventions. Confirm actual names against the Nginx configuration and Ember environment config in the repository.

## Feature Flags

> No evidence found in codebase. No feature flag system (GrowthBook, LaunchDarkly, etc.) is identified in the inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/environment.js` | JavaScript | Ember CLI environment configuration: API host, environment mode (development/production), feature toggles |
| `ember-cli-build.js` | JavaScript | Ember CLI build pipeline configuration: fingerprinting, asset pipeline, environment-specific build options |
| `nginx.conf` | Nginx config | Nginx web server configuration: static asset serving, reverse proxy rules for `/__/proxies/*` paths, SSO enforcement |
| `package.json` | JSON | Node.js dependency manifest and npm scripts |
| `.ember-cli` | JSON | Ember CLI options (port, liveReload, proxy) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY | AWS credentials for S3 upload operations | CI/CD secret / environment |
| Doorman SSO client credentials | OAuth2 client authentication with Doorman | CI/CD secret / environment |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Ember CLI uses `config/environment.js` to define per-environment configuration:

- **development**: Ember CLI dev server with live reload; proxy rules in `.ember-cli` forward `/__/proxies/*` to local or staging backends.
- **test**: Ember test environment; Ember CLI QUnit test runner; backends may be mocked.
- **production**: Minified/fingerprinted static build served by Nginx; all proxy paths target production DPCC and PCCJT service endpoints.
