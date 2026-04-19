---
service: "merchant-lifecycle-service"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

Merchant Lifecycle Service follows the Dropwizard/JTier configuration pattern: a YAML configuration file is loaded at startup, with environment-specific values injected via environment variables or JTier-managed config bundles. Database connections, Kafka broker addresses, and external service URLs are the primary configuration concerns.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `POSTGRES_MLS_DEAL_INDEX_URL` | JDBC URL for `mlsDealIndexPostgres` | yes | — | env / JTier DaaS bundle |
| `POSTGRES_HISTORY_SERVICE_URL` | JDBC URL for `historyServicePostgres` | yes | — | env / JTier DaaS bundle |
| `POSTGRES_METRICS_URL` | JDBC URL for `metricsPostgres` | yes | — | env / JTier DaaS bundle |
| `POSTGRES_UNIT_INDEX_URL` | JDBC URL for `unitIndexPostgres` | yes | — | env / JTier DaaS bundle |
| `POSTGRES_YANG_URL` | JDBC URL for `yangPostgres` | no | — | env / JTier DaaS bundle |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker addresses for MBus/Kafka consumers and producers | yes | — | env / JTier MessageBus bundle |
| `FIS_CLIENT_BASE_URL` | Base URL for FIS (TPIS/Goods/Voucher) client | yes | — | env / fis-client config |
| `DEAL_CATALOG_BASE_URL` | Base URL for `continuumDealCatalogService` | yes | — | env / Retrofit config |
| `VIS_BASE_URL` | Base URL for `continuumVoucherInventoryService` | yes | — | env / Retrofit config |
| `M3_MERCHANT_BASE_URL` | Base URL for `continuumM3MerchantService` | yes | — | env / Retrofit config |
| `JTIER_AUTH_TOKEN` | JTier authentication credentials for inbound and outbound auth | yes | — | vault / JTier auth bundle |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `yang.module.enabled` | Enables merchant risk queries against `yangPostgres` | false | per-deployment |

> Additional feature flags are not evidenced in the architecture inventory. Flag inventory to be confirmed by service owner.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | yaml | Primary Dropwizard application configuration (server, database, messaging, clients) |
| `config-{env}.yml` | yaml | Per-environment overrides for dev, staging, and production |

> Exact file paths within the service repository to be confirmed by service owner.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `mls-postgres-credentials` | PostgreSQL usernames and passwords for all five databases | vault |
| `kafka-credentials` | Kafka client credentials for MBus/Kafka | vault |
| `fis-client-credentials` | FIS client authentication credentials | vault |
| `jtier-auth-credentials` | JTier platform auth token | vault |

> Secret values are NEVER documented. Only names and rotation policies are listed here. Rotation policies to be confirmed by service owner.

## Per-Environment Overrides

- **Development**: Local Postgres instances, local Kafka, FIS and downstream services pointed at dev/staging endpoints
- **Staging**: Staging Postgres cluster, staging Kafka, staging instances of all downstream services
- **Production**: Production Postgres cluster, production Kafka, production instances of all downstream services; `yang.module.enabled` configuration as determined by rollout state

> Specific per-environment values are managed in JTier/Vault configuration stores and are not documented here.
