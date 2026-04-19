---
service: "consumer-data"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Consumer Data Service is configured primarily through environment variables injected at runtime. Database connection, MessageBus credentials, and external service endpoints are expected to be provided via environment. Sinatra/Puma server settings may be defined in config files within the repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL connection string for ActiveRecord | yes | none | env |
| `MESSAGEBUS_URL` | MessageBus broker endpoint | yes | none | env |
| `MESSAGEBUS_USERNAME` | MessageBus authentication username | yes | none | env |
| `MESSAGEBUS_PASSWORD` | MessageBus authentication password (secret) | yes | none | env |
| `BHOOMI_SERVICE_URL` | Endpoint for bhoomi GeoDetails service | yes | none | env |
| `BHUVAN_SERVICE_URL` | Endpoint for bhuvan external data service | yes | none | env |
| `SERVICE_DISCOVERY_ENV` | Environment label used by service_discovery_client | yes | none | env |
| `RACK_ENV` | Sinatra/Rack environment (development, staging, production) | yes | development | env |
| `PORT` | Puma HTTP listen port | no | 9292 | env |
| `LOG_LEVEL` | sonoma-logger log level | no | info | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase for a feature flag system.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `Gemfile` | Ruby DSL | Dependency declarations |
| `Gemfile.lock` | Text | Locked dependency versions |
| `config/puma.rb` | Ruby DSL | Puma server configuration (workers, threads, port) |
| `config/database.yml` | YAML | ActiveRecord database connection profiles per environment |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `MESSAGEBUS_PASSWORD` | MessageBus broker authentication | env (injected at deploy) |
| `DATABASE_URL` | Contains database credentials | env (injected at deploy) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- `RACK_ENV=development` enables verbose logging and local database configuration.
- `RACK_ENV=staging` connects to staging MySQL and MessageBus instances.
- `RACK_ENV=production` enables production database, MessageBus, and all external service endpoints.
- Capistrano deployment scripts (`capistrano 3.16.0`) manage environment-specific variable injection at deploy time.
