---
service: "mls-rin"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "mlsRinDealIndexDb"
    type: "postgresql"
    purpose: "Deal index read model"
  - id: "mlsRinHistoryDb"
    type: "postgresql"
    purpose: "History events read model"
  - id: "mlsRinMetricsDb"
    type: "postgresql"
    purpose: "Metrics and lifecycle analytics read model"
  - id: "mlsRinUnitIndexDb"
    type: "postgresql"
    purpose: "Unit search and counts read model"
  - id: "mlsRinYangDb"
    type: "postgresql"
    purpose: "Merchant risk and yang-module queries (optional)"
---

# Data Stores

## Overview

MLS RIN uses five purpose-built PostgreSQL read models. All databases are read-only from the perspective of this service — data is written by MLS Yang and pipeline components that feed these stores. Connection management is handled through the JTier DaaS PostgreSQL module (`jtier-daas-postgres`), and all query access is through JDBI3 DAOs. The Yang DB is optional and conditionally enabled via configuration. MLS RIN does not use any caching layer.

## Stores

### MLS RIN Deal Index DB (`mlsRinDealIndexDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `mlsRinDealIndexDb` |
| Purpose | Stores the deal index — a read-optimized projection of active and historical deals for a merchant, including deal metadata, counts, status, and inventory service associations |
| Ownership | shared (written by MLS Yang pipeline, read by MLS RIN) |
| Migrations path | Managed via `mls-db-schemas` artifact (test dependency); Flyway used in test scope |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal index records | Queryable deal state indexed by merchant, deal ID, status, and inventory service | merchant_id, deal_id, deal_status, inventory_service, launched_at |

#### Access Patterns

- **Read**: Query by merchant_id (one or many), deal_ids, deal_status filters, inventory_service filters; supports sorting (launched_at, random) and pagination
- **Write**: Not performed by this service
- **Indexes**: Schema managed externally via `mls-db-schemas`

---

### MLS RIN History DB (`mlsRinHistoryDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `mlsRinHistoryDb` |
| Purpose | Stores history events recording state changes and lifecycle actions for merchants, deals, and users |
| Ownership | shared (written by MLS pipeline, read by MLS RIN) |
| Migrations path | Managed via `mls-db-schemas` artifact |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| History events | Audit trail of lifecycle events | event_type, user_type, user_id, merchant_id, deal_id, occurred_at |

#### Access Patterns

- **Read**: Query by event_type, user_type, user_id, merchant_id, deal_id, date range; supports pagination and rendered_for context
- **Write**: Not performed by this service
- **Indexes**: Schema managed externally via `mls-db-schemas`

---

### MLS RIN Metrics DB (`mlsRinMetricsDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `mlsRinMetricsDb` |
| Purpose | Stores aggregated marketing metrics (impressions, clicks, shares, referrals) by channel for deals, enabling time-series analytics |
| Ownership | shared (written by metrics pipeline, read by MLS RIN) |
| Migrations path | Managed via `mls-db-schemas` artifact |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Metrics records | Channel-specific metric events for deals | deal_id, type (EMAIL_CLICKS, WEB_IMPRESSIONS, MOBILE_CLICKS, etc.), aggregate_by, date |

#### Access Patterns

- **Read**: Query by deal_ids (required), type (multi-value enum), aggregate_by (DAILY/WEEKLY/MONTHLY/YEARLY/COMPLETE), date range; configured batch read size and cutoff days via `metricsConfig` / `MetricsConfiguration`
- **Write**: Not performed by this service
- **Indexes**: Schema managed externally via `mls-db-schemas`

---

### MLS RIN Unit Index DB (`mlsRinUnitIndexDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `mlsRinUnitIndexDb` |
| Purpose | Stores a local cache / aggregation of unit-level sold counts and index data used as a fast alternative to calling inventory services directly |
| Ownership | shared (written by MLS pipeline, read by MLS RIN) |
| Migrations path | Managed via `mls-db-schemas` artifact |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Unit index records | Pre-aggregated unit sold counts per inventory service | unit_id, inventory_service, sold_count, merchant_id |

#### Access Patterns

- **Read**: Used when `CountStyle.aggregateViaLocalCache` is configured for a given inventory service; provides fast sold count lookups without calling FIS
- **Write**: Not performed by this service
- **Indexes**: Schema managed externally via `mls-db-schemas`

---

### MLS RIN Yang DB (`mlsRinYangDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `mlsRinYangDb` |
| Purpose | Optional datastore for merchant risk and yang-module queries; enables merchant risk retrieval when configured |
| Ownership | shared (written by MLS Yang, read by MLS RIN) |
| Migrations path | Managed via `mls-db-schemas` artifact |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Merchant risk records | Risk status and threshold data per merchant | merchant_id, risk_level, refunded_percentage, recommended_percentage |

#### Access Patterns

- **Read**: Queried by merchant_id when the Yang DB is enabled (`Optional<PostgresConfig> yangConfig()`); `MerchantRiskConfiguration` configures min/max thresholds
- **Write**: Not performed by this service
- **Indexes**: Schema managed externally via `mls-db-schemas`

## Caches

MLS RIN does not use any caching layer. The `OWNERS_MANUAL.md` explicitly states: "MLS RIN does not use any caching." While `hk2-di-caching` is present as a library dependency (and `CacheConfiguration` is present in the config class), no active cache is documented as in use.

## Data Flows

Data flows into the MLS RIN read models exclusively from MLS write-side pipeline components (MLS Yang, MANA pipeline, metrics pipeline). MLS RIN does not perform any ETL or replication; it consumes pre-populated read models. For unit data that is not locally cached, MLS RIN fans out to federated inventory services (VIS, GLive, Getaways) at request time via HTTP using the FIS client.
