---
service: "tpis-inventory-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: []
---

# Configuration

## Overview

Configuration details for the Third Party Inventory Service are not discoverable from the architecture DSL alone. As a Java microservice in the Continuum platform, it is expected to follow standard Continuum configuration patterns including environment variables, application properties, and externalized secrets.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_HOST` | MySQL database host for TPIS inventory DB | yes (inferred) | -- | env |
| `DB_PORT` | MySQL database port | yes (inferred) | 3306 | env |
| `DB_NAME` | Database name | yes (inferred) | -- | env |
| `DB_USERNAME` | Database username | yes (inferred) | -- | env / vault |
| `DB_PASSWORD` | Database password | yes (inferred) | -- | vault |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes. The variables above are inferred from standard Java/MySQL patterns and should be verified by the service owner.

## Feature Flags

No feature flags are discoverable from the architecture DSL.

> Service owners should document any feature flags used by TPIS.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| (inferred) application.properties / application.yml | properties / yaml | Main application configuration |

> Exact config file paths are not discoverable from the architecture DSL. Service owners should document the actual configuration files.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| DB credentials | MySQL database authentication | vault (inferred) |
| Partner API credentials | Authentication with third-party inventory partner systems | vault (inferred) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Environment-specific configuration (dev, staging, production) is not discoverable from the architecture DSL. Service owners should document how configuration differs between environments.
