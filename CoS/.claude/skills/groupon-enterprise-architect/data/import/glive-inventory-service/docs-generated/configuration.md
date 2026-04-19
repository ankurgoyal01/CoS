---
service: "glive-inventory-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, messagebus-config]
---

# Configuration

## Overview

GLive Inventory Service is configured through a combination of Rails environment configuration files, environment variables, and external configuration via MessageBus. The service follows standard Rails conventions with environment-specific configuration under `config/environments/`. External service endpoints are resolved via service_discovery_client. Background job configuration (queues, concurrency) is managed through Resque/ActiveJob configuration. MessageBus topic and queue settings are defined in `messagebus.yml`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RAILS_ENV` | Rails environment (development, staging, production) | yes | development | env |
| `DATABASE_URL` | MySQL database connection string | yes | — | env |
| `REDIS_URL` | Redis connection URL for caching and locking | yes | — | env |
| `RESQUE_REDIS_URL` | Redis connection URL for Resque job queues | yes | — | env |
| `SECRET_KEY_BASE` | Rails secret key for session and token signing | yes | — | env / vault |
| `ELASTIC_APM_SERVER_URL` | Elastic APM server endpoint for tracing | no | — | env |
| `ELASTIC_APM_SERVICE_NAME` | Service name reported to Elastic APM | no | glive-inventory-service | env |
| `TICKETMASTER_API_KEY` | API key for Ticketmaster integration | yes (if TM enabled) | — | vault |
| `TICKETMASTER_API_URL` | Base URL for Ticketmaster API | yes (if TM enabled) | — | env / config |
| `AXS_CLIENT_ID` | OAuth client ID for AXS v2 API | yes (if AXS enabled) | — | vault |
| `AXS_CLIENT_SECRET` | OAuth client secret for AXS v2 API | yes (if AXS enabled) | — | vault |
| `AXS_API_URL` | Base URL for AXS API | yes (if AXS enabled) | — | env / config |
| `TELECHARGE_API_URL` | Base URL for Telecharge partner API | yes (if TC enabled) | — | env / config |
| `TELECHARGE_CREDENTIALS` | Telecharge partner authentication credentials | yes (if TC enabled) | — | vault |
| `PROVENUE_API_URL` | Base URL for ProVenue partner API | yes (if PV enabled) | — | env / config |
| `PROVENUE_CREDENTIALS` | ProVenue partner authentication credentials | yes (if PV enabled) | — | vault |
| `MESSAGEBUS_URL` | MessageBus broker connection URL | yes | — | env |
| `VARNISH_PURGE_URL` | Varnish cache purge endpoint | yes | — | env / config |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Ticketmaster integration enabled | Controls whether Ticketmaster API integration is active | true | global |
| AXS integration enabled | Controls whether AXS API integration is active | true | global |
| Telecharge integration enabled | Controls whether Telecharge integration is active | true | global |
| ProVenue integration enabled | Controls whether ProVenue integration is active | true | global |
| Background job processing | Controls whether Resque workers process jobs | true | global |
| Cache invalidation enabled | Controls whether Varnish PURGE requests are sent on state changes | true | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | YAML | MySQL database connection configuration per environment |
| `config/environments/*.rb` | Ruby | Rails environment-specific settings (development, staging, production) |
| `config/application.rb` | Ruby | Core Rails application configuration |
| `config/routes.rb` | Ruby | API route definitions for all endpoint namespaces |
| `config/messagebus.yml` | YAML | MessageBus topic and queue configuration for STOMP/JMS |
| `config/resque.yml` | YAML | Resque/Redis configuration for background job queues |
| `config/initializers/elastic_apm.rb` | Ruby | Elastic APM agent configuration |
| `config/initializers/sonoma.rb` | Ruby | Sonoma metrics and logging configuration |
| `config/initializers/steno.rb` | Ruby | Steno structured logger configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SECRET_KEY_BASE` | Rails session and token signing | vault / env |
| `TICKETMASTER_API_KEY` | Ticketmaster API authentication | vault |
| `AXS_CLIENT_ID` | AXS OAuth 2.0 client identifier | vault |
| `AXS_CLIENT_SECRET` | AXS OAuth 2.0 client secret | vault |
| `TELECHARGE_CREDENTIALS` | Telecharge partner authentication | vault |
| `PROVENUE_CREDENTIALS` | ProVenue partner authentication | vault |
| `DATABASE_URL` | MySQL connection string (contains credentials) | vault / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Uses local MySQL and Redis instances. External third-party APIs are stubbed or pointed at sandbox environments. Varnish cache is typically bypassed. Elastic APM may be disabled.
- **Staging**: Connects to staging MySQL and Redis clusters. Third-party APIs use sandbox/test credentials. MessageBus connects to staging broker. Full observability stack enabled.
- **Production**: Connects to production MySQL and Redis clusters with high-availability configuration. Third-party APIs use production credentials with real inventory. Varnish HTTP cache fully enabled. All observability (Steno, Sonoma, Elastic APM) active with production thresholds and alerting.
