---
service: "dynamic_pricing"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The Pricing Service is a Java 8 / Maven application deployed on Kubernetes. Configuration is supplied through environment variables injected at deploy time and static configuration files bundled with the application. Database connection details, Redis connection parameters, MBus broker addresses, and outbound HTTP client URLs are all externalised as environment variables. Quartz scheduler settings are defined in configuration files.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `PRICING_DB_URL` | JDBC URL for `continuumPricingDb` (MySQL) | yes | none | env |
| `PRICING_DB_USER` | Database username for `continuumPricingDb` | yes | none | env |
| `PRICING_DB_PASSWORD` | Database password for `continuumPricingDb` | yes | none | env |
| `PWA_DB_URL` | JDBC URL for `continuumPwaDb` (MySQL) | yes | none | env |
| `PWA_DB_USER` | Database username for `continuumPwaDb` | yes | none | env |
| `PWA_DB_PASSWORD` | Database password for `continuumPwaDb` | yes | none | env |
| `REDIS_HOST` | Hostname of `continuumRedisCache` (Redis) | yes | none | env |
| `REDIS_PORT` | Port for `continuumRedisCache` | yes | none | env |
| `MBUS_BROKER_URL` | JMS broker URL for `continuumMbusBroker` | yes | none | env |
| `VIS_BASE_URL` | Base URL for `continuumVoucherInventoryService` HTTP client | yes | none | env |
| `DEAL_CATALOG_BASE_URL` | Base URL for `continuumDealCatalogService` HTTP client | yes | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are recorded here.

> No evidence found for the exact environment variable names used in the codebase. The variables above are derived from the architecture inventory and represent the logical configuration required by each integration.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Product feature flags | Control pricing eligibility and client enablement per product | No evidence found | per-product |

> Feature flags are managed through the `continuumPricingService_featureFlagController` and `continuumPricingService_featureFlagService` components, stored in `continuumPricingDb`. Per-product flag values are managed via the API.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| Quartz scheduler config | properties | Configures Quartz thread pool, job store (JDBC-backed against `continuumPricingDb`), and scheduler intervals |
| NGINX config | NGINX conf | Defines upstream routing rules for read/write pods and health check path for `continuumDynamicPricingNginx` |

> No evidence found for specific config file paths in the available architecture inventory.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `PRICING_DB_PASSWORD` | Authentication credential for `continuumPricingDb` | env / platform secrets |
| `PWA_DB_PASSWORD` | Authentication credential for `continuumPwaDb` | env / platform secrets |

> Secret values are NEVER documented. Only names and rotation policies are noted here.

## Per-Environment Overrides

> No evidence found for documented per-environment configuration differences in the available architecture inventory. Database URLs, broker addresses, and Redis connection details are expected to vary between development, staging, and production environments through injected environment variables.
