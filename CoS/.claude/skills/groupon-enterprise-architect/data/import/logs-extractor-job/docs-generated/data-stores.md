---
service: "logs-extractor-job"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumLogExtractorElasticsearch"
    type: "elasticsearch"
    purpose: "Source of raw operational logs"
  - id: "continuumLogExtractorBigQuery"
    type: "bigquery"
    purpose: "Primary analytical sink for transformed log datasets"
  - id: "continuumLogExtractorMySQL"
    type: "mysql"
    purpose: "Optional operational relational sink for extracted logs"
---

# Data Stores

## Overview

The Log Extractor Job interacts with three data stores. Elasticsearch is a read-only source; the job pulls raw logs from it via the `@groupon/logs-processor` SDK. Google BigQuery is the primary write destination — tables are created automatically and logs are loaded in day-partitioned batches. MySQL is an optional secondary write destination used for operational reporting; it is disabled in both staging and production by default.

## Stores

### Source Elasticsearch Cluster (`continuumLogExtractorElasticsearch`)

| Property | Value |
|----------|-------|
| Type | Elasticsearch |
| Architecture ref | `continuumLogExtractorElasticsearch` |
| Purpose | Source of raw PWA, proxy (api_proxy), Lazlo, and orders log documents |
| Ownership | external (managed by Groupon logging infrastructure) |
| Migrations path | Not applicable (read-only) |

#### Key Entities

| Index / Log Type | Purpose | Key Fields |
|-----------------|---------|-----------|
| PWA logs | Application-level user interaction and error events from the MBNXT PWA | `@timestamp`, `bcookie`, `ccookie`, `message`, `cat`, `name`, `platform`, `errorCode`, `requestId` |
| Proxy logs | HTTP proxy (api_proxy) request logs | `@timestamp`, `requestId`, `bcookie`, `status`, `route`, `path`, `method`, `errorMessage` |
| Lazlo logs | Legacy backend routing logs | `@timestamp`, `requestId`, `path`, `statusCode`, `name`, `legacyMethod`, `action`, `clientName` |
| Orders logs | Order service request and error logs | `@timestamp`, `b_cookie`, `http_request_id`, `httpStatus`, `endpoints`, `error_codes`, `error_messages_array` |

#### Access Patterns

- **Read**: Time-range queries via `extractLogsForTimeRangeExact` from `@groupon/logs-processor`; supports scroll/time-based pagination internally
- **Write**: Not applicable — job is read-only against Elasticsearch
- **Indexes**: Managed by the Elasticsearch cluster owner; not defined in this repo

---

### Log Extractor BigQuery Dataset (`continuumLogExtractorBigQuery`)

| Property | Value |
|----------|-------|
| Type | BigQuery |
| Architecture ref | `continuumLogExtractorBigQuery` |
| Purpose | Analytical store for transformed log datasets, partitioned by day |
| Ownership | owned |
| Migrations path | Not applicable — tables created automatically via `bigQueryService.ensureAllTablesExist()` |

#### Key Entities

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| `pwa_logs` | PWA application and error events | `timestamp` (REQUIRED), `bcookie`, `ccookie`, `requestId`, `message`, `cat`, `name`, `platform`, `errorCode`, `isGuest`, `paymentMethod`, `cartData` (JSON), `data` (JSON), `extraction_timestamp` |
| `proxy_logs` | HTTP proxy request records | `timestamp` (REQUIRED), `requestId`, `bcookie`, `status` (INTEGER), `route`, `path`, `method`, `errorMessage`, `extraction_timestamp` |
| `lazlo_logs` | Legacy backend routing records | `timestamp` (REQUIRED), `requestId`, `path`, `statusCode`, `name`, `legacyMethod`, `action`, `clientName`, `extraction_timestamp` |
| `orders_logs` | Order service request records | `timestamp` (REQUIRED), `bcookie`, `requestId`, `statusCode` (INTEGER), `endpoint`, `errorCodes` (REPEATED), `errorMessagesArray` (REPEATED), `extraction_timestamp` |
| `bcookie_summary` | Per-bCookie session analytics derived from PWA logs | `bcookie` (REQUIRED), `eventCount`, `sessionCount`, `firstSeen`, `lastSeen`, `hasPurchase` (BOOLEAN), `hasApiError` (BOOLEAN), `extraction_timestamp` |
| `combined_logs` | Denormalized join of PWA, proxy, Lazlo, and orders logs by requestId | `timestamp` (REQUIRED), `requestId`, `bcookie`, `ccookie`, `path`, `pwa_*` fields, `proxy_*` fields, `lazlo_*` fields, `orders_*` fields, `extraction_timestamp` |

#### Access Patterns

- **Read**: Not applicable in-job — BigQuery is write-only from this service; downstream analytical queries are ad-hoc by consumers
- **Write**: Batch inserts in chunks of 500 rows using `table.insert()` with `skipInvalidRows: true` and `ignoreUnknownValues: true`; `extraction_timestamp` is added to every row at upload time
- **Indexes**: Day-level time partitioning on the `timestamp` field for all tables that contain it; dataset located in `US` region

---

### Log Extractor MySQL Database (`continuumLogExtractorMySQL`)

| Property | Value |
|----------|-------|
| Type | MySQL 8 |
| Architecture ref | `continuumLogExtractorMySQL` |
| Purpose | Optional relational store for extracted logs for operational reporting and ad-hoc queries |
| Ownership | owned |
| Migrations path | Not applicable — tables created automatically via `CREATE TABLE IF NOT EXISTS` DDL in `src/schemas/mysqlSchemas.js` |

#### Key Entities

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| `pwa_logs` | PWA log records | `id` (PK), `timestamp`, `request_id`, `bcookie`, `ccookie`, `cat`, `platform`, `error_code`, `is_guest`, `payment_method`, `cart_data` (JSON), `data` (JSON) |
| `proxy_logs` | Proxy request records | `id` (PK), `timestamp`, `request_id`, `bcookie`, `status` (INT), `route`, `path`, `method` |
| `lazlo_logs` | Legacy routing records | `id` (PK), `timestamp`, `request_id`, `path`, `status_code`, `name`, `legacy_method`, `action`, `client_name` |
| `orders_logs` | Orders request records | `id` (PK), `timestamp`, `bcookie`, `request_id`, `status_code` (INT), `endpoint`, `error_codes` (JSON), `error_messages_array` (JSON) |
| `bcookie_summary` | Per-bCookie session summaries | `id` (PK), `bcookie`, `event_count`, `session_count`, `first_seen`, `last_seen`, `has_purchase` (BOOLEAN), `has_api_error` (BOOLEAN) |
| `combined_logs` | Denormalized joined log records | `id` (PK), `timestamp`, `request_id`, `bcookie`, `ccookie`, `path`, `pwa_*` fields, `proxy_*` fields, `lazlo_*` fields, `orders_*` fields |

#### Access Patterns

- **Read**: Not applicable in-job — MySQL is write-only from this service
- **Write**: Transactional batched inserts per table in chunks of `BATCH_SIZE` (default 1000); each upload is wrapped in `BEGIN` / `COMMIT` with `ROLLBACK` on error
- **Indexes**: `idx_timestamp`, `idx_bcookie`, `idx_request_id`, `idx_is_guest`, `idx_payment_method`, `idx_status` (varies by table); `InnoDB` engine, `utf8mb4` charset

## Caches

> No evidence found in codebase. This service uses no caching layer.

## Data Flows

Raw log documents are read from Elasticsearch for a one-hour window. The job transforms each log type into a structured record, adds an `extraction_timestamp`, and writes to BigQuery (primary) and optionally MySQL (secondary). The `combined_logs` table is constructed by denormalizing PWA logs as the primary record and joining related proxy, Lazlo, and orders logs by `requestId`. The `bcookie_summary` table is derived entirely from `pwa_logs` records within the same extraction window.
