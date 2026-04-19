---
service: "mds"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumMarketingDealDb"
    type: "postgresql"
    purpose: "Primary relational store for deals, taxonomy, divisions, trackers, and mapping tables"
  - id: "continuumMarketingDealServiceRedis"
    type: "redis"
    purpose: "In-memory queue, distributed locking, retry scheduling, and notification store"
  - id: "continuumMarketingDealServiceMongo"
    type: "mongodb"
    purpose: "Legacy/compatibility metadata store (tagged ToDecommission)"
---

# Data Stores

## Overview

MDS owns three data stores: a PostgreSQL database as the primary source of truth for enriched deal data, taxonomy mappings, division configurations, and change trackers; a Redis instance that serves as an in-memory queue for deal processing, distributed lock manager, retry scheduler, and notification store; and a legacy MongoDB instance used for backward-compatible metadata reads in older deal-service flows. The MongoDB store is tagged for decommissioning and is read-only in current operations. The PostgreSQL store is accessed via JDBC (JTier layer) and Sequelize (Node.js worker layer). Redis is accessed via the RESP protocol from both layers.

## Stores

### Marketing Deal Service Database (`continuumMarketingDealDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumMarketingDealDb` |
| Purpose | Primary relational store for deals, taxonomy, divisions, trackers, and mapping tables |
| Ownership | owned |
| Migrations path | Managed via Sequelize migrations (worker) and JDBI schema (JTier) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deals` | Enriched deal records — the primary domain entity | id, deal_uuid, title, status, division_id, taxonomy_id, merchant_id, enrichment_timestamp |
| `deal_taxonomy` | Taxonomy classification mappings for deals | id, deal_id, taxonomy_path, category, subcategory |
| `deal_divisions` | Division assignments and geo-based deal distribution | id, deal_id, division_id, division_name, active |
| `deal_trackers` | Change tracking records for outbox/publish pattern | id, deal_id, change_type, tracked_at, published_at, retry_count |
| `product_mappings` | Product-to-deal mapping data for inventory correlation | id, deal_id, product_id, inventory_type, mapping_status |
| `deal_locations` | Redemption location and place metadata per deal | id, deal_id, place_id, latitude, longitude, google_place_id |
| `deal_performance` | Cached performance/KPI metrics per deal | id, deal_id, metric_date, impressions, clicks, conversions, revenue |
| `deal_margins` | Margin and pricing enrichment data | id, deal_id, margin_pct, price, value, discount_pct |

#### Access Patterns

- **Read**: Deal retrieval by ID or UUID; filtered list queries by division, taxonomy, status, and merchant; tracker reads for publish scheduling; performance data aggregation for reporting; location lookups for geo-enrichment
- **Write**: Enrichment pipeline writes deal deltas (taxonomy, division, margin, performance, location); tracker records created/updated during change tracking; product mappings updated during inventory aggregation; batch updates during feed generation
- **Indexes**: Primary key indexes on all tables; indexes on `deals.deal_uuid`, `deals.status`, `deals.division_id`, `deals.merchant_id`, `deal_trackers.change_type`, `deal_trackers.published_at`, `deal_divisions.division_id` (inferred from access patterns; verify against schema)

### Marketing Deal Service Redis (`continuumMarketingDealServiceRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumMarketingDealServiceRedis` |
| Purpose | In-memory queue, distributed locking, retry scheduling, and notification store for deal processing workers |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal processing queues | Named queues holding deal identifiers awaiting enrichment processing | queue name, deal_id, enqueue_timestamp |
| Distributed locks | Per-deal locks preventing concurrent processing of the same deal | lock key (deal_id), lock owner (worker instance), TTL |
| Retry schedules | Delayed retry entries for failed enrichment attempts | deal_id, retry_count, next_retry_at, error_reason |
| Notification store | Buffered deal-change notifications before publishing | notification_id, deal_id, change_type, payload |
| Failed processing queue | Dead-letter store for deals exceeding retry limits | deal_id, last_error, failure_count, failed_at |

#### Access Patterns

- **Read**: Workers dequeue deal identifiers for processing; lock checks before processing; retry schedule polling; notification reads for batch publishing
- **Write**: Deal identifiers enqueued on event consumption; locks acquired/released during processing; retry entries created on failure; notifications buffered during enrichment; failed entries written after max retries
- **Indexes**: Not applicable (Redis key-space with prefixed namespaces)

### Marketing Deal Service MongoDB (`continuumMarketingDealServiceMongo`)

| Property | Value |
|----------|-------|
| Type | mongodb |
| Architecture ref | `continuumMarketingDealServiceMongo` |
| Purpose | Legacy/compatibility metadata store referenced by older deal-service flows |
| Ownership | owned (tagged `ToDecommission`) |
| Migrations path | Not applicable (legacy) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal metadata (legacy) | Historical deal metadata from pre-PostgreSQL era | deal_id, metadata attributes, legacy_fields |

#### Access Patterns

- **Read**: Legacy deal-service flows read metadata for backward compatibility; read-only in current operations
- **Write**: No active writes — store is in read-only decommissioning mode
- **Indexes**: Legacy indexes maintained; no new indexes being added

> This store is tagged `ToDecommission`. Active migration to PostgreSQL is in progress. All new deal metadata is written exclusively to `continuumMarketingDealDb`.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumMarketingDealServiceRedis` | redis | Distributed locks (per-deal), retry schedule state, notification buffer | Lock TTL: configurable per deal; retry/notification: until consumed |

## Data Flows

- Deal events arrive from the message bus and Deal Catalog Service. The Deal Processing Worker enqueues deal identifiers into Redis queues.
- Workers dequeue deals, acquire distributed locks in Redis, and run the enrichment pipeline which reads from upstream services and writes computed deltas to PostgreSQL via the Persistence Adapter.
- Change trackers in PostgreSQL are updated by the Deal Change Tracking & Publish Worker (Quartz-scheduled), which then publishes notifications via Redis and the message bus.
- The JTier API layer reads enriched deal data from PostgreSQL, calls inventory services for real-time status, and returns aggregated responses.
- Legacy MongoDB is read by older JTier query paths that still reference the Mongo persistence layer; these paths are being migrated to PostgreSQL.
- No CDC, ETL pipelines, or cross-database replication were identified in the architecture model for this service.
