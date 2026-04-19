---
service: "accounting-service"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Accounting Service is configured primarily through environment variables injected at runtime by the Kubernetes deployment (cloud-elevator). Database and Redis connection strings, external API credentials, and application behavior settings are all supplied via environment variables. Application-level YAML config files define per-environment defaults. No evidence found of Consul or Vault as direct config sources — secrets are injected via Kubernetes secrets.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | Primary MySQL connection string for `continuumAccountingMysql` | yes | None | env / k8s-secret |
| `REDIS_URL` | Redis connection string for `continuumAccountingRedis` (Resque queue and cache) | yes | None | env / k8s-secret |
| `SALESFORCE_API_URL` | Base URL for Salesforce REST API (contract import) | yes | None | env / k8s-secret |
| `SALESFORCE_CLIENT_ID` | OAuth client ID for Salesforce API authentication | yes | None | env / k8s-secret |
| `SALESFORCE_CLIENT_SECRET` | OAuth client secret for Salesforce API authentication | yes | None | env / k8s-secret |
| `MESSAGEBUS_URL` | Groupon Message Bus broker URL | yes | None | env / k8s-secret |
| `MESSAGEBUS_CLIENT_ID` | Message Bus client identifier | yes | None | env / k8s-secret |
| `MESSAGEBUS_CLIENT_SECRET` | Message Bus authentication secret | yes | None | env / k8s-secret |
| `DEAL_CATALOG_SERVICE_URL` | Base URL for `continuumDealCatalogService` REST API | yes | None | env |
| `ORDERS_SERVICE_URL` | Base URL for `continuumOrdersService` (TPS) REST API | yes | None | env |
| `VOUCHER_INVENTORY_SERVICE_URL` | Base URL for `continuumVoucherInventoryService` REST API | yes | None | env |
| `RAILS_ENV` | Rails environment identifier (production, staging, development, test) | yes | development | env |
| `SECRET_KEY_BASE` | Rails secret key base for session and cookie signing | yes | None | env / k8s-secret |
| `RESQUE_WORKER_COUNT` | Number of Resque worker processes to run | no | Platform default | env |
| `COVERBAND_REDIS_URL` | Redis URL for Coverband production code coverage tracking | no | `REDIS_URL` | env |

> IMPORTANT: Secret values are never documented here. Only variable names and purposes are listed.

## Feature Flags

> No evidence found of a dedicated feature flag system (e.g., LaunchDarkly, Flipper) in the service inventory. Behavioral flags may be managed through Rails configuration or environment variables.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | yaml | ActiveRecord database connection configuration per Rails environment |
| `config/resque.yml` | yaml | Resque worker queue configuration |
| `config/application.yml` | yaml | Application-level settings and per-environment overrides (if present) |
| `Gemfile` | Ruby DSL | Dependency manifest for Bundler |
| `Gemfile.lock` | Text | Locked dependency versions |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `salesforce-credentials` | Salesforce API client ID and secret for contract import | k8s-secret |
| `messagebus-credentials` | Message Bus client ID and secret | k8s-secret |
| `database-credentials` | MySQL connection credentials for `continuumAccountingMysql` | k8s-secret |
| `redis-credentials` | Redis connection credentials for `continuumAccountingRedis` | k8s-secret |
| `rails-secret-key-base` | Rails session and cookie signing key | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Production**: All external service URLs point to production endpoints; SOX controls enforce change management (GPROD approval required); Coverband active for production code coverage tracking
- **Staging**: External service URLs point to staging/sandbox endpoints; Salesforce sandbox credentials used; reduced worker counts
- **Development / Test**: Local database and Redis connections; external service integrations typically stubbed or disabled; `RAILS_ENV=test` disables Resque workers in favor of inline job execution
