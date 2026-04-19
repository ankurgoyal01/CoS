---
service: "Deal-Estate"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, redis]
---

# Configuration

## Overview

Deal-Estate is configured through environment variables (injected at runtime), Rails environment-specific config files (`config/environments/`), and Redis-backed feature flags managed by the `rollout` gem. Secrets (database credentials, Salesforce OAuth tokens, service credentials) are provided via environment variables and are never committed to source.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RAILS_ENV` | Rails environment mode (production, staging, development) | yes | development | env |
| `DATABASE_URL` | MySQL connection string for primary database | yes | none | env |
| `REDIS_URL` | Redis connection URL for Resque queues, cache, and rollout flags | yes | none | env |
| `MEMCACHE_SERVERS` | Comma-separated Memcached server addresses (dalli client) | yes | none | env |
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth client ID | yes | none | env |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth client secret | yes | none | env |
| `SALESFORCE_USERNAME` | Salesforce API username | yes | none | env |
| `SALESFORCE_PASSWORD` | Salesforce API password + security token | yes | none | env |
| `MESSAGEBUS_URL` | Message bus broker connection URL | yes | none | env |
| `SECRET_KEY_BASE` | Rails secret key for session signing | yes | none | env |
| `UNICORN_WORKERS` | Number of Unicorn worker processes | no | platform default | env |
| `RESQUE_WORKER_COUNT` | Number of Resque worker processes | no | platform default | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Managed via `rollout` gem | Redis-backed feature flags for progressive rollout of features | off | per-user, per-group, or percentage-based |

> Specific flag names are managed at runtime via the rollout Redis keys. Consult the service owner or inspect Redis for active flags in each environment.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | yaml | MySQL connection configuration per environment |
| `config/environments/production.rb` | Ruby | Production-specific Rails settings |
| `config/environments/staging.rb` | Ruby | Staging-specific Rails settings |
| `config/environments/development.rb` | Ruby | Development-specific Rails settings |
| `config/initializers/resque.rb` | Ruby | Resque and Redis connection initialisation |
| `config/initializers/dalli.rb` | Ruby | Memcached (dalli) connection initialisation |
| `config/resque_schedule.yml` | yaml | Resque Scheduler job definitions and cron schedules |
| `config/unicorn.rb` | Ruby | Unicorn web server configuration (worker count, timeouts) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_URL` | MySQL credentials for Deal Estate primary database | env |
| `SALESFORCE_CLIENT_ID` / `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth application credentials | env |
| `SALESFORCE_USERNAME` / `SALESFORCE_PASSWORD` | Salesforce API user credentials | env |
| `MESSAGEBUS_URL` | Message bus broker credentials | env |
| `SECRET_KEY_BASE` | Rails session signing key | env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Production**: Full Unicorn worker pool, production MySQL and Redis endpoints, Salesforce production org credentials, message bus production broker.
- **Staging**: Staging MySQL and Redis instances, Salesforce sandbox credentials, reduced worker counts.
- **Development**: Local or Docker-composed MySQL/Redis/Memcached, stub or sandbox Salesforce credentials, single Unicorn worker.
