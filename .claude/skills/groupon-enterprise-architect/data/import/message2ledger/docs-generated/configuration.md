---
service: "message2ledger"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

message2ledger is a JTier/Dropwizard service and follows the standard JTier configuration pattern: primary configuration is supplied via YAML config file at startup (Dropwizard convention), with environment-specific values provided through environment variables or JTier platform config injection. Database credentials, MBus connection details, and downstream service endpoints are the critical runtime configuration items.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | JDBC connection URL for message2ledger MySQL | yes | none | env / JTier platform |
| `DATABASE_USER` | MySQL username | yes | none | env / JTier platform |
| `DATABASE_PASSWORD` | MySQL password — secret value never documented | yes | none | vault / JTier platform |
| `MBUS_BROKER_URL` | JMS broker URL for MBus subscription | yes | none | env / JTier platform |
| `MBUS_USERNAME` | MBus authentication username | yes | none | env / JTier platform |
| `MBUS_PASSWORD` | MBus authentication password — secret value never documented | yes | none | vault / JTier platform |
| `ACCOUNTING_SERVICE_BASE_URL` | Base URL for the Accounting Service HTTP API | yes | none | env / JTier platform |
| `VIS_BASE_URL` | Base URL for continuumVoucherInventoryApi | yes | none | env / JTier platform |
| `TPIS_BASE_URL` | Base URL for continuumThirdPartyInventoryService | yes | none | env / JTier platform |
| `ORDERS_SERVICE_BASE_URL` | Base URL for continuumOrdersService | yes | none | env / JTier platform |
| `EDW_JDBC_URL` | JDBC connection URL for EDW reconciliation queries | yes | none | env / JTier platform |
| `EDW_USERNAME` | EDW database username | yes | none | env / JTier platform |
| `EDW_PASSWORD` | EDW database password — secret value never documented | yes | none | vault / JTier platform |

> IMPORTANT: Secret values are never documented. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found for runtime feature flags in the architecture sources. Feature flag configuration to be confirmed in the service repository.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` (Dropwizard convention) | YAML | Primary Dropwizard application configuration: server ports, database pool settings, MBus subscription config, retry policy, Quartz scheduler settings |
| Flyway migration scripts | SQL | Database schema version management under the Flyway migrations directory |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_PASSWORD` | message2ledger MySQL authentication | vault / JTier platform secrets |
| `MBUS_PASSWORD` | MBus broker authentication | vault / JTier platform secrets |
| `EDW_PASSWORD` | EDW JDBC authentication | vault / JTier platform secrets |

> Secret values are NEVER documented. Only names and rotation policies are listed. Rotation policies to be defined by service owner.

## Per-Environment Overrides

JTier services typically maintain separate config profiles for `dev`, `staging` (itier), and `production` environments. Key differences across environments:

- **dev / local**: Local or stubbed MySQL instance; MBus may be pointed at a development broker or disabled; downstream service URLs point to local/mock endpoints
- **staging (itier)**: Full integration with staging instances of Accounting Service, VIS, TPIS, Orders Service, and EDW; uses staging MBus topics
- **production**: Live NA and EMEA MBus topic subscriptions; production Accounting Service, VIS, TPIS, Orders Service, and EDW endpoints; production MySQL with full data retention
