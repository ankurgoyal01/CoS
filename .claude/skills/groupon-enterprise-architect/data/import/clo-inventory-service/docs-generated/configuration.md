---
service: "clo-inventory-service"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars, jtier-service-discovery]
---

# Configuration

## Overview

CLO Inventory Service is configured via Dropwizard YAML configuration files following JTIER/IS-Core conventions. Service dependencies, database connections, Redis cache settings, and external HTTP client configurations are wired through `CloServiceConfiguration` and the bootstrap classes (`CloServiceApplication`, `ServiceDependencies`, `CloServiceLocator`, `ClientLocator`). Environment-specific overrides are managed through JTIER deployment infrastructure.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_ENV` | JTIER environment identifier (staging, production) | Yes | — | env |
| `DB_HOST` | PostgreSQL database host | Yes | — | env / JTIER DaaS |
| `DB_PORT` | PostgreSQL database port | Yes | 5432 | env / JTIER DaaS |
| `DB_NAME` | PostgreSQL database name | Yes | — | env / JTIER DaaS |
| `DB_USERNAME` | PostgreSQL database username | Yes | — | env / JTIER DaaS |
| `DB_PASSWORD` | PostgreSQL database password | Yes | — | env / JTIER DaaS |
| `REDIS_HOST` | Redis cache host | Yes | — | env / JTIER Cache |
| `REDIS_PORT` | Redis cache port | Yes | 6379 | env / JTIER Cache |
| `SERVICE_PORT` | HTTP server port | No | 8080 | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Pricing configuration | Controls dynamic pricing behavior for CLO products | Service-level default | per-environment |
| Cache enablement | Controls whether Redis and in-memory caching is active | Enabled | per-environment |
| Consent module | Controls consent API availability | Enabled | global |

> Feature flag names and exact configuration are managed within the service's configuration files. Service owners should document specific flags as they are added.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | YAML | Main Dropwizard configuration: server settings, database, Redis, logging |
| `config-{env}.yml` | YAML | Per-environment overrides for staging, production, etc. |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | PostgreSQL database credentials | JTIER DaaS / environment |
| `REDIS_AUTH` | Redis authentication token (if required) | JTIER Cache / environment |
| Service-to-service credentials | JTIER authentication tokens for downstream HTTP clients | JTIER platform |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Configuration differs between environments following JTIER conventions:

- **Development/Local**: Local PostgreSQL and Redis instances; mock or local downstream services; debug logging enabled
- **Staging**: JTIER DaaS staging PostgreSQL; JTIER staging Redis; staging endpoints for CLO Core Service, Card Interaction Service, Deal Catalog, M3 Merchant, and M3 Places; standard logging
- **Production**: JTIER DaaS production PostgreSQL with connection pooling; JTIER production Redis cluster; production endpoints for all downstream services; production logging levels; metrics and health checks active
