---
service: "gpn-data-api"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumGpnDataApiMySql"
    type: "mysql"
    purpose: "Stores per-day query count limits and daily usage tracking"
  - id: "bigQuery_prj-grp-dataview-prod-1ff9"
    type: "bigquery"
    purpose: "Source of marketing attribution and unit economics data"
---

# Data Stores

## Overview

GPN Data API owns one MySQL database for operational rate-limiting state and reads from a shared Google BigQuery project for attribution analytics data. MySQL is the only store the service writes to. BigQuery is read-only and owned externally by data engineering.

## Stores

### GPN Data API MySQL (`continuumGpnDataApiMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumGpnDataApiMySql` |
| Purpose | Tracks the number of attribution queries executed per calendar day and stores the configurable daily query limit |
| Ownership | owned |
| Migrations path | Managed via `com.groupon.jtier:jtier-migrations` (5.8.0) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `attribution_query_count` | Records query count per calendar day | `query_date` (date, PK), `query_count` (int — increments on each API call via upsert) |
| `attribution_properties` | Stores named configuration values | `property_name` (PK), `property_value` — the row with `property_name = 'attribution_teradata'` holds the maximum queries per day |

#### Access Patterns

- **Read**: `SELECT property_value FROM attribution_properties WHERE property_name = 'attribution_teradata'` — fetches the daily query cap on every API call.
- **Read**: `SELECT query_count FROM attribution_query_count WHERE query_date = :operationDate` — fetches today's accumulated query count.
- **Write**: `INSERT INTO attribution_query_count(query_date, query_count) VALUES (:operationDate, 1) ON DUPLICATE KEY UPDATE query_count = query_count + 1` — upserts the daily count before each query is executed.
- **Indexes**: Primary key on `query_date` in `attribution_query_count`; primary key on `property_name` in `attribution_properties`.

---

### Google BigQuery — `prj-grp-dataview-prod-1ff9` (external)

| Property | Value |
|----------|-------|
| Type | bigquery |
| Architecture ref | `bigQuery_unk_a1b2` (stub in local model) |
| Purpose | Provides marketing attribution and unit economics data for order attribution lookups |
| Ownership | external (data engineering team) |
| Migrations path | Not applicable — read-only |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `` `prj-grp-dataview-prod-1ff9`.marketing.order_attribution_part `` | Order-level attribution records (UTM data, traffic source) | `order_id`, `country_id`, `attribution_type`, `event_date`, `utm_medium`, `utm_source`, `utm_campaign`, `traffic_source`, `traffic_sub_source`, `full_url` |
| `` `prj-grp-dataview-prod-1ff9`.finance_unit_economics.unit_economics `` | Per-unit financial transaction data | `order_id_original`, `feature_country_id`, `inventory_unit_uuid`, `last_status`, `cash_payment_amount`, `groupon_bucks_exchange_payment_amount`, `event_date`, `deal_uuid`, `sub_platform`, `unit_price`, `incentive_promo_code`, `order_created_at` |
| `` `prj-grp-dataview-prod-1ff9`.marketing.parent_orders `` | Maps parent order UUID to support ID | `uuid`, `support_id_original` |

#### Access Patterns

- **Read**: Parameterized SELECT JOIN across three tables with `WHERE attribution_type = '3.3'` and `last_status IN ('refund','capture','cancel','chargeback')`.
- **Write**: None — the service is read-only against BigQuery.
- **Indexes**: BigQuery partitioned/clustered table structure managed externally; queries filter on `event_date` range to leverage partitioning.

## Caches

> No evidence found in codebase. No caching layer is used. BigQuery results are not cached locally.

## Data Flows

Attribution query results flow entirely in memory within a single request lifecycle:

1. The service receives a REST request with order IDs and a date range.
2. The `AttributionDetailsService` splits large order ID lists into batches of up to 1,000 IDs.
3. Each batch triggers a parameterized BigQuery query; results are returned as `TableResult` objects.
4. Rows are mapped in-memory to `AttributionDetailsDto` objects and returned as JSON or CSV in the HTTP response.

No ETL, CDC, or replication pipelines are owned by this service.
