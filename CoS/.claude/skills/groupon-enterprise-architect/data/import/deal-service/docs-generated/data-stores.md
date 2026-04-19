---
service: "deal-service"
title: Data Stores
generated: "2026-03-02"
type: data-stores
stores:
  - id: "continuumDealServicePostgres"
    type: "postgresql"
    purpose: "Deal processing state, product-to-deal mappings, message bus update records"
  - id: "continuumDealServiceMongo"
    type: "mongodb"
    purpose: "Comprehensive deal metadata (titles, pricing, options, merchant info, taxonomies)"
  - id: "continuumDealServiceRedisLocal"
    type: "redis"
    purpose: "Processing queue, retry scheduling, deal notification lists"
  - id: "continuumDealServiceRedisBts"
    type: "redis"
    purpose: "BTS deal metadata cache"
---

# Data Stores

## Overview

Deal Service owns four data stores spanning three technologies. PostgreSQL is the primary relational store for deal processing state and audit records. MongoDB holds the full enriched deal metadata document. Two Redis instances serve distinct roles: the local Redis instance drives the job queue and retry scheduler, while a separate BTS Redis instance caches deal metadata for BTS consumers. The `dealStoreRepository` component mediates all reads and writes to Postgres and MongoDB.

## Stores

### Deal Service Postgres (`continuumDealServicePostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumDealServicePostgres` |
| Purpose | Stores deal processing state, product-to-deal mappings, and message bus update records |
| Ownership | owned |
| Migrations path | > No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deals` | Tracks per-deal processing state | deal ID, active status, timestamps |
| `product_to_deal_mapping` | Maps product/supply identifiers to deal identifiers | product ID, deal ID |
| `deal_mbus_updates` | Records inventory update events published to the message bus | deal ID, option ID, publish status, timestamp |

#### Access Patterns

- **Read**: Looks up existing deal state and mappings before processing; checks `deal_mbus_updates` to detect inventory status changes
- **Write**: Upserts deal state after processing; inserts/updates `deal_mbus_updates` records when inventory events are published
- **Indexes**: > No evidence found

---

### Deal Service MongoDB (`continuumDealServiceMongo`)

| Property | Value |
|----------|-------|
| Type | mongodb |
| Architecture ref | `continuumDealServiceMongo` |
| Purpose | Stores comprehensive deal metadata aggregated from multiple upstream APIs |
| Ownership | owned |
| Migrations path | > Not applicable (schema-less document store) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal metadata document | Full enriched deal record used as the canonical metadata store | `active`, `ts_updated`, `options`, `trends`, `localised_pricing`, `merchant_recommendations`, deal UUID, country |

#### Access Patterns

- **Read**: Queried at queue-fill time to identify deals due for processing (filtered by `active` flag and `ts_updated` age relative to `updateActiveInHours` / `updateInactiveInHours` thresholds)
- **Write**: Full document upsert after each deal processing cycle completes enrichment
- **Indexes**: > No evidence found

---

### Deal Service Redis (Local) (`continuumDealServiceRedisLocal`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumDealServiceRedisLocal` |
| Purpose | Job queue, retry scheduler, and deal notification lists |
| Ownership | owned |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `processing_cloud` (sorted set) | Active deal processing job queue | Member: deal identifier; Score: enqueue timestamp |
| `nodejs_deal_scheduler` (sorted set) | Scheduled retry queue for failed deals | Member: deal identifier; Score: retry-due timestamp |
| `{event_notification}.message` (list) | Deal change notification queue for downstream consumers | JSON notification payload |

#### Access Patterns

- **Read**: Polled every 5 seconds (`feature_flags.processDeals.intervalInSec`) for new jobs; sorted set range queries by score for due retries
- **Write**: Bulk-populated from MongoDB when `processing_cloud` length falls below the batch limit; individual retry entries added by `redisScheduler` on failure
- **Indexes**: > Not applicable (Redis native sorted set / list structures)

---

### Deal Service Redis (BTS) (`continuumDealServiceRedisBts`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumDealServiceRedisBts` |
| Purpose | Cache for BTS deal metadata, separate from the job queue Redis |
| Ownership | owned |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| BTS deal metadata entries | Cached deal data served to BTS consumers | Deal identifier-keyed entries |

#### Access Patterns

- **Read**: BTS consumers read cached metadata from this instance
- **Write**: deal-service writes/refreshes BTS cache entries after processing each deal
- **Indexes**: > Not applicable

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumDealServiceRedisBts` | redis | BTS deal metadata cache | > No evidence found |

## Data Flows

After each deal processing cycle, deal-service writes the enriched deal state to PostgreSQL (`deals` table) and the full metadata document to MongoDB, then refreshes the BTS Redis cache. When inventory status has changed relative to the last recorded state in `deal_mbus_updates`, the service publishes an `INVENTORY_STATUS_UPDATE` event to the message bus. The Redis local instance acts purely as an operational queue and is not a system of record.
