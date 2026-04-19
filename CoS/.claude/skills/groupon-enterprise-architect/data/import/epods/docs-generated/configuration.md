---
service: "epods"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

EPODS is configured through the JTier / Dropwizard configuration system, which combines YAML config files with environment variable overrides. Partner API credentials, data store connection details, and message bus settings are injected via environment variables (sourced from secrets management). Feature-level toggles and per-partner settings are managed through config files and the Partner Service (`continuumPartnerService`).

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection URL for `continuumEpodsPostgres` | yes | none | env / vault |
| `DATABASE_USER` | PostgreSQL username | yes | none | env / vault |
| `DATABASE_PASSWORD` | PostgreSQL password | yes | none | env / vault |
| `REDIS_URL` | Redis connection URL for `continuumEpodsRedis` | yes | none | env / vault |
| `MESSAGEBUS_URL` | JMS/STOMP broker URL for `messageBus` | yes | none | env / vault |
| `MESSAGEBUS_USER` | Message bus username | yes | none | env / vault |
| `MESSAGEBUS_PASSWORD` | Message bus password | yes | none | env / vault |
| `MINDBODY_API_KEY` | API key for MindBody partner integration | yes | none | env / vault |
| `MINDBODY_API_BASE_URL` | Base URL for MindBody REST API | yes | none | env |
| `BOOKER_API_KEY` | API key for Booker partner integration | yes | none | env / vault |
| `BOOKER_API_BASE_URL` | Base URL for Booker REST API | yes | none | env |
| `SQUARE_API_KEY` | API key for Square partner integration | yes | none | env / vault |
| `SHOPIFY_API_KEY` | API key for Shopify partner integration | yes | none | env / vault |
| `DEAL_CATALOG_BASE_URL` | Base URL for `continuumDealCatalogService` | yes | none | env |
| `CALENDAR_SERVICE_BASE_URL` | Base URL for `continuumCalendarService` | yes | none | env |
| `CFS_BASE_URL` | Base URL for `continuumCfsService` | yes | none | env |
| `PARTNER_SERVICE_BASE_URL` | Base URL for `continuumPartnerService` | yes | none | env |
| `MERCHANT_API_BASE_URL` | Base URL for `continuumMerchantApi` | yes | none | env |
| `ORDERS_SERVICE_BASE_URL` | Base URL for `continuumOrdersService` | yes | none | env |
| `INGESTION_SERVICE_BASE_URL` | Base URL for `continuumIngestionService` | yes | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found of a named feature flag system in the architecture model. Partner-level feature toggles are managed through `continuumPartnerService` configuration rather than a centralized flag store.

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `availability.sync.enabled` | Enables/disables the Quartz availability sync job | true | global |
| `webhook.validation.enabled` | Enables HMAC/signature validation on inbound partner webhooks | true | per-partner |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | yaml | Main Dropwizard / JTier application configuration (server, database pool, Redis, message bus) |
| `config-{env}.yml` | yaml | Per-environment overrides (dev, staging, production) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `epods/db/password` | PostgreSQL password for `continuumEpodsPostgres` | vault |
| `epods/redis/password` | Redis auth token for `continuumEpodsRedis` | vault |
| `epods/mbus/password` | Message bus password for `messageBus` | vault |
| `epods/partners/mindbody/api-key` | MindBody partner API key | vault |
| `epods/partners/booker/api-key` | Booker partner API key | vault |
| `epods/partners/square/api-key` | Square partner API key | vault |
| `epods/partners/shopify/api-key` | Shopify partner API key | vault |

> Secret values are NEVER documented. Only names and rotation policies are recorded here.

## Per-Environment Overrides

- **Development**: Reduced connection pool sizes; partner API base URLs point to sandbox/mock endpoints; message bus points to local or shared dev broker
- **Staging**: Full-size pools; partner sandbox API endpoints; shared staging message bus; mirrors production secrets structure
- **Production**: Full-size pools; live partner API endpoints; production message bus; all secrets sourced from vault
