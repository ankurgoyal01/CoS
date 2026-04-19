---
service: "travel-search"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The Getaways Search Service is a Java/Jetty WAR application. Configuration follows standard Continuum platform patterns: environment variables supply runtime values for database connections, cache endpoints, external service URLs, and messaging bootstrap addresses. Service-level properties (search tuning, job schedules, feature toggles) are managed via config files packaged with the WAR or mounted at deploy time. Secret values (credentials, API keys) are injected via the platform secrets management layer.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_URL` | JDBC connection URL for `continuumTravelSearchDb` (MySQL) | yes | — | env / platform |
| `DB_USERNAME` | MySQL database username | yes | — | env / vault |
| `DB_PASSWORD` | MySQL database password | yes | — | vault |
| `REDIS_HOST` | Hostname for `continuumTravelSearchRedis` Redis instance | yes | — | env / platform |
| `REDIS_PORT` | Port for Redis instance | yes | `6379` | env |
| `KAFKA_BOOTSTRAP_SERVERS` | Bootstrap address for Kafka cluster (`externalKafkaCluster_f6a7`) | yes | — | env / platform |
| `KAFKA_GROUP_ID` | Consumer group ID for EAN price update stream | yes | — | env |
| `MBUS_BROKER_URL` | JMS broker URL for internal Message Bus (`externalMessageBus_e5f6`) | yes | — | env / platform |
| `CONTENT_SERVICE_URL` | Base URL for `externalContentService_3b91` | yes | — | env |
| `GEO_SERVICE_URL` | Base URL for `externalGeoService_4c0d` | yes | — | env |
| `INVENTORY_SERVICE_URL` | Base URL for `externalInventoryService_5d2a` | yes | — | env |
| `DEAL_CATALOG_SERVICE_URL` | Base URL for `continuumDealCatalogService` | yes | — | env |
| `FOREX_SERVICE_URL` | Base URL for `continuumForexService` | yes | — | env |
| `RAPI_SERVICE_URL` | Base URL for `externalRapiService_7a2c` | no | — | env |
| `BACKPACK_SERVICE_URL` | Base URL for `externalBackpackService_8b3d` | no | — | env |
| `EAN_API_URL` | Base URL for `externalExpediaEanApi_a1b2` | yes | — | env |
| `EAN_API_KEY` | API key for Expedia EAN API | yes | — | vault |
| `GOOGLE_HOTELS_FEED_URL` | Endpoint for Google Hotels OTA feed upload | no | — | env |
| `RELEVANCE_SERVICE_URL` | Base URL for `externalRelevanceService_c3d4` | no | — | env |
| `GAP_FILTERING_SERVICE_URL` | Base URL for `externalGapFilteringService_d4e5` | no | — | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

> Variable names are derived from component responsibilities in the architecture model. Exact names should be verified against the service's WAR configuration and deployment manifests.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `ENABLE_EAN_PRICE_UPDATES` | Activates Kafka consumer for EAN price update stream | `true` | global |
| `ENABLE_GOOGLE_HOTELS_UPLOAD` | Activates background job for OTA feed upload to Google Hotels | `true` | global |
| `ENABLE_RELEVANCE_RANKING` | Routes search results through `externalRelevanceService_c3d4` | `true` | global |
| `ENABLE_GAP_FILTERING` | Applies locale gap filtering via `externalGapFilteringService_d4e5` | `true` | per-tenant |
| `ENABLE_CARD_DEALS` | Includes RAPI card-based deals in search results | `true` | global |

> Feature flag names are inferred from component responsibilities. Verify exact flag names and storage mechanism in source code.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `WEB-INF/web.xml` | XML | Jetty WAR servlet configuration, filter chain, and listener registration |
| `application.properties` | properties | Service-level defaults — HTTP client timeouts, cache TTLs, job schedules, search tuning parameters |

> Config file paths are standard for a Java Jetty WAR deployment. Verify against the service repository structure.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | MySQL database password for `continuumTravelSearchDb` | vault |
| `EAN_API_KEY` | Expedia EAN API authentication key | vault |
| `MBUS_CREDENTIALS` | JMS broker credentials for internal Message Bus | vault |
| `KAFKA_CREDENTIALS` | Kafka cluster access credentials | vault |

> Secret values are NEVER documented. Only names and rotation policies are listed here. Rotation policies are managed by the Continuum platform secrets team.

## Per-Environment Overrides

- **Development**: Local MySQL and Redis instances; Kafka and MBus connections pointed at local/staging brokers; EAN API key points to sandbox environment
- **Staging**: Staging instances of all downstream services; reduced Kafka consumer throughput; Google Hotels feed upload may be disabled
- **Production**: Full configuration with production credentials, live EAN API, and live Google Hotels feed endpoint; Redis and MySQL scaled per production SLOs
