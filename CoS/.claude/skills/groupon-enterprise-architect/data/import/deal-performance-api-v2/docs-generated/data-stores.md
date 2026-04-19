---
service: "deal-performance-api-v2"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumDealPerformancePostgres"
    type: "postgresql"
    purpose: "Pre-aggregated deal performance and attribute metrics — read-only by this service"
---

# Data Stores

## Overview

Deal Performance API V2 uses a single GDS-managed PostgreSQL instance as its data store. The service is read-only with respect to this database — all writes are performed by upstream data pipelines (`deal-performance-data-pipelines`). Two logical connection pools are maintained: a session/read-only replica connection (default) and an optional primary read-write connection (selected per-request via `shouldUsePrimaryDb=true`). Data backup is managed by the GDS team.

## Stores

### Deal Performance PostgreSQL (`continuumDealPerformancePostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumDealPerformancePostgres` |
| Purpose | Stores pre-aggregated deal performance, deal option performance, and deal attribute metrics |
| Ownership | Shared (GDS-managed, owned by data pipeline team) |
| Migrations path | > No evidence found in codebase — migrations managed by upstream pipeline repo |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deal_performance_daily` | Daily-bucketed event counts per deal, grouped by dimensions | `deal_id`, `time_bucket`, `event_type`, `count_type`, `count_value`, `platform`, `gender`, `brand`, `deal_option_id`, `purchaser_division_id`, `activation` |
| `deal_performance_hourly` | Hourly-bucketed event counts per deal, same schema as daily | `deal_id`, `time_bucket`, `event_type`, `count_type`, `count_value` |
| `deal_option_performance_daily` | Daily-bucketed purchases and activations per deal option | `deal_id`, `time_bucket`, `purchases_count`, `activations_count` |
| `deal_option_performance_hourly` | Hourly-bucketed purchases and activations per deal option | `deal_id`, `time_bucket`, `purchases_count`, `activations_count` |
| `deal_attribute_data_daily` | Daily deal attribute summary metrics (NOB, NOR, GR, GB, refunds, etc.) | `id`, `deal_id`, `date_value`, `brand`, plus metric columns |
| `deal_impressions_traffic_source` | Impression data broken down by traffic source, joined to attribute data | `id`, traffic source metric columns |

#### Access Patterns

- **Read**: All queries are parameterized by `deal_id` (UUID) and a `time_bucket` range (`fromTime` / `toTime`). Dynamic SQL is generated per request using StringTemplate4 templates to construct the appropriate `GROUP BY` clauses. The `deal_performance_*` tables are queried via a CTE unioning multiple metric sub-queries. The `deal_attribute_data_daily` table is queried with a LEFT JOIN to `deal_impressions_traffic_source`.
- **Write**: This service performs no writes. Data is loaded by upstream pipelines.
- **Indexes**: Not visible from application code. Index strategy is managed by the GDS database team.

#### Connection Configuration

| Environment | Host | Database |
|-------------|------|----------|
| Production | `deal-performance-service-v2-ro-na-production-db.gds.prod.gcp.groupondev.com` | `deal_perf_v2_prod` |
| Staging | `deal-performance-service-v2-rw-na-staging-db.gds.stable.gcp.groupondev.com` | `deal_perf_v2_stg` |
| Development | `localhost` | `postgres` |

Port `5432` is used for admin, session, and transaction connections across all environments.

## Caches

> No evidence found in codebase of an active cache configuration. The `caffeine` library (v3.0.3) is a declared dependency but no cache wiring is present in the application configuration.

## Data Flows

Data flows into the PostgreSQL database from external upstream pipelines (tracked in `deal-performance-data-pipelines`). This service reads exclusively; no CDC, ETL, or replication is managed by this service. The GDS team handles database backups and replication between the read-write primary and read-only replicas.
