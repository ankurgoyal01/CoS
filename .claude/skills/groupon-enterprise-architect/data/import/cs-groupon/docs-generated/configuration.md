---
service: "cs-groupon"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

cyclops is configured via environment variables injected at container startup (Docker / Capistrano deployment) and Rails environment-specific config files. Secrets (database credentials, API tokens, Redis URLs) are provided as environment variables and are not committed to source. Rails environment (`RAILS_ENV`) determines which config file overlays are active.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RAILS_ENV` | Rails environment selector (development, staging, production) | yes | development | env |
| `DATABASE_URL` | MySQL connection string for `continuumCsAppDb` | yes | none | env |
| `REDIS_URL` | Redis connection URL for `continuumCsRedisCache` | yes | none | env |
| `MEMCACHED_SERVERS` | Memcached server addresses for fragment caching | yes | none | env |
| `ELASTICSEARCH_URL` | Elasticsearch endpoint for fuzzy search | yes | none | env |
| `ZENDESK_URL` | Base URL for Zendesk API | yes | none | env |
| `ZENDESK_USERNAME` | Zendesk API username / email | yes | none | env |
| `ZENDESK_API_TOKEN` | Zendesk API token credential | yes | none | env |
| `MESSAGEBUS_URL` | MBus broker connection URL | yes | none | env |
| `SECRET_KEY_BASE` | Rails session secret key | yes | none | env |
| `UNICORN_WORKERS` | Number of Unicorn worker processes | no | 4 | env |
| `RESQUE_REDIS_URL` | Redis URL for Resque job queues (may share `REDIS_URL`) | yes | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Feature flags stored in `continuumCsRedisCache` | Runtime toggles for CS workflow features | Service-specific | per-region |

> Specific feature flag names are not enumerable from the DSL inventory. Flags are stored in Redis and managed operationally by the GSO Engineering team.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | yaml | ActiveRecord MySQL database connection settings per environment |
| `config/redis.yml` | yaml | Redis connection settings per environment |
| `config/application.rb` | Ruby | Rails application-level configuration |
| `config/environments/production.rb` | Ruby | Production-specific Rails overrides |
| `config/environments/staging.rb` | Ruby | Staging-specific Rails overrides |
| `config/unicorn.rb` | Ruby | Unicorn web server worker and socket configuration |
| `config/resque.yml` | yaml | Resque queue definitions and Redis connection |
| `config/initializers/` | Ruby | Per-gem and per-integration initialization (Warden, CanCan, Zendesk, etc.) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_URL` | MySQL password embedded in connection string | env |
| `ZENDESK_API_TOKEN` | Zendesk API authentication credential | env |
| `MESSAGEBUS_URL` | MBus broker credentials embedded in URL | env |
| `SECRET_KEY_BASE` | Rails session encryption key | env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Uses local MySQL, Redis, and Memcached instances; Zendesk and MBus may point to sandbox or be stubbed
- **Staging**: Mirrors production configuration with staging-tier service endpoints; uses dedicated staging MySQL and Redis instances
- **Production (SNC1 / SAC1 / DUB1)**: Full configuration with production credentials and region-specific endpoint overrides; `RAILS_ENV=production`; Unicorn worker count tuned to instance capacity
