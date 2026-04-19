---
service: "identity-service"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

identity-service is configured through environment variables for database connections, Message Bus credentials, Redis connectivity, JWT validation, and observability. Config files (likely YAML or environment-specific Ruby config) supply additional structured configuration. The service targets different upstream APIs (GDPR Platform, RaaS) per environment (staging vs. production) via environment variable overrides.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for the primary identity store | yes | None | env |
| `MYSQL_DATABASE_URL` | MySQL connection string for PWA platform data | yes | None | env |
| `REDIS_URL` | Redis connection string for cache and Resque queue | yes | None | env |
| `JWT_SECRET` | Secret used to validate incoming Bearer JWT tokens | yes | None | env / vault |
| `MBUS_HOST` | Message Bus host for event publishing and consumption | yes | None | env |
| `MBUS_PORT` | Message Bus port | yes | None | env |
| `MBUS_USERNAME` | Message Bus authentication username | yes | None | env / vault |
| `MBUS_PASSWORD` | Message Bus authentication password | yes | None | env / vault |
| `GDPR_PLATFORM_URL` | Base URL of the GDPR Platform API (if REST integration) | yes | None | env |
| `RAAS_URL` | Base URL of RaaS (Rewards-as-a-Service) | yes | None | env |
| `RACK_ENV` | Runtime environment (`development`, `test`, `staging`, `production`) | yes | `development` | env |
| `PORT` | HTTP port for Puma to bind | no | `9292` | env |
| `WEB_CONCURRENCY` | Number of Puma worker processes | no | To be confirmed | env |
| `RACK_ATTACK_THROTTLE_LIMIT` | rack-attack throttle limit per window | no | To be confirmed | env |
| `LOG_LEVEL` | Log verbosity for rtier-logger / sonoma-logger | no | `info` | env |
| `SONOMA_METRICS_HOST` | Sonoma metrics reporting endpoint | no | None | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found of a feature flag system in this service's inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `Gemfile` | Ruby DSL | Dependency declarations |
| `Gemfile.lock` | Text | Locked dependency versions |
| `config/database.yml` | YAML | ActiveRecord database configuration per environment |
| `config/environment.rb` (or equivalent) | Ruby | Application initialization and middleware stack |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `JWT_SECRET` | Validates Bearer JWT tokens on all protected endpoints | env / vault |
| `MBUS_PASSWORD` | Authenticates with the Groupon Message Bus | env / vault |
| `DATABASE_URL` | Contains credentials for PostgreSQL access | env / vault |
| `MYSQL_DATABASE_URL` | Contains credentials for MySQL / PWA data access | env / vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `DATABASE_URL` points to a local PostgreSQL instance; Message Bus may be stubbed or pointed to a dev Mbus instance.
- **Staging**: `DATABASE_URL`, `MYSQL_DATABASE_URL`, and `MBUS_HOST` point to staging infrastructure; `GDPR_PLATFORM_URL` and `RAAS_URL` point to staging endpoints.
- **Production**: All variables point to production infrastructure with production-grade secrets managed via the secret store. `RACK_ENV=production` activates production-specific middleware and logging behavior.
