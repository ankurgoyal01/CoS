---
service: "orders-rails3"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

orders-rails3 is configured via environment variables and Rails environment-specific configuration files. Sensitive credentials (payment gateway keys, database passwords, Message Bus credentials) are injected as environment variables at runtime and are not stored in the codebase. The service follows standard Rails configuration conventions with `config/` directory files providing per-environment overrides.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | Primary MySQL/PostgreSQL connection string for `continuumOrdersDb` | yes | none | env |
| `FRAUD_DATABASE_URL` | Connection string for `continuumFraudDb` | yes | none | env |
| `MESSAGING_DATABASE_URL` | Connection string for `continuumOrdersMsgDb` | yes | none | env |
| `REDIS_URL` | Redis connection URL for `continuumRedis` (Resque queues and caching) | yes | none | env |
| `MESSAGEBUS_URL` | Message Bus broker endpoint | yes | none | env |
| `MESSAGEBUS_API_KEY` | Authentication key for Message Bus publishing | yes | none | env |
| `PAYMENT_GATEWAY_URL` | Base URL for primary payment gateway (GlobalPayments/Killbill) | yes | none | env |
| `PAYMENT_GATEWAY_API_KEY` | API key for payment gateway authentication | yes | none | env |
| `ADYEN_API_KEY` | Adyen payment gateway API key | yes | none | env |
| `ADYEN_MERCHANT_ACCOUNT` | Adyen merchant account identifier | yes | none | env |
| `ACCERTIFY_API_KEY` | Accertify fraud screening API key | yes | none | env |
| `USERS_SERVICE_URL` | Base URL for `continuumUsersService` | yes | none | env |
| `DEAL_CATALOG_SERVICE_URL` | Base URL for `continuumDealCatalogService` | yes | none | env |
| `VOUCHER_INVENTORY_SERVICE_URL` | Base URL for `continuumVoucherInventoryService` | yes | none | env |
| `FRAUD_ARBITER_SERVICE_URL` | Base URL for `continuumFraudArbiterService` | yes | none | env |
| `INCENTIVES_SERVICE_URL` | Base URL for `continuumIncentivesService` | yes | none | env |
| `PAYMENTS_SERVICE_URL` | Base URL for `continuumPaymentsService` | yes | none | env |
| `TAXONOMY_SERVICE_URL` | Base URL for `continuumTaxonomyService` | yes | none | env |
| `GEO_DETAILS_SERVICE_URL` | Base URL for `continuumGeoDetailsService` | yes | none | env |
| `GEO_SERVICE_URL` | Base URL for `continuumGeoService` | yes | none | env |
| `M3_MERCHANT_SERVICE_URL` | Base URL for `continuumM3MerchantService` | yes | none | env |
| `M3_PLACES_SERVICE_URL` | Base URL for `continuumM3PlacesService` | yes | none | env |
| `RAILS_ENV` | Rails environment (development, staging, production) | yes | development | env |
| `UNICORN_WORKERS` | Number of Unicorn worker processes | no | 4 | env |
| `RESQUE_WORKER_COUNT` | Number of Resque worker processes | no | 5 | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found of a feature flag system in the architecture model. Per-environment configuration is managed via Rails environment files and environment variables.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | yaml | Database connection configuration per Rails environment |
| `config/resque.yml` | yaml | Resque queue configuration and Redis connection settings |
| `config/initializers/messagebus.rb` | ruby | Message Bus client initialization and topic configuration |
| `config/initializers/payment_gateways.rb` | ruby | Payment gateway client configuration (GlobalPayments, Killbill, Adyen) |
| `config/environments/production.rb` | ruby | Production-specific Rails settings (caching, logging, asset pipeline) |
| `config/environments/staging.rb` | ruby | Staging environment overrides |
| `config/unicorn.rb` | ruby | Unicorn server configuration (worker count, timeout, socket path) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `PAYMENT_GATEWAY_API_KEY` | Authenticates to GlobalPayments/Killbill payment gateway | env / vault |
| `ADYEN_API_KEY` | Authenticates to Adyen payment gateway | env / vault |
| `ACCERTIFY_API_KEY` | Authenticates to Accertify fraud screening | env / vault |
| `MESSAGEBUS_API_KEY` | Authenticates Message Bus publishing | env / vault |
| `DATABASE_URL` | Contains database password for Orders DB | env / vault |
| `FRAUD_DATABASE_URL` | Contains database password for Fraud DB | env / vault |
| `MESSAGING_DATABASE_URL` | Contains database password for Messaging DB | env / vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Uses local database instances and stubbed payment gateway responses; Message Bus publishing is typically disabled or pointed at a local mock
- **Staging**: Uses staging-tier databases and sandbox payment gateway credentials; full Message Bus integration enabled against staging broker
- **Production**: All credentials are production-grade; Unicorn and Resque worker counts are tuned for production load; database connection pools are sized for production concurrency
