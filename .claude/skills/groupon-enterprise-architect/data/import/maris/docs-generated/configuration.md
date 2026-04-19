---
service: "maris"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, vault]
---

# Configuration

## Overview

MARIS is configured using the standard JTier / Dropwizard configuration model, combining a YAML configuration file with environment variable overrides. Secrets (Expedia API credentials, database passwords, MBus credentials) are injected at runtime via the platform secrets management system. The service follows JTier 5.14.0 conventions for configuration binding.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `MARIS_DB_URL` | JDBC connection URL for `marisMySql` | yes | none | env / vault |
| `MARIS_DB_USER` | MySQL username for `marisMySql` | yes | none | env / vault |
| `MARIS_DB_PASSWORD` | MySQL password for `marisMySql` | yes | none | vault |
| `EXPEDIA_EAN_API_KEY` | API key for Expedia EAN API authentication | yes | none | vault |
| `EXPEDIA_RAPID_API_KEY` | API key for Expedia Rapid API authentication | yes | none | vault |
| `EXPEDIA_RAPID_BASE_URL` | Base URL for Expedia Rapid API | yes | none | env |
| `EXPEDIA_EAN_BASE_URL` | Base URL for Expedia EAN API | yes | none | env |
| `MBUS_BROKER_URL` | MBus broker connection URL | yes | none | env / vault |
| `MBUS_USERNAME` | MBus broker username | yes | none | vault |
| `MBUS_PASSWORD` | MBus broker password | yes | none | vault |
| `ORDERS_SERVICE_URL` | Base URL for the Orders Service | yes | none | env |
| `DEAL_CATALOG_SERVICE_URL` | Base URL for the Deal Catalog Service | yes | none | env |
| `CONTENT_SERVICE_URL` | Base URL for the Content Service | yes | none | env |
| `TRAVEL_SEARCH_SERVICE_URL` | Base URL for the Travel Search Service | yes | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

> Note: Exact environment variable names are inferred from JTier conventions and the integration inventory. Confirm authoritative names against the service's YAML configuration file and deployment manifests.

## Feature Flags

> No evidence found for application-level feature flags in the architecture model inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | YAML | Primary Dropwizard service configuration — server, database pool (HikariCP), MBus, scheduler, and client settings |

> Specific config file path follows JTier / Dropwizard conventions. Confirm location against the service repository's deployment configuration.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `EXPEDIA_EAN_API_KEY` | Authenticates calls to Expedia EAN API | vault |
| `EXPEDIA_RAPID_API_KEY` | Authenticates calls to Expedia Rapid API | vault |
| `MARIS_DB_PASSWORD` | MySQL database password for `marisMySql` | vault |
| `MBUS_PASSWORD` | MBus broker authentication password | vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The service runs in standard Continuum environments (development, staging, production). Per-environment differences are expected in:
- Database connection URLs pointing to environment-specific `marisMySql` instances
- Expedia API base URLs (Expedia provides sandbox endpoints for non-production environments)
- MBus broker URLs pointing to environment-specific broker clusters
- Service URLs for Orders, Deal Catalog, Content, and Travel Search pointing to the appropriate environment tier
