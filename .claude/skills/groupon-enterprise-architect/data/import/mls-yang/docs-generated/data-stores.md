---
service: "mls-yang"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "mlsYangDb"
    type: "postgresql"
    purpose: "Primary Yang projection store, CLO transactions, vouchers, batch/Quartz state"
  - id: "mlsYangRinDb"
    type: "postgresql"
    purpose: "Merchant lifecycle inventory and lifecycle data"
  - id: "mlsYangHistoryDb"
    type: "postgresql"
    purpose: "History service store for whitelisted merchant history events"
  - id: "mlsYangDealIndexDb"
    type: "postgresql"
    purpose: "Read-optimised deal snapshot and event index"
---

# Data Stores

## Overview

mls-yang owns or co-owns four PostgreSQL databases, each serving a distinct projection concern. The primary database (`yangDb`) is the broadest — it stores all Kafka-projected merchant state and acts as the Quartz scheduler's job store for the batch subsystem. The three secondary databases handle specialised domains: merchant lifecycle inventory (`rinDb`), history events (`historyDb`), and deal index lookups (`dealIndexDb`). All databases are accessed via JDBI DAOs with DaaS-backed PostgreSQL connection pools. No caching layer is used in the data path (beyond an in-memory Guava cache for permalink-to-UUID resolution in the batch import path).

## Stores

### MLS Yang Primary DB (`mlsYangDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `mlsYangDb` |
| Purpose | Primary persistence for Yang projections: voucher sold/redeemed counts, CLO transactions, merchant facts, merchant accounts, bullets, deal metrics, and Quartz job/trigger state |
| Ownership | Owned |
| Migrations path | Referenced from `mls-db-schemas` test dependency; migration scripts not bundled in this repo |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `voucher_sold` | Tracks voucher-sold counts per merchant | `merchant_id`, `voucher_count`, `counted_at` |
| `voucher_redeemed` | Tracks voucher-redeemed counts per merchant | `merchant_id`, `voucher_count`, `counted_at` |
| `clo_transaction` | CLO linked-offer transaction records (AUTH/CLEAR/REWARD) | `transaction_uuid`, `deal_uuid`, `consumer_uuid`, `transaction_type`, `transaction_at`, `group_id`, `billing_record_id` |
| `merchant_account` | Merchant account metadata (type, country, DNR reason, metal status) | `uuid`, `type`, `country`, `metal`, `dnr_reason` |
| `merchant_fact` | Key-value merchant facts (e.g. metal tier) | `merchant_id`, `type`, `value`, `created_at` |
| `bullet` | Bullet records created via BulletCreated commands | `bullet_id`, merchant references |
| `deal_metrics` | Deal engagement metrics by date and metric type | `deal_uuid`, `metric_type`, `event_date`, `value` |
| `quartz.qrtz_*` | Quartz scheduler job and trigger state (clustered) | Standard Quartz PostgreSQL tables under `quartz` schema |

#### Access Patterns

- **Read**: Voucher counts by merchant UUID; CLO transactions by group ID, deal IDs+dates, or transaction UUID; merchant accounts by UUID; merchant facts by merchant ID
- **Write**: Upserts for voucher counts and merchant facts; inserts for CLO transactions with recent-record deduplication; batch imports write deal metrics in bulk (batch size 10,000)
- **Indexes**: Not directly visible from application code; Quartz tables require standard Quartz PostgreSQL indexes

### MLS Yang RIN DB (`mlsYangRinDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `mlsYangRinDb` |
| Purpose | Merchant lifecycle database — stores inventory products and lifecycle data shared across MLS services |
| Ownership | Shared (co-owned with other MLS services) |
| Migrations path | Not bundled in this repo |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `inventory_product` | Inventory product records imported from Hive | Deal/product identifiers, import metadata |

#### Access Patterns

- **Read**: Batch jobs read inventory product state for backfill decisions
- **Write**: `InventoryProductImportExecutor` and `DealDailyBackfill` write inventory product data; lifecycle backfill jobs write lifecycle metrics

### MLS Yang History DB (`mlsYangHistoryDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `mlsYangHistoryDb` |
| Purpose | Stores history events projected from the `mls.HistoryEvent` Kafka topic |
| Ownership | Shared (co-owned with history-service components) |
| Migrations path | Not bundled in this repo |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `history_event` | Merchant history events (all types when `saveHistoryEventInHistoryService=true`) | `history_id`, `event_type`, `event_date`, `merchant_id`, `deal_id`, `user_id` |

#### Access Patterns

- **Read**: Existence check by `history_id` before insert (idempotency guard)
- **Write**: Insert on first occurrence of each `history_id`

### MLS Yang Deal Index DB (`mlsYangDealIndexDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `mlsYangDealIndexDb` |
| Purpose | Read-optimised deal snapshot and event index; updated from `mls.Generic` Kafka topic and read during batch imports |
| Ownership | Shared (co-owned with deal-index components) |
| Migrations path | Not bundled in this repo |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deal_snapshot` | Current snapshot of deal state | `deal_uuid`, snapshot payload fields |
| `deal_event` | Deal event log | `deal_uuid`, `event_type`, `event_timestamp` |

#### Access Patterns

- **Read**: Batch import jobs read deal index data during metrics enrichment
- **Write**: `DealSnapshotHandler` updates deal snapshots; `DealEventHandler` writes deal events

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `permalinkToDealUUIDCache` | In-memory (Guava) | Caches deal permalink to UUID resolution results from Deal Catalog API | 1 day (expire after access); max 500,000 entries |

## Data Flows

- **Kafka to yangDb/historyDb/dealIndexDb**: Command Ingestion Pipeline (`smaApi_commandIngestion`) receives Kafka messages, deserialises payloads, and writes projections to the appropriate database via JDBI DAOs.
- **Hive/Janus to yangDb**: Batch import workers (`smaBatch_importWorkers`) query Janus Hive tables (`grp_gdoop_pde.junohourly`) via JDBC, resolve deal UUIDs via Deal Catalog API (with Guava cache), and persist metrics into `yangDb.deal_metrics`.
- **Cerebro Hive to rinDb**: Risk import workers query Cerebro Hive for refund rate data and persist results into `rinDb`.
- **Partition management**: `PersistencePartitionsManager` job maintains PostgreSQL table partitions in `yangDb` (schema `ext`) on a weekly schedule.
- **CLO retention**: `CloRetentionManager` job purges old CLO records from `yangDb` on a daily schedule (05:00 UTC in production).
