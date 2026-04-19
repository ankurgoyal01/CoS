---
service: "salesforce-cache"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumSalesforceCacheDatabase"
    type: "postgresql"
    purpose: "Primary cache of Salesforce objects and replication state"
  - id: "continuumSalesforceCacheRedis"
    type: "redis"
    purpose: "Cache and lookup store for API layer"
---

# Data Stores

## Overview

Salesforce Cache uses two data stores: a PostgreSQL database (the shared "reading-rainbow" database) as the primary cache for Salesforce objects and replication state, and a Redis instance for fast lookup and auth caching in the API layer. The Replication Worker owns all write operations to PostgreSQL; the API component is read-only against it.

## Stores

### Salesforce Cache Database (`continuumSalesforceCacheDatabase`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumSalesforceCacheDatabase` |
| Purpose | Stores cached Salesforce objects (e.g., Account, Opportunity, Task, RecordType) and replication configuration/state |
| Ownership | Shared — originally the Reading Rainbow database (`reading_rainbow` / `reading_rainbow_stg`) |
| Migrations path | `src/main/resources/db/` (Flyway-managed via `jtier-migrations`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `_object_config` | Controls which Salesforce objects are cached and whether caching is enabled | `object_name`, `sc_cacher_off`, `cacher_off` |
| `_clients` | Stores provisioned API client credentials | `client_id`, password hash |
| `<object_name>` (e.g., `Account`, `Opportunity`, `Task`, `RecordType`) | Cached Salesforce records per object type | `Id`, `SystemModstamp`, object-specific fields |
| `qrtz_fired_triggers` | Quartz scheduler state for replication job tracking | `job_name`, `prev_fire_time` |
| `qrtz_triggers` | Quartz trigger definitions | `job_name`, `prev_fire_time` |

#### Access Patterns

- **Read**: The API component (`salesforceCacheApi`) queries cached object tables using JDBI, applying parsed filter expressions and field projections. Reads are by object type with optional Salesforce ID lookup.
- **Write**: The Replication Worker (`salesforceCacheReplicationWorker`) writes new and updated Salesforce records for each configured object after each batch fetch. The unstaler job removes records that are no longer present in Salesforce.
- **Indexes**: Not directly visible from inventory; `SystemModstamp` is used as a high-water-mark column for incremental replication queries.

### Production Database Connection

| Environment | Host | Port | DB Name |
|-------------|------|------|---------|
| Production | `prod-read-rainbow-new-rw-vip.us.daas.grpn` | 15432 | `reading_rainbow` |
| Staging | `reading-rainbow-stg.ccoxqscq6x7v.us-west-1.rds.amazonaws.com` | 5432 | `reading_rainbow_stg` |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumSalesforceCacheRedis` | Redis | API-layer lookup cache and auth value storage | Not documented in inventory |

The Redis store (`continuumSalesforceCacheRedis`) is accessed by the `redisClient_SalCac` component within the API container. It is integrated via the `dropwizard-redis` library.

## Data Flows

1. The Replication Worker polls Salesforce via the `Read-only Salesforce Client` on a Quartz schedule.
2. Fetched records are batched by the `Salesforce Batch Iterator` and written to PostgreSQL by the `Salesforce Update Persister`.
3. The API reads from PostgreSQL (JDBI/PostgreSQL) and uses Redis for cached lookups.
4. Schema changes (adding/removing objects and fields) are managed via the `UpdateMaven` CLI migration tool, which generates Flyway migration files.
5. The unstaler job periodically removes stale records from the PostgreSQL cache that are no longer present in Salesforce.
