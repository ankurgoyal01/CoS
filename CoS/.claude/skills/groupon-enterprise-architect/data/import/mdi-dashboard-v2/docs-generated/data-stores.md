---
service: "mdi-dashboard-v2"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "mdiDashboardPostgres"
    type: "postgresql"
    purpose: "Persists feed configurations and API key records"
---

# Data Stores

## Overview

mdi-dashboard-v2 owns a single PostgreSQL database used to persist feed configuration records and API key records. All database access is managed through the Sequelize ORM (v2.0.5). The dashboard does not use any caching layer; all other data (deals, taxonomy, merchant insights) is fetched live from upstream services.

## Stores

### MDI Dashboard PostgreSQL (`mdiDashboardPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `mdiDashboardPostgres` |
| Purpose | Stores feed configurations created by the feed builder and API keys issued to programmatic consumers |
| Ownership | owned |
| Migrations path | > No evidence found of a specific migrations directory in the inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `feeds` | Stores feed builder configurations defining deal selection criteria and output format | id, name, configuration (JSON), created_at, updated_at |
| `api_keys` | Stores issued API keys and associated metadata for programmatic access consumers | id, key, owner, created_at, revoked_at |

#### Access Patterns

- **Read**: Feed list and detail views read from the `feeds` table on dashboard page load and AJAX requests; API key list reads from the `api_keys` table.
- **Write**: Feed CRUD operations insert, update, and delete rows in the `feeds` table; API key creation inserts into `api_keys`; revocation performs a soft or hard delete on `api_keys`.
- **Indexes**: > No evidence found of specific index definitions in the inventory.

## Caches

> No caching layer is configured for this service. All non-persisted data is fetched live from upstream services on each request.

## Data Flows

Feed configuration data is created and managed entirely within this service's PostgreSQL database. When feed generation is triggered, the dashboard reads the feed configuration from PostgreSQL, constructs a request, and dispatches it to the `continuumMdsFeedService` for execution. No ETL, CDC, or replication patterns are in use.
