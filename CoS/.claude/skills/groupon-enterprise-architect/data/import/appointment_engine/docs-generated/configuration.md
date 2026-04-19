---
service: "appointment_engine"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The appointment engine is configured via environment variables and Rails config files. Deployment is managed by Capistrano 3.11.0, which manages environment-specific configuration. Database connection settings, external service URLs, and message bus configuration are injected as environment variables. Feature flags are not evidenced at the application level.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RAILS_ENV` | Rails environment mode (development, test, production) | yes | `production` | env |
| `DATABASE_URL` | MySQL connection string for primary database | yes | None | env / capistrano |
| `REDIS_URL` | Redis connection URL for Resque job queue | yes | None | env / capistrano |
| `MEMCACHED_SERVERS` | Memcached server addresses for dalli cache client | yes | None | env / capistrano |
| `MESSAGE_BUS_HOST` | Groupon Message Bus broker host | yes | None | env / capistrano |
| `MESSAGE_BUS_USERNAME` | Message Bus authentication username | yes | None | env / capistrano |
| `MESSAGE_BUS_PASSWORD` | Message Bus authentication password (secret) | yes | None | env / vault |
| `AVAILABILITY_ENGINE_URL` | Base URL for Availability Engine REST API | yes | None | env / capistrano |
| `DEAL_CATALOG_URL` | Base URL for Deal Catalog REST API | yes | None | env / capistrano |
| `ORDERS_SERVICE_URL` | Base URL for Orders Service REST API | yes | None | env / capistrano |
| `USERS_SERVICE_URL` | Base URL for Users Service REST API | yes | None | env / capistrano |
| `ONLINE_BOOKING_NOTIFICATIONS_URL` | Base URL for notification service | yes | None | env / capistrano |
| `API_LAZLO_URL` | Base URL for API Lazlo gateway | yes | None | env / capistrano |
| `RAILS_MAX_THREADS` | Puma thread pool size (concurrency) | no | `5` | env |
| `PORT` | HTTP port for Puma server | no | `3000` | env |
| `LOG_LEVEL` | Rails log verbosity | no | `info` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase for application-level feature flag integration in the appointment engine.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | YAML | Rails database connection configuration per environment |
| `config/environments/production.rb` | Ruby | Rails production environment settings |
| `config/environments/development.rb` | Ruby | Rails development environment settings |
| `config/initializers/resque.rb` | Ruby | Resque configuration (Redis connection, queue names) |
| `config/initializers/dalli.rb` | Ruby | Dalli/Memcached client configuration |
| `config/schedule.rb` | Ruby | resque-scheduler cron job schedule definitions |
| `Capfile` | Ruby | Capistrano deployment configuration entry point |
| `config/deploy.rb` | Ruby | Capistrano shared deployment settings |
| `config/deploy/<environment>.rb` | Ruby | Per-environment Capistrano deployment targets |
| `Gemfile` | Ruby | Bundler dependency manifest |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_PASSWORD` | MySQL database authentication | vault / capistrano secrets |
| `MESSAGE_BUS_PASSWORD` | Message Bus broker authentication | vault / capistrano secrets |
| `API_CLIENT_SECRET` | Authentication secret for api_clients inter-service calls | vault / capistrano secrets |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `RAILS_ENV=development`; local MySQL and Redis instances; message bus typically disabled or mocked.
- **Staging**: Capistrano deploys to staging servers; environment variables point to staging-tier backend services; reduced Puma thread count.
- **Production**: Capistrano deploys to production servers; full Puma thread pools; all external service URLs point to production endpoints; Resque workers enabled with full queue configuration.
