---
service: "jtier-oxygen"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumOxygenPostgres"
    type: "postgresql"
    purpose: "Primary relational store for greetings, broadcast metadata, and Quartz job persistence"
  - id: "continuumOxygenRedisCache"
    type: "redis"
    purpose: "Key-value cache backing the Redis test resource"
---

# Data Stores

## Overview

JTier Oxygen owns two data stores: a PostgreSQL database (via DaaS) for relational data and Quartz persistence, and a Redis instance (via RaaS) for key-value cache testing. Both stores are owned by the jtier-oxygen service. Postgres uses a master/slave replication strategy with backups enabled (per Owners Manual). Redis is used only for ephemeral test reads and writes.

## Stores

### Oxygen Postgres (`continuumOxygenPostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumOxygenPostgres` |
| Purpose | Stores greetings (name-to-greeting mappings), broadcast metadata (broadcast records and individual message tracking), and Quartz scheduler job/trigger state |
| Ownership | owned |
| Migrations path | `jtier-migrations` module (managed by JTier framework); Quartz schema via `jtier-quartz-postgres-migrations` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| greetings | Stores greeting text keyed by name | `key`, `value` |
| broadcasts | Tracks broadcast definitions and state | `id`, `name`, `numMessages`, `processingTimeMillis`, `maxIterations`, `startTime`, `endTime`, `running` |
| broadcast_messages | Tracks individual message records per broadcast | `id`, `messageRank`, `maxIteration`, `updatedAt` |
| Quartz tables | Scheduler job/trigger persistence (`EverywhereJob`, `ExclusiveJob`) | Standard Quartz schema |

#### Access Patterns

- **Read**: Greeting lookup by name; broadcast lookup by name or paginated ID range; broadcast stats aggregation; Quartz scheduler state reads on job execution
- **Write**: Greeting upsert on `POST /greetings`; broadcast record creation on `POST /broadcasts`; broadcast message iteration count update on each MessageBus roundtrip; Quartz trigger state updates on each scheduled job execution
- **Indexes**: Not directly visible in inventory; standard Quartz schema indexes apply

#### Connection Configuration (Production, us-central1)

- Host: `jtier-oxygen-rw-na-production-db.gds.prod.gcp.groupondev.com`
- Database: `oxygen_prod`
- Credentials: `${DAAS_APP_USERNAME}` / `${DAAS_APP_PASSWORD}` (app user); `${DAAS_DBA_USERNAME}` / `${DAAS_DBA_PASSWORD}` (DBA user)
- Pool: `transactionPoolSize: 7`, ports `5432` for all connection modes

#### Connection Configuration (Staging, us-central1)

- Host: `jtier-oxygen-rw-na-staging-db.gds.stable.gcp.groupondev.com`
- Database: `oxygen_stg`

### Oxygen Redis (`continuumOxygenRedisCache`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumOxygenRedisCache` |
| Purpose | Backing store for the Redis test resource (`POST /redis`, `GET /redis/{key}`) — stores arbitrary key-value pairs with optional TTL |
| Ownership | owned |
| Migrations path | Not applicable (schema-less) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Arbitrary keys | Test key-value storage with optional TTL | `key`, `value`, `ttlMilliseconds` |

#### Access Patterns

- **Read**: `GET /redis/{key}` retrieves a value by key
- **Write**: `POST /redis` stores a key-value pair; TTL in milliseconds is optional
- **Indexes**: Not applicable

#### Connection Configuration (Production, us-central1)

- Endpoint: `oxygen-memorystore.us-central1.caches.prod.gcp.groupondev.com:6379`
- SSL: disabled
- Pool: `maxTotal: 1924`, `minIdle: 0`, `maxIdle: 0`, `timeout: 2000ms`

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumOxygenRedisCache` | Redis | Test endpoint backing store for key-value reads and writes | Per-entry optional TTL via `ttlMilliseconds` field; no global TTL configured |

## Data Flows

- Postgres receives writes from `oxygenDataAccess` (JDBI3 DAO) on greeting creation/update and broadcast lifecycle events; reads flow back to the HTTP API and Broadcast Core
- Redis receives writes and reads directly from the HTTP Resources component via the Jedis bundle
- Quartz scheduler reads and writes its own persistence tables in the same Postgres database on every cron trigger cycle
- No CDC, ETL, or cross-store replication is configured; the two stores are independent
