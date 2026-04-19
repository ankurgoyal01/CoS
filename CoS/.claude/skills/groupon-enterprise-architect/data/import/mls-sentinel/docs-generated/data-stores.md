---
service: "mls-sentinel"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "mlsSentinelDealIndexDb"
    type: "postgresql"
    purpose: "Deal snapshots and inventory product index state"
  - id: "mlsSentinelHistoryDb"
    type: "postgresql"
    purpose: "Merchant history event persistence"
  - id: "mlsSentinelUnitIndexDb"
    type: "postgresql"
    purpose: "Inventory unit index state"
---

# Data Stores

## Overview

MLS Sentinel owns three PostgreSQL databases, each managed via the JTier DaaS-Postgres connection pool (`jtier-daas-postgres`) and accessed through JDBI3 DAOs (`jtier-jdbi`, `hk2-di-jdbi3`). Schema migrations are provided by the shared `mls-db-schemas` artifact (applied via Flyway in test scope). No caching layer is used — the OWNERS_MANUAL explicitly states that MLS Sentinel does not use any caching.

## Stores

### Deal Index DB (`mlsSentinelDealIndexDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `mlsSentinelDealIndexDb` |
| Purpose | Stores deal snapshots and inventory product index state; used during inventory update and backfill flows to track the current known state of each deal/inventory product |
| Ownership | owned |
| Migrations path | `mls-db-schemas` (shared artifact, applied via Flyway) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal snapshot / inventory product index | Tracks the current indexed state of deals and inventory products for update flow coordination | Deal ID / inventory product ID, snapshot timestamp, index state |

#### Access Patterns

- **Read**: Queries current deal/inventory product state before deciding whether to emit a Kafka Command; used in inventory update and backfill flows
- **Write**: Upserts deal snapshot records when Sentinel processes inventory product updates from MessageBus or backfill triggers
- **Indexes**: Not directly visible from the codebase; managed by `mls-db-schemas` Flyway migrations

---

### History DB (`mlsSentinelHistoryDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `mlsSentinelHistoryDb` |
| Purpose | Persists merchant history events written via the `/v1/history` API and MBus history event processors, when `saveHistoryEventInHistoryService` is enabled |
| Ownership | owned |
| Migrations path | `mls-db-schemas` (shared artifact, applied via Flyway) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| History event | Records individual merchant lifecycle history events | historyId (UUID), merchantId (UUID), dealId (UUID), userId (UUID), eventType, eventDate, historyData (JSONB) |

#### Access Patterns

- **Read**: Queried to support DLQ retry flows and history event deduplication checks
- **Write**: Inserts new history event records on each `/v1/history` POST or relevant MBus event, conditional on the `saveHistoryEventInHistoryService` configuration flag
- **Indexes**: Not directly visible; managed by `mls-db-schemas`

---

### Unit Index DB (`mlsSentinelUnitIndexDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `mlsSentinelUnitIndexDb` |
| Purpose | Stores inventory unit index state; used in unit-level update flows to track processed unit state |
| Ownership | owned |
| Migrations path | `mls-db-schemas` (shared artifact, applied via Flyway) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Inventory unit index | Tracks processed state for each inventory unit | Unit ID, index state, timestamp |

#### Access Patterns

- **Read**: Checks current unit state before deciding whether to emit an updated Kafka Command
- **Write**: Upserts unit records when processing unit update events
- **Indexes**: Not directly visible; managed by `mls-db-schemas`

---

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| — | — | — | — |

MLS Sentinel does not use any caching layer. This is explicitly stated in the OWNERS_MANUAL.

## Data Flows

- All three databases receive writes from the Flow Processing Layer (`mlsSentinel_processingFlows`) via the Persistence Layer (`mlsSentinel_persistence`).
- The databases are accessed exclusively by the `continuumMlsSentinelService` instance — no other service writes to or reads from these stores directly.
- Inbound data originates from upstream MBus events; outbound data (validated commands) flows to Kafka topics, not back to databases.
- Schema migrations (`mls-db-schemas`) are applied as part of the deployment lifecycle using Flyway.
