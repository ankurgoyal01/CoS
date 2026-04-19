---
service: "deal-book-service"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Deal Book Service uses standard Rails configuration conventions with environment variables for service URLs, credentials, and external API configuration. Scheduled jobs are configured via `whenever 0.9.4` (cron). The `sonoma-metrics` and `sonoma-logger` libraries are configured through Sonoma platform conventions. Specific variable names below reflect the integration landscape; exact names are not fully discoverable from the inventory.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RAILS_ENV` | Sets the Rails execution environment (development, staging, production) | yes | `development` | env |
| `SECRET_KEY_BASE` | Rails session/cookie signing key | yes | none | env / vault |
| `DATABASE_URL` | MySQL connection URL for `continuumDealBookMysql` | yes | none | env / vault |
| `REDIS_URL` | Redis connection URL for `continuumDealBookRedis` | yes | none | env |
| `GOOGLE_DRIVE_CLIENT_ID` | Google service account client ID for Sheets API access | yes | none | vault |
| `GOOGLE_DRIVE_CLIENT_SECRET` | Google service account client secret | yes | none | vault |
| `TAXONOMY_SERVICE_URL` | Base URL for Taxonomy Service API | yes | none | env |
| `MODEL_API_URL` | Base URL for Model API | yes | none | env |
| `SALESFORCE_API_URL` | Base URL for Salesforce REST API | no | none | env |
| `SALESFORCE_API_TOKEN` | Authentication token for Salesforce API | no | none | vault |
| `MESSAGE_BUS_URL` | Connection URL for the message bus (JMS) | yes | none | env / vault |
| `MESSAGE_BUS_USERNAME` | Message bus authentication username | yes | none | vault |
| `MESSAGE_BUS_PASSWORD` | Message bus authentication password | yes | none | vault |
| `SONOMA_METRICS_HOST` | Host endpoint for Sonoma metrics reporting | no | none | env |
| `SONOMA_LOG_LEVEL` | Log verbosity level for sonoma-logger | no | `info` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/application.rb` | Ruby | Rails application configuration |
| `config/environments/production.rb` | Ruby | Production-specific Rails settings |
| `config/environments/staging.rb` | Ruby | Staging-specific Rails settings |
| `config/environments/development.rb` | Ruby | Development-specific Rails settings |
| `config/initializers/` | Ruby | Per-library initialization (metrics, logger, message bus, Redis) |
| `config/schedule.rb` | Ruby | Cron schedule definitions for rake tasks (via `whenever`) |
| `Gemfile` | Ruby DSL | Dependency manifest |
| `Gemfile.lock` | Text | Locked dependency versions |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SECRET_KEY_BASE` | Rails session signing key | vault / env |
| `DATABASE_URL` | MySQL credentials for `continuumDealBookMysql` | vault |
| `GOOGLE_DRIVE_CLIENT_ID` / `GOOGLE_DRIVE_CLIENT_SECRET` | Google Sheets API authentication | vault |
| `SALESFORCE_API_TOKEN` | Salesforce REST API authentication | vault |
| `MESSAGE_BUS_PASSWORD` | Message bus connection authentication | vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Local or mocked service URLs; relaxed authentication; debug logging; scheduler disabled or run manually
- **Staging**: Points to staging instances of Taxonomy Service, Model API, and message bus; mirrors production config minus live credentials; Google Sheets may point to a test sheet
- **Production**: Full credentials; production MySQL and Redis instances; message bus connected to `jms.topic.taxonomyV2.content.update`; scheduled rake tasks active via `whenever`/cron
