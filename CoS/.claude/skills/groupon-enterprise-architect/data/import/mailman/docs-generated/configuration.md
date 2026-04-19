---
service: "mailman"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Mailman is a Spring Boot 1.2.2 application configured via standard Spring Boot mechanisms: `application.properties` / `application.yml` files and environment variable overrides. Configuration covers database connectivity, MBus connection details, downstream service base URLs, Quartz scheduler settings, EhCache configuration, and Spring Security. No external configuration store (Consul, Vault, Helm) was identified in the architecture model inventory.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `SPRING_DATASOURCE_URL` | PostgreSQL JDBC connection URL for `mailmanPostgres` | yes | none | env |
| `SPRING_DATASOURCE_USERNAME` | PostgreSQL username | yes | none | env |
| `SPRING_DATASOURCE_PASSWORD` | PostgreSQL password | yes | none | env |
| `MBUS_CONNECTION_URL` | MBus/JMS broker connection URL | yes | none | env |
| `MBUS_QUEUE_MAILMAN` | MBus queue name for inbound requests (`MailmanQueue`) | yes | none | env |
| `MBUS_QUEUE_DLQ` | MBus dead letter queue name | yes | none | env |
| `ORDERS_SERVICE_URL` | Base URL for `continuumOrdersService` | yes | none | env |
| `USERS_SERVICE_URL` | Base URL for `continuumUsersService` | yes | none | env |
| `DEAL_CATALOG_SERVICE_URL` | Base URL for `continuumDealCatalogService` | yes | none | env |
| `MARKETING_DEAL_SERVICE_URL` | Base URL for `continuumMarketingDealService` | yes | none | env |
| `VOUCHER_INVENTORY_SERVICE_URL` | Base URL for `continuumVoucherInventoryService` | yes | none | env |
| `RELEVANCE_API_URL` | Base URL for `continuumRelevanceApi` | yes | none | env |
| `UNIVERSAL_MERCHANT_API_URL` | Base URL for `continuumUniversalMerchantApi` | yes | none | env |
| `API_LAZLO_URL` | Base URL for `continuumApiLazloService` | yes | none | env |
| `GOODS_INVENTORY_SERVICE_URL` | Base URL for `continuumGoodsInventoryService` | yes | none | env |
| `TRAVEL_INVENTORY_SERVICE_URL` | Base URL for `continuumTravelInventoryService` | yes | none | env |
| `THIRD_PARTY_INVENTORY_SERVICE_URL` | Base URL for `continuumThirdPartyInventoryService` | yes | none | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

> Note: Specific environment variable names above are inferred from Spring Boot conventions and the inventory's list of integrations. Confirm exact names against the service's `application.properties` / deployment configuration.

## Feature Flags

> No evidence found — no feature flag system was identified in the architecture inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/application.properties` | properties | Primary Spring Boot configuration (datasource, MBus, Quartz, server port, security) |
| `src/main/resources/ehcache.xml` | xml | EhCache 2.9.0 cache region definitions and TTL configuration |
| `src/main/resources/quartz.properties` | properties | Quartz scheduler thread pool and JDBC store configuration |

> Config file paths are inferred from Spring Boot 1.2.2 conventions. Confirm against the service source repository.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SPRING_DATASOURCE_PASSWORD` | PostgreSQL authentication credential | env / deployment secret |
| `MBUS_CONNECTION_URL` | MBus broker connection string (may include credentials) | env / deployment secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Spring Boot 1.2.2 supports profile-based configuration via `application-{profile}.properties`. Environment-specific overrides for database URLs, MBus endpoints, and downstream service base URLs are expected to differ between development, staging, and production environments via profile activation or environment variable injection at deployment time.
