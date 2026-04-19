---
service: "glive-gia"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

GIA is configured through a combination of Rails environment-specific config files (e.g., `config/database.yml`, `config/redis.yml`) and environment variables for secrets and deployment-specific values. Ticketing provider credentials are stored per-deal in MySQL (as references), not as global environment variables. Admin user authentication delegates to OGWall, whose connection details are configured via environment variables.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL connection string for GIA primary database | yes | none | env |
| `REDIS_URL` | Redis connection URL for Resque queue and Rails cache | yes | none | env |
| `RAILS_ENV` | Rails environment (`development`, `staging`, `production`) | yes | `development` | env |
| `SECRET_KEY_BASE` | Rails session cookie encryption key | yes | none | env / vault |
| `OGWALL_BASE_URL` | Base URL of OGWall authentication service | yes | none | env |
| `SALESFORCE_API_URL` | Salesforce REST API base URL | yes | none | env |
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth client ID | yes | none | env / vault |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth client secret | yes | none | vault |
| `DEAL_MANAGEMENT_API_URL` | Base URL of the Deal Management API | yes | none | env |
| `INVENTORY_SERVICE_URL` | Base URL of the Inventory Service | yes | none | env |
| `ACCOUNTING_SERVICE_URL` | Base URL of the Accounting Service | yes | none | env |
| `CUSTOM_FIELDS_SERVICE_URL` | Base URL of the Custom Fields Service | yes | none | env |
| `GTX_SERVICE_URL` | Base URL of the GTX tax/inventory service | yes | none | env |
| `RAILS_LOG_LEVEL` | Log verbosity (`debug`, `info`, `warn`, `error`) | no | `info` | env |
| `UNICORN_WORKERS` | Number of Unicorn worker processes | no | varies by environment | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are recorded here.

## Feature Flags

> No evidence found for a feature flag system (e.g., LaunchDarkly, Flipper) in the inventory. GIA does not appear to use runtime feature flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | YAML | MySQL connection settings per Rails environment |
| `config/redis.yml` | YAML | Redis connection settings for cache and Resque |
| `config/initializers/resque.rb` | Ruby | Resque queue and scheduler configuration |
| `config/initializers/money.rb` | Ruby | money-rails currency and rounding defaults |
| `config/schedule.rb` (resque-scheduler) | YAML/Ruby | Cron schedule definitions for recurring background jobs |
| `config/unicorn.rb` | Ruby | Unicorn web server worker count and timeout settings |
| `config/routes.rb` | Ruby | Rails route definitions for all API endpoints |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SECRET_KEY_BASE` | Rails encrypted session signing | vault / env |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth authentication | vault |
| Ticketing provider API credentials | Per-deal Ticketmaster/Provenue/AXS API access keys | MySQL (`ticketmaster_settings`, `provenue_settings`, `axs_settings`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Uses local MySQL and Redis instances; Salesforce and ticketing provider integrations may point to sandbox environments
- **Staging**: Full integration with staging instances of Salesforce, Deal Management API, Inventory Service, and ticketing provider sandboxes; Unicorn worker count reduced vs. production
- **Production**: Full integration with all live external systems; Unicorn worker count scaled for production load; all secrets sourced from vault
