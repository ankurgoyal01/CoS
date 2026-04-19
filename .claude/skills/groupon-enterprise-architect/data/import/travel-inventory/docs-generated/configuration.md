---
service: "travel-inventory"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, appconfig]
---

# Configuration

## Overview

Getaways Inventory Service uses an AppConfig and ConfigReader-based configuration system that loads environment-specific settings for database roles, connection pools, feature flags, external service endpoints, cache hosts, and messaging broker destinations. The Configuration & Environment component centralizes all configuration loading. A Configuration API is available in development environments to read and update runtime configuration values.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_PRIMARY_HOST` | MySQL primary (write) host | yes | none | env |
| `DB_READ_HOST` | MySQL read replica host | yes | none | env |
| `DB_AUDIT_HOST` | MySQL audit workload host | no | primary host | env |
| `DB_REPORTING_HOST` | MySQL reporting workload host | no | read host | env |
| `DB_USERNAME` | Database username | yes | none | env / vault |
| `DB_PASSWORD` | Database password | yes | none | vault |
| `DB_POOL_SIZE` | Connection pool size | no | framework default | env |
| `REDIS_HOTEL_PRODUCT_HOST` | Redis host for Hotel Product Detail Cache | yes | none | env |
| `REDIS_HOTEL_PRODUCT_PORT` | Redis port for Hotel Product Detail Cache | no | 6379 | env |
| `REDIS_INVENTORY_PRODUCT_HOST` | Redis host for Inventory Product Cache | yes | none | env |
| `REDIS_INVENTORY_PRODUCT_PORT` | Redis port for Inventory Product Cache | no | 6379 | env |
| `MEMCACHED_AVAILABILITY_HOST` | Memcached host for Backpack Availability Cache | yes | none | env |
| `CONTENT_SERVICE_BASE_URL` | Base URL for Getaways Content Service | yes | none | env |
| `BACKPACK_SERVICE_BASE_URL` | Base URL for Backpack Reservation Service | yes | none | env |
| `VOUCHER_INVENTORY_BASE_URL` | Base URL for Voucher Inventory Service | yes | none | env |
| `FOREX_SERVICE_HOST` | Host for Forex Service | yes | none | env |
| `FOREX_SERVICE_PATH` | Path for Forex Service API | no | default path | env |
| `MBUS_BROKER_URL` | MBus broker endpoint URL | yes | none | env |
| `MBUS_DESTINATIONS` | MBus topic/queue destinations configuration | yes | none | env |
| `SFTP_HOST` | AWS SFTP Transfer endpoint hostname | yes | none | env |
| `SFTP_USERNAME` | SFTP authentication username | yes | none | env / vault |
| `SFTP_PRIVATE_KEY` | SFTP SSH private key | yes | none | vault |
| `APP_ENVIRONMENT` | Application environment identifier (dev, staging, production) | yes | none | env |
| `CACHE_TTL_HOTEL_PRODUCT` | TTL for Hotel Product Detail Cache entries | no | configured default | env |
| `CACHE_TTL_INVENTORY_PRODUCT` | TTL for Inventory Product Cache entries | no | configured default | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `audit_endpoints_enabled` | Enables or disables Audit API endpoints | false | global |
| `unity_shopping_enabled` | Enables Unity product API shopping flows | true | global |
| `backpack_availability_cache_enabled` | Enables Memcached-based Backpack availability caching | true | global |
| `ota_updates_enabled` | Enables OTA inventory and rate update processing | true | global |
| `config_api_enabled` | Enables Configuration API (typically dev-only) | false | per-environment |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| Application config (AppConfig) | properties / yaml | Primary configuration file loaded by ConfigReader; defines database roles, external service endpoints, cache settings, and feature flags |
| Log4j2 config | xml | Logging configuration for Log4j2 framework |
| Flyway config | properties | Database migration configuration for Flyway |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | MySQL database password | vault / env |
| `SFTP_PRIVATE_KEY` | SSH private key for AWS SFTP Transfer authentication | vault |
| `MBUS_CREDENTIALS` | Message bus broker authentication credentials | vault / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Configuration API is enabled for runtime value updates. Audit endpoints may be enabled. Database may point to a shared dev instance. SFTP transfers may target a dev/test SFTP endpoint.
- **Staging**: Full production-like configuration with separate database hosts, dedicated cache instances, and staging SFTP endpoint. Feature flags match production defaults.
- **Production**: All external service URLs point to production endpoints. Database role routing is fully active (primary, read replica, audit, reporting). SFTP transfers target the production AWS SFTP Transfer endpoint. Configuration API is disabled. Full metrics and logging are enabled.
