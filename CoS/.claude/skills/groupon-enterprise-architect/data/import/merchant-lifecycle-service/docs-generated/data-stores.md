---
service: "merchant-lifecycle-service"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "mlsDealIndexPostgres"
    type: "postgresql"
    purpose: "Deal index snapshot and deal query state"
  - id: "historyServicePostgres"
    type: "postgresql"
    purpose: "History event reads and writes"
  - id: "metricsPostgres"
    type: "postgresql"
    purpose: "Metrics and lifecycle analytics aggregates"
  - id: "unitIndexPostgres"
    type: "postgresql"
    purpose: "Unit search state, counts, and inventory index records"
  - id: "yangPostgres"
    type: "postgresql"
    purpose: "Merchant risk and yang-module queries (optional)"
---

# Data Stores

## Overview

Merchant Lifecycle Service owns five PostgreSQL databases accessed via JDBI 3. All databases are read-heavy from `continuumMlsRinService` and written primarily by `continuumMlsSentinelService` as Kafka events are processed. There is no caching layer evidenced in the architecture inventory — reads are served directly from the materialized PostgreSQL stores.

## Stores

### MLS Deal Index DB (`mlsDealIndexPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `mlsDealIndexPostgres` |
| Purpose | Stores deal index snapshots and the current state of deal queries |
| Ownership | owned |
| Migrations path | Not evidenced in architecture inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| deal index records | Materialized deal state for query | deal UUID, snapshot version, deal state, update timestamp |
| inventory product records | FIS inventory product index entries | product UUID, unit state, inventory source ID |

#### Access Patterns

- **Read**: `continuumMlsRinService` queries deal index data via `rinDataAccess` (JDBI) for deal detail and search endpoints
- **Write**: `continuumMlsSentinelService` upserts deal snapshots and inventory product records via `sentinelPersistence` (JDBI) on Kafka event receipt
- **Indexes**: Not evidenced in architecture inventory

---

### History Service DB (`historyServicePostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `historyServicePostgres` |
| Purpose | Stores history events for the `GET /history` endpoint and Sentinel event auditing |
| Ownership | owned |
| Migrations path | Not evidenced in architecture inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| history events | Deal and inventory lifecycle event log | event type, merchant UUID, deal UUID, event timestamp |

#### Access Patterns

- **Read**: `continuumMlsRinService` retrieves history events via `rinHistoryDomain` -> `rinDataAccess`
- **Write**: `continuumMlsSentinelService` writes history events via `sentinelPersistence` during flow processing
- **Indexes**: Not evidenced in architecture inventory

---

### Metrics DB (`metricsPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `metricsPostgres` |
| Purpose | Stores metrics aggregates and lifecycle analytics data |
| Ownership | owned |
| Migrations path | Not evidenced in architecture inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| metrics aggregates | Pre-computed performance and lifecycle metrics | merchant UUID, metric type, period, value |

#### Access Patterns

- **Read**: `continuumMlsRinService` reads metrics via `rinMetricsDomain` -> `rinDataAccess` for performance and analytics endpoints
- **Write**: Not evidenced in architecture inventory for this store specifically — write path to be confirmed by service owner
- **Indexes**: Not evidenced in architecture inventory

---

### Unit Index DB (`unitIndexPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `unitIndexPostgres` |
| Purpose | Stores unit search state, unit counts, and inventory index records |
| Ownership | owned |
| Migrations path | Not evidenced in architecture inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| unit index records | Materialized unit search state | inventory source ID, unit UUID, unit state, indexed timestamp |
| unit counts | Pre-aggregated unit counts per context | context key, count value, last updated |

#### Access Patterns

- **Read**: `continuumMlsRinService` queries unit data via `rinUnitSearchDomain` -> `rinDataAccess` for search and count endpoints
- **Write**: `continuumMlsSentinelService` writes and updates unit state via `sentinelPersistence` on inventory update events
- **Indexes**: Not evidenced in architecture inventory

---

### Yang DB (`yangPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `yangPostgres` |
| Purpose | Optional store for merchant risk scores and yang-module queries |
| Ownership | owned |
| Migrations path | Not evidenced in architecture inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| merchant risk records | Merchant risk scores and threshold data | merchant UUID, risk score, threshold, evaluated timestamp |

#### Access Patterns

- **Read**: `continuumMlsRinService` reads merchant risk data via `rinRiskDomain` -> `rinDataAccess` when the yang module is enabled
- **Write**: Not evidenced in architecture inventory — write path to be confirmed by service owner
- **Indexes**: Not evidenced in architecture inventory

## Caches

> No evidence found — no caching layer is evidenced in the architecture inventory. All reads are served directly from PostgreSQL.

## Data Flows

- Deal catalog events consumed by `continuumMlsSentinelService` drive upserts into `mlsDealIndexPostgres`, creating the materialized read model served by `continuumMlsRinService`.
- Inventory update events consumed by `continuumMlsSentinelService` drive writes into `unitIndexPostgres`, maintaining the unit search index.
- History events written by `continuumMlsSentinelService` are subsequently read by `continuumMlsRinService` for the history endpoint.
- `metricsPostgres` and `yangPostgres` serve pre-aggregated or supplemental data to enrichment flows within `continuumMlsRinService`.
