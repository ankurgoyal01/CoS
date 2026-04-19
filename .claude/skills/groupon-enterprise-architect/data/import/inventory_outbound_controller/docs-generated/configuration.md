---
service: "inventory_outbound_controller"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

inventory_outbound_controller uses a combination of Play Framework configuration files (typically `application.conf` in HOCON format) and environment variable overrides for deployment-specific values. Database connection details, message bus endpoints, and external service URLs are expected to be injected via environment variables at runtime, following standard Continuum platform practices. Schema migrations are managed by Liquibase at startup.

## Environment Variables

> No evidence found in codebase for an explicit inventory of environment variable names for this service. The following are inferred from the service's dependencies and standard Continuum/Play Framework patterns.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_URL` | JDBC connection URL for the MySQL database (`continuumInventoryOutboundControllerDb`) | yes | None | env / k8s-secret |
| `DB_USER` | MySQL database username | yes | None | env / k8s-secret |
| `DB_PASSWORD` | MySQL database password | yes | None | env / k8s-secret |
| `MBUS_BROKER_URL` | JMS message bus broker connection URL | yes | None | env |
| `MBUS_USERNAME` | Message bus authentication username | yes | None | env / k8s-secret |
| `MBUS_PASSWORD` | Message bus authentication password | yes | None | env / k8s-secret |
| `INVENTORY_SERVICE_URL` | Base URL of the Inventory Service | yes | None | env |
| `GOODS_INVENTORY_SERVICE_URL` | Base URL of the Goods Inventory Service | yes | None | env |
| `ORDERS_SERVICE_URL` | Base URL of the Orders Service | yes | None | env |
| `DEAL_CATALOG_SERVICE_URL` | Base URL of the Deal Catalog Service | yes | None | env |
| `USERS_SERVICE_URL` | Base URL of the Users Service | yes | None | env |
| `PRICING_SERVICE_URL` | Base URL of the Pricing Service | yes | None | env |
| `ROCKETMAN_EMAIL_URL` | Base URL of the Rocketman Email service | yes | None | env |
| `LANDMARK_3PL_URL` | Base URL of the Landmark Global 3PL HTTP endpoint | yes | None | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase for a feature flag system used by this service.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `conf/application.conf` | HOCON (Play Framework) | Primary application configuration: database connection pool settings, JMS consumer configuration, Quartz scheduler settings, HTTP timeouts |
| `conf/routes` | Play routes DSL | HTTP route definitions mapping paths to controller actions |
| `db/changelog/` (inferred Liquibase path) | XML / YAML | Database schema migration changelogs managed by Liquibase 3.3 |
| `build.sbt` | SBT DSL | Project build definition, dependency declarations, SBT plugin config |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | MySQL database password | k8s-secret (inferred) |
| `MBUS_PASSWORD` | Message bus authentication password | k8s-secret (inferred) |
| Google Sheets API credentials | Authentication for Google Sheets integration | k8s-secret (inferred) |
| Landmark Global 3PL credentials | Authentication for 3PL HTTP calls | k8s-secret (inferred) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Play Framework's `application.conf` supports environment-specific overlays. Database URLs, message bus broker addresses, and external service base URLs differ between development, staging, and production environments. Quartz job schedules may be disabled or use shorter intervals in non-production environments. Liquibase migrations are applied automatically on startup across all environments.
