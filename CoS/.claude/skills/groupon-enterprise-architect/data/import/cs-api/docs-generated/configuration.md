---
service: "cs-api"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

CS API is a Dropwizard / JTier service and follows the standard JTier configuration pattern: a YAML configuration file provides the primary configuration, with environment-specific overrides applied via environment variables or JTier platform configuration injection. Secrets (database passwords, Redis credentials, external API keys) are injected at runtime and are never stored in source control.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | JDBC connection string for `csApiMysql` primary | yes | none | env / platform |
| `DATABASE_RO_URL` | JDBC connection string for `csApiRoMysql` read replica | yes | none | env / platform |
| `DATABASE_PASSWORD` | Password for MySQL primary connection | yes | none | env / vault |
| `REDIS_URL` | Connection URL for `csApiRedis` | yes | none | env / platform |
| `CS_REDIS_CACHE_URL` | Connection URL for `continuumCsRedisCache` | yes | none | env / platform |
| `ZENDESK_BASE_URL` | Zendesk API base URL | yes | none | env / platform |
| `ZENDESK_API_TOKEN` | Zendesk API authentication token | yes | none | env / vault |
| `SALESFORCE_BASE_URL` | Salesforce API base URL | yes | none | env / platform |
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth2 client ID | yes | none | env / vault |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth2 client secret | yes | none | env / vault |
| `CS_TOKEN_SERVICE_URL` | Base URL for `continuumCsTokenService` | yes | none | env / platform |
| `JWT_SECRET` | Secret used for JJWT signing and validation | yes | none | env / vault |

> IMPORTANT: Actual secret values are never documented. Only variable names and purposes are shown above.

> The exact variable names above are inferred from standard JTier / Dropwizard conventions and the services identified in the architecture model. Confirm precise names with the service owner (GSO Engineering / nsanjeevi).

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| > No evidence found | Feature flags are stored in the `features` MySQL table and served via the `/features` endpoint | — | per-agent |

> Feature flag configuration is managed at runtime through the `/features` API rather than through static environment variables. The `features` table in `csApiMysql` holds flag state.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | yaml | Primary Dropwizard application configuration (server, database pool, Redis, logging) |
| `config-<env>.yml` | yaml | Per-environment override files (dev, staging, production) |

> Exact config file paths are not captured in the architecture DSL inventory. Standard Dropwizard / JTier conventions apply.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| MySQL primary password | Authentication to `csApiMysql` | vault / platform secrets |
| Redis password / auth token | Authentication to `csApiRedis` and `continuumCsRedisCache` | vault / platform secrets |
| Zendesk API token | Authentication to Zendesk REST API | vault / platform secrets |
| Salesforce client secret | OAuth2 credential for Salesforce API | vault / platform secrets |
| JWT signing secret | Signs and validates agent JWT tokens via JJWT | vault / platform secrets |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Local MySQL and Redis instances; Zendesk and Salesforce sandbox endpoints configured
- **Staging**: Shared staging MySQL replicas; Zendesk sandbox; Salesforce QA sandbox (`salesforceQaSandbox`)
- **Production**: Production MySQL cluster with read replica; production Zendesk and Salesforce endpoints; Redis cluster
