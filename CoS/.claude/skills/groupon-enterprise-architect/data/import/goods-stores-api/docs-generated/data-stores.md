---
service: "goods-stores-api"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumGoodsStoresDb"
    type: "mysql"
    purpose: "Primary relational store for goods products, options, merchants, contracts, taxonomy mappings, and audit history"
  - id: "continuumGoodsStoresRedis"
    type: "redis"
    purpose: "Resque queues, caching, throttling, and batch state"
  - id: "continuumGoodsStoresElasticsearch"
    type: "elasticsearch"
    purpose: "Search index for product, option, inventory, and deal documents"
  - id: "continuumGoodsStoresS3"
    type: "s3"
    purpose: "Object storage for attachments, images, and uploads"
---

# Data Stores

## Overview

Goods Stores API owns four data stores: a MySQL database as the system of record for all goods domain entities, a Redis instance serving as both a Resque job queue and caching layer, an Elasticsearch index for full-text and structured product/agreement search, and an S3 bucket for binary attachment and image storage. The MySQL database is the authoritative source; Redis, Elasticsearch, and S3 are derived or operational stores that are populated by the API and worker containers.

## Stores

### Goods Stores MySQL (`continuumGoodsStoresDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumGoodsStoresDb` |
| Purpose | Primary relational store for goods products, options, merchants, contracts, taxonomy mappings, and audit history |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `products` | Core goods product records | id, merchant_id, status, title, created_at, updated_at |
| `options` | Product option variants (size, color, etc.) | id, product_id, sku, price, status |
| `merchants` | Merchant account records | id, name, status, avalara_account_id |
| `contracts` | Merchant-Groupon contracts governing deal terms | id, merchant_id, product_id, start_date, end_date, region, status |
| `attachments` | File and image metadata linked to products | id, product_id, url, content_type, created_at |
| `taxonomy_mappings` | Product-to-category taxonomy associations | id, product_id, category_id, taxonomy_source |
| `versions` (Paper Trail) | SOX audit history for all in-scope model mutations | id, item_type, item_id, event, whodunnit, created_at |

#### Access Patterns

- **Read**: API endpoints query by product_id, merchant_id, contract_id; search endpoints delegate to Elasticsearch; taxonomy reads join taxonomy_mappings to products
- **Write**: API endpoints create and update products, options, merchants, contracts; workers perform batch mutations and post-processing updates; Paper Trail automatically versions all changes to in-scope models
- **Indexes**: Indexes expected on foreign keys (merchant_id, product_id, contract_id) and status fields; specific index names not discoverable from inventory

---

### Goods Stores Elasticsearch (`continuumGoodsStoresElasticsearch`)

| Property | Value |
|----------|-------|
| Type | elasticsearch |
| Architecture ref | `continuumGoodsStoresElasticsearch` |
| Purpose | Search index powering product and agreement search endpoints |
| Ownership | owned |
| Migrations path | > Not applicable — index mappings managed via application initializer |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `products` index | Full-text and filtered product search | product_id, title, merchant_id, status, taxonomy_category, options |
| `agreements` index | Agreement/contract search for merchant tooling | contract_id, merchant_id, product_id, status, region |

#### Access Patterns

- **Read**: `continuumGoodsStoresApi_search` component builds Elasticsearch queries for `/v2/search/products` and `/v2/search/agreements` endpoints
- **Write**: `continuumGoodsStoresWorkers_elasticsearchIndexer` indexes and validates documents after domain changes; triggered by post-processors and direct API mutations
- **Indexes**: Elasticsearch mappings define analyzed fields for full-text search and keyword fields for exact-match filtering

---

### Goods Stores S3 Bucket (`continuumGoodsStoresS3`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `continuumGoodsStoresS3` |
| Purpose | Binary object storage for product attachments, images, and uploads |
| Ownership | owned |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Attachment objects | Product images and file attachments uploaded via the API | object key, content_type, product_id reference |
| SFTP exports | Batch export files produced by `continuumGoodsStoresWorkers_batch` | export job id, timestamp |

#### Access Patterns

- **Read**: `continuumGoodsStoresApi_attachmentService` serves attachment URLs; workers read export files
- **Write**: `continuumGoodsStoresApi_attachmentService` uploads files via CarrierWave/Attachinary; `continuumGoodsStoresWorkers_batch` writes SFTP export objects

---

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumGoodsStoresRedis` | redis | Resque job queues for background worker dispatch | N/A (queue; not TTL-based) |
| `continuumGoodsStoresRedis` | redis | Application-level response caching and throttle state | Configured per cache key |
| `continuumGoodsStoresRedis` | redis | Event batching state for MessageBus price change handler | Configured per batch window |

## Data Flows

1. API writes to `continuumGoodsStoresDb` (MySQL) as the system of record.
2. After write, the API enqueues a Resque job in `continuumGoodsStoresRedis` for the `continuumGoodsStoresWorkers` pool.
3. Workers run post-processing pipelines, update `continuumGoodsStoresDb`, and trigger `continuumGoodsStoresWorkers_elasticsearchIndexer` to sync `continuumGoodsStoresElasticsearch`.
4. Attachment uploads flow from the API to `continuumGoodsStoresS3` via CarrierWave; metadata is persisted to `continuumGoodsStoresDb`.
5. MessageBus events arrive at `continuumGoodsStoresMessageBusConsumer`, which writes batching state to `continuumGoodsStoresRedis` and enqueues workers.
