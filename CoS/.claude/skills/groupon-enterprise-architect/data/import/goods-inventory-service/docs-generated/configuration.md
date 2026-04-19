---
service: "goods-inventory-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["config-files", "env-vars"]
---

# Configuration

## Overview

Goods Inventory Service is configured primarily through Play Framework configuration files (`conf/application.conf` and environment-specific overrides). Database connections, Redis endpoints, external service URLs, and MessageBus settings are defined in these configuration files. Sensitive values (credentials, API keys) are injected via environment variables or secret management.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_DEFAULT_URL` | Primary PostgreSQL connection URL | yes | none | env |
| `DB_DEFAULT_USERNAME` | PostgreSQL username | yes | none | env / secret |
| `DB_DEFAULT_PASSWORD` | PostgreSQL password | yes | none | env / secret |
| `DB_DEFAULT_READONLY_URL` | Read replica PostgreSQL connection URL | yes | none | env |
| `REDIS_HOST` | Redis (GCP Memorystore) host address | yes | none | env |
| `REDIS_PORT` | Redis port | no | 6379 | env |
| `MESSAGEBUS_BROKER_URL` | Groupon MessageBus broker connection URL | yes | none | env |
| `IMS_CLIENT_BASE_URL` | Goods Inventory Management Service base URL | yes | none | env |
| `GOODS_STORES_CLIENT_BASE_URL` | Goods Stores Service base URL | yes | none | env |
| `GPAPI_CLIENT_BASE_URL` | GPAPI Service base URL | yes | none | env |
| `SRS_CLIENT_BASE_URL` | SRS Outbound Controller base URL | yes | none | env |
| `ORC_CLIENT_BASE_URL` | ORC Service base URL | yes | none | env |
| `ITEM_MASTER_CLIENT_BASE_URL` | Item Master Service base URL | yes | none | env |
| `CURRENCY_CONVERSION_BASE_URL` | Currency Conversion Service base URL | yes | none | env |
| `DELIVERY_ESTIMATOR_BASE_URL` | Delivery Estimator Service base URL | yes | none | env |
| `APPLICATION_SECRET` | Play Framework application secret | yes | none | env / secret |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `feature.reverse-fulfillment.enabled` | Enable/disable reverse fulfillment processing | true | global |
| `feature.pricing-cache.enabled` | Enable/disable Redis pricing cache | true | global |
| `feature.cronus-snapshots.enabled` | Enable/disable Cronus snapshot publishing | true | global |
| `feature.add-back-logic.enabled` | Enable/disable add-back logic during cancellations | true | global |
| `feature.charge-when-ship.enabled` | Enable/disable charge-when-ship sync job | true | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `conf/application.conf` | HOCON | Primary Play Framework configuration: routes, DB pools, Redis, HTTP clients, MessageBus, Quartz jobs |
| `conf/routes` | Play routes | HTTP route definitions mapping URLs to controller actions |
| `conf/logback.xml` | XML | Logging configuration for StenoLogger and Logback |
| `conf/evolutions/` | SQL | Database schema evolution scripts for PostgreSQL |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_DEFAULT_PASSWORD` | PostgreSQL database credentials | Environment / secret manager |
| `APPLICATION_SECRET` | Play Framework cryptographic secret | Environment / secret manager |
| `MESSAGEBUS_AUTH_TOKEN` | MessageBus authentication token | Environment / secret manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Configuration differs between environments through environment-specific HOCON overrides and environment variable injection:

- **Development**: Local PostgreSQL and Redis instances, mock or local service URLs, verbose logging
- **Staging**: Shared staging infrastructure, staging service endpoints, standard logging levels
- **Production**: Production PostgreSQL with read replicas, GCP Memorystore Redis, production service URLs, structured JSON logging, tighter connection pool limits and timeouts
