---
service: "goods-stores-api"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Goods Stores API is configured through a combination of environment variables (for secrets and environment-specific settings) and Rails YAML config files (for application behaviour, service URLs, and feature flags). Secrets such as database credentials, API keys, and service tokens are injected via environment variables and are never committed to the repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL connection string for `continuumGoodsStoresDb` | yes | None | env |
| `REDIS_URL` | Redis connection URL for `continuumGoodsStoresRedis` (Resque queues and caching) | yes | None | env |
| `ELASTICSEARCH_URL` | Elasticsearch cluster URL for `continuumGoodsStoresElasticsearch` | yes | None | env |
| `AWS_ACCESS_KEY_ID` | AWS credentials for S3 attachment uploads | yes | None | env / vault |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials for S3 attachment uploads | yes | None | env / vault |
| `AWS_S3_BUCKET` | S3 bucket name for `continuumGoodsStoresS3` | yes | None | env |
| `AVALARA_API_KEY` | API key for Avalara Tax API (`continuumAvalaraService`) | yes | None | env / vault |
| `DEAL_CATALOG_SERVICE_URL` | Base URL for `continuumDealCatalogService` | yes | None | env |
| `PRICING_SERVICE_URL` | Base URL for `continuumPricingService` | yes | None | env |
| `TAXONOMY_SERVICE_URL` | Base URL for `continuumTaxonomyService` | yes | None | env |
| `ORDERS_SERVICE_URL` | Base URL for `continuumOrdersService` | yes | None | env |
| `DEAL_MANAGEMENT_API_URL` | Base URL for `continuumDealManagementApi` | yes | None | env |
| `BHUVAN_SERVICE_URL` | Base URL for `continuumBhuvanService` | yes | None | env |
| `M3_PLACES_SERVICE_URL` | Base URL for `continuumM3PlacesService` | yes | None | env |
| `GOODS_INVENTORY_SERVICE_URL` | Base URL for `continuumGoodsInventoryService` | yes | None | env |
| `USERS_SERVICE_URL` | Base URL for `continuumUsersService` | yes | None | env |
| `MESSAGE_BUS_URL` | JMS/STOMP broker URL for `continuumGoodsStoresMessageBusConsumer` | yes | None | env |
| `RAILS_ENV` | Rails environment (`development`, `staging`, `production`) | yes | `development` | env |
| `SECRET_KEY_BASE` | Rails secret key base for session signing | yes | None | env / vault |
| `RESQUE_WORKER_COUNT` | Number of Resque worker processes to spawn | no | 5 | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Feature flags are managed via database-backed flag records and role checks in `continuumGoodsStoresApi_auth` | Role and feature-flag gate checks on API endpoints | Configured per deployment | per-tenant |

> Specific feature flag names are not discoverable from the repository inventory. Flag configuration is managed via the application database.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | yaml | Rails database connection configuration per environment |
| `config/application.yml` | yaml | Application-level settings (service URLs, feature flag defaults) |
| `config/initializers/elasticsearch.rb` | ruby | Elasticsearch client initialization and index configuration |
| `config/initializers/carrierwave.rb` | ruby | CarrierWave/S3 uploader configuration |
| `config/initializers/resque.rb` | ruby | Resque connection and queue configuration |
| `config/resque.yml` | yaml | Resque queue names and worker concurrency per environment |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_URL` | MySQL credentials for `continuumGoodsStoresDb` | env / vault |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | AWS S3 access for `continuumGoodsStoresS3` | env / vault |
| `AVALARA_API_KEY` | Avalara Tax API authentication | env / vault |
| `SECRET_KEY_BASE` | Rails session signing | env / vault |
| Internal service tokens | Authentication for `schema_driven_client` calls to Continuum services | env / vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Uses local MySQL, Redis, and Elasticsearch instances; S3 uploads may be stubbed; external service URLs point to dev/sandbox endpoints
- **Staging**: Mirrors production configuration; connects to staging-tier Continuum service instances; Avalara uses sandbox credentials
- **Production**: All services point to production endpoints; secrets injected via vault/secrets manager; Resque worker count tuned for production load; SOX audit logging fully active via Paper Trail
