---
service: "deal_wizard"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Deal Wizard is configured primarily via environment variables for secrets and runtime endpoints, supplemented by Rails environment-specific config files (`config/environments/`). Salesforce credentials, database connection parameters, and Redis connection details are injected via environment variables. Feature flags for locale gating are stored in Redis and read by the `redisCache` component.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL connection string for ActiveRecord | yes | none | env |
| `REDIS_URL` | Redis connection URL for session cache and feature flags | yes | none | env |
| `SALESFORCE_CLIENT_ID` | OAuth 2.0 client ID for Salesforce omniauth provider | yes | none | env |
| `SALESFORCE_CLIENT_SECRET` | OAuth 2.0 client secret for Salesforce omniauth provider | yes | none | env |
| `SALESFORCE_HOST` | Salesforce instance hostname (e.g., login.salesforce.com or custom domain) | yes | none | env |
| `NEW_RELIC_LICENSE_KEY` | New Relic APM agent license key | yes | none | env |
| `NEW_RELIC_APP_NAME` | New Relic application name for telemetry grouping | no | deal_wizard | env |
| `SECRET_KEY_BASE` | Rails session cookie signing secret | yes | none | env |
| `RAILS_ENV` | Rails environment (development, staging, production) | yes | development | env |
| `UNICORN_WORKERS` | Number of Unicorn worker processes | no | 4 | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Locale flags | Enable or disable specific locale/region combinations in the wizard fine print and pricing steps | off | per-region |

> Feature flag key names are stored in Redis and managed via the `redisCache` component. Specific flag key names are not discoverable from the architecture inventory alone.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | yaml | ActiveRecord database connection configuration per Rails environment |
| `config/newrelic.yml` | yaml | New Relic APM agent configuration (app name, log level, transaction tracing) |
| `config/unicorn.rb` | Ruby | Unicorn web server process configuration (workers, timeouts, socket path) |
| `config/initializers/omniauth.rb` | Ruby | Salesforce OAuth provider registration with omniauth |
| `config/environments/production.rb` | Ruby | Production-specific Rails settings (asset pipeline, log level, caching) |
| `config/environments/staging.rb` | Ruby | Staging-specific overrides |
| `config/environments/development.rb` | Ruby | Development-specific settings (reloading, verbose logging) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SALESFORCE_CLIENT_ID` | Identifies the Deal Wizard OAuth application to Salesforce | env / secrets manager |
| `SALESFORCE_CLIENT_SECRET` | Authenticates the Deal Wizard OAuth application to Salesforce | env / secrets manager |
| `SECRET_KEY_BASE` | Signs and verifies Rails session cookies | env / secrets manager |
| `NEW_RELIC_LICENSE_KEY` | Authorizes APM data transmission to New Relic | env / secrets manager |
| `DATABASE_URL` | Contains MySQL credentials for the application database | env / secrets manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Local MySQL and Redis instances; Salesforce sandbox OAuth credentials; verbose Rails logging; asset pipeline disabled or bypassed
- **Staging**: Salesforce sandbox or partial-data instance; staging-specific Redis cluster; New Relic reporting to a staging application entity
- **Production**: Production Salesforce org; production Redis cluster; production MySQL; New Relic production reporting; Unicorn worker count tuned to production traffic
