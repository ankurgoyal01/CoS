---
service: "deal_centre_api"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Deal Centre API follows standard Spring Boot configuration conventions. Application configuration is supplied through environment variables and Spring Boot `application.properties` / `application.yml` files. External service URLs, database credentials, and Message Bus connection details are injected at runtime via environment variables. Per-environment overrides are managed outside this architecture model.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_HOST` | PostgreSQL host for `continuumDealCentrePostgres` | yes | none | env |
| `DB_PORT` | PostgreSQL port | yes | `5432` | env |
| `DB_NAME` | PostgreSQL database name | yes | none | env |
| `DB_USERNAME` | PostgreSQL username | yes | none | env / vault |
| `DB_PASSWORD` | PostgreSQL password | yes | none | vault |
| `DMAPI_BASE_URL` | Base URL for Deal Management API (`continuumDealManagementApi`) | yes | none | env |
| `DEAL_CATALOG_SERVICE_BASE_URL` | Base URL for Deal Catalog Service (`continuumDealCatalogService`) | yes | none | env |
| `EMAIL_SERVICE_BASE_URL` | Base URL for Email Service (`continuumEmailService`) | yes | none | env |
| `MBUS_CONNECTION_URL` | Message Bus broker connection URL | yes | none | env |
| `MBUS_INVENTORY_TOPIC` | Topic name for inventory events on `messageBus` | yes | none | env |
| `MBUS_CATALOG_TOPIC` | Topic name for deal catalog events on `messageBus` | yes | none | env |
| `SPRING_PROFILES_ACTIVE` | Active Spring profile (dev, staging, production) | yes | none | env |
| `SERVER_PORT` | HTTP port the service listens on | no | `8080` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found for explicit feature flag configuration in the architecture model. Feature flag usage to be confirmed with the service owner.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/application.properties` | properties | Base Spring Boot configuration — server port, datasource, MBus |
| `src/main/resources/application-dev.properties` | properties | Development environment overrides |
| `src/main/resources/application-staging.properties` | properties | Staging environment overrides |
| `src/main/resources/application-production.properties` | properties | Production environment overrides |

> Config file paths are inferred from Spring Boot conventions. Verify actual paths in the service repository.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | PostgreSQL database password for `continuumDealCentrePostgres` | vault |
| `DMAPI_SERVICE_KEY` | Service-to-service auth key for Deal Management API | vault |
| `DEAL_CATALOG_SERVICE_KEY` | Service-to-service auth key for Deal Catalog Service | vault |
| `EMAIL_SERVICE_KEY` | Service-to-service auth key for Email Service | vault |
| `MBUS_CREDENTIALS` | Message Bus authentication credentials | vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Local PostgreSQL instance, stub or dev-tier MBus broker, dev-tier DMAPI and catalog service endpoints
- **Staging**: Staging PostgreSQL instance, staging MBus broker, staging-tier downstream services
- **Production**: Production PostgreSQL cluster (`continuumDealCentrePostgres`), production MBus broker, production DMAPI and catalog service endpoints; credentials injected from Vault
