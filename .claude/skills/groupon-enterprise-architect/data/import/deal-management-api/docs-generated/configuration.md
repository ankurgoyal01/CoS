---
service: "deal-management-api"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

DMAPI is configured primarily through environment variables injected at runtime, supplemented by Rails environment-specific config files (`config/environments/`). Service discovery endpoints for internal dependencies are resolved via the `service-discovery-client` library, which reads its configuration from environment or config files. Secrets (database credentials, API tokens) are supplied via environment variables and are never committed to source control.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL connection string for `continuumDealManagementMysql` | yes | none | env |
| `REDIS_URL` | Redis connection URL for `continuumDealManagementRedis` (Resque queue + cache) | yes | none | env |
| `SALESFORCE_API_URL` | Base URL for Salesforce REST API integration | yes | none | env |
| `SALESFORCE_API_TOKEN` | Authentication token for Salesforce API calls | yes | none | env |
| `RAILS_ENV` | Rails environment designation (development, staging, production) | yes | development | env |
| `SECRET_KEY_BASE` | Rails secret key for session signing | yes | none | env |
| `RESQUE_QUEUE_NAMESPACE` | Namespace prefix for Resque queues in Redis | no | dmapi | env |
| `RESQUE_WORKER_COUNT` | Number of Resque worker processes to start | no | 2 | env |
| `SERVICE_DISCOVERY_URL` | Base URL for internal service discovery registry | yes | none | env |
| `DEAL_CATALOG_SERVICE_URL` | Endpoint override for Deal Catalog Service (if not using discovery) | no | via discovery | env |
| `PUMA_WORKERS` | Number of Puma worker processes | no | 2 | env |
| `PUMA_THREADS_MIN` | Minimum Puma thread count per worker | no | 1 | env |
| `PUMA_THREADS_MAX` | Maximum Puma thread count per worker | no | 5 | env |
| `LOG_LEVEL` | steno_logger log level (debug, info, warn, error) | no | info | env |
| `METRICS_ENABLED` | Enable sonoma-metrics emission | no | true | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found of a dedicated feature flag system in the inventory. Behavior variations are controlled via Rails environment configuration and environment variables.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | YAML | Database connection configuration per Rails environment |
| `config/resque.yml` | YAML | Resque queue names and Redis connection settings |
| `config/initializers/service_discovery.rb` | Ruby | Initializes `service-discovery-client` with registry URL |
| `config/initializers/metrics.rb` | Ruby | Configures sonoma-metrics emitter |
| `config/environments/production.rb` | Ruby | Production-specific Rails settings (caching, logging, etc.) |
| `config/environments/staging.rb` | Ruby | Staging overrides |
| `config/environments/development.rb` | Ruby | Local development settings |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_URL` | MySQL host, port, database name, username, and password | env (injected at deploy time) |
| `SALESFORCE_API_TOKEN` | Salesforce API authentication credential | env (injected at deploy time) |
| `SECRET_KEY_BASE` | Rails session encryption key | env (injected at deploy time) |
| `REDIS_URL` | Redis authentication and connection string | env (injected at deploy time) |

> Secret values are NEVER documented. Only names and rotation policies are recorded here. Rotation policies are managed by the dms-dev team.

## Per-Environment Overrides

- **Development**: Uses local MySQL and Redis instances; service discovery may point to stub URLs; Salesforce integration is typically disabled or pointed at a sandbox.
- **Staging**: Full service discovery enabled; Salesforce Sandbox or test org; reduced Puma/Resque worker counts.
- **Production**: Full-scale Puma and Resque worker pools; production Salesforce org; metrics emission active; log level set to `warn` or `info`.
