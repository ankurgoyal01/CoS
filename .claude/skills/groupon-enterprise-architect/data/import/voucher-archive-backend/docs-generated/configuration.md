---
service: "voucher-archive-backend"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The voucher-archive-backend follows the standard Rails/Continuum configuration pattern: environment-specific values are injected via environment variables at runtime, with YAML config files used for framework-level settings (database connections, Puma threads, Resque/Redis). Secrets such as database passwords and API keys are never stored in the repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL_DEALS` | Connection string for the deals MySQL database | yes | none | env |
| `DATABASE_URL_USERS` | Connection string for the users MySQL database | yes | none | env |
| `DATABASE_URL_ORDERS` | Connection string for the orders MySQL database | yes | none | env |
| `DATABASE_URL_TRAVEL` | Connection string for the travel MySQL database | yes | none | env |
| `REDIS_URL` | Redis connection URL for Resque and action events | yes | none | env |
| `USERS_SERVICE_URL` | Base URL of the Continuum Users Service for token validation | yes | none | env |
| `CS_TOKEN_SERVICE_URL` | Base URL of the CS Token Service for CSR auth | yes | none | env |
| `MX_MERCHANT_API_URL` | Base URL of the MX Merchant API for merchant auth | yes | none | env |
| `RETCON_SERVICE_URL` | Base URL of the Retcon Service for GDPR erasure | yes | none | env |
| `MESSAGE_BUS_URL` | JMS message bus connection URL | yes | none | env |
| `IMAGE_SERVICE_URL` | Base URL of the Image Service | no | none | env |
| `DEAL_CATALOG_SERVICE_URL` | Base URL of the Deal Catalog Service | no | none | env |
| `CITY_SERVICE_URL` | Base URL of the City Service | no | none | env |
| `RAILS_ENV` | Rails environment (development, staging, production) | yes | development | env |
| `PORT` | HTTP port for the Puma server | no | 3000 | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | yaml | MySQL database connection configuration per environment |
| `config/puma.rb` | ruby | Puma server thread and worker configuration |
| `config/schedule.rb` | ruby | Whenever cron job schedule definitions |
| `config/initializers/resque.rb` | ruby | Redis/Resque connection and queue configuration |
| `Gemfile` | ruby | Dependency manifest |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_PASSWORD_*` | MySQL database passwords for all four databases | No evidence found in codebase. |
| `MESSAGE_BUS_CREDENTIALS` | Message bus authentication credentials | No evidence found in codebase. |
| `SERVICE_API_KEYS` | API keys for downstream service authentication | No evidence found in codebase. |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The service uses Rails' built-in environment system (`RAILS_ENV`). The `config/database.yml` file defines separate connection blocks for `development`, `test`, `staging`, and `production` environments. Puma thread counts and worker counts are expected to be higher in production. Whenever cron jobs run only in production and staging environments.
