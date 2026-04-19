---
service: "etorch"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [config-files, app-config]
---

# Configuration

## Overview

eTorch uses AppConfig 1.8.0 as its primary configuration management library, reading configuration from files at startup. Connection details, credentials for downstream services, and job scheduling parameters are all managed through configuration. Per-environment overrides are applied at deployment time.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ETORCH_DB_URL` | JDBC connection URL for the eTorch relational database | yes | none | env / config |
| `ETORCH_DB_USER` | Database username | yes | none | env / config |
| `ETORCH_DB_PASSWORD` | Database password (secret) | yes | none | vault / env |
| `GETAWAYS_INVENTORY_BASE_URL` | Base URL for Getaways Inventory REST calls | yes | none | env / config |
| `GETAWAYS_CONTENT_BASE_URL` | Base URL for Getaways Content REST calls | yes | none | env / config |
| `LARC_BASE_URL` | Base URL for LARC REST calls | yes | none | env / config |
| `CHANNEL_MANAGER_SYNXIS_BASE_URL` | Base URL for Channel Manager Integrator (Synxis) | yes | none | env / config |
| `MX_MERCHANT_API_BASE_URL` | Base URL for MX Merchant API | yes | none | env / config |
| `ROCKETMAN_BASE_URL` | Base URL for Rocketman commercial notification service | yes | none | env / config |
| `NOTIFICATION_SERVICE_BASE_URL` | Base URL for Notification Service | yes | none | env / config |
| `DEAL_MANAGEMENT_API_BASE_URL` | Base URL for Deal Management API | yes | none | env / config |
| `ACCOUNTING_SERVICE_BASE_URL` | Base URL for Accounting Service | yes | none | env / config |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found for a feature flag system.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| AppConfig-managed config files | properties / YAML | Service-level configuration for database connections, downstream URLs, job schedules, and HTTP client timeouts — managed by AppConfig 1.8.0 |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Database password | Authenticates eTorch against its relational database | vault / env |
| Downstream service credentials | API keys or tokens for authenticated calls to Getaways Inventory, Accounting Service, MX Merchant API, and other dependents | vault / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

AppConfig supports environment-specific configuration profiles. Base URLs for all downstream services differ between development, staging, and production environments. Database connection strings and credentials are always environment-specific. Quartz job schedules may be suppressed or reduced in frequency in non-production environments to avoid side effects on shared data.
