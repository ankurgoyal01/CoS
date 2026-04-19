---
service: "darwin-indexer"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "elasticsearchCluster"
    type: "elasticsearch"
    purpose: "Primary deal and hotel offer search index"
  - id: "continuumRedisCache"
    type: "redis"
    purpose: "Feature and sponsored data cache reads"
  - id: "postgresql"
    type: "postgresql"
    purpose: "Indexer metadata storage"
---

# Data Stores

## Overview

darwin-indexer writes to Elasticsearch as its primary output store, producing fully-denormalized search documents for deal and hotel offer indexes. It uses PostgreSQL to persist indexer metadata (run state, offsets, audit records). It reads from Redis cache for feature and sponsored data lookups during deal enrichment. Watson Feature Bucket (S3) is used to read and write item feature data for the Holmes ML pipeline. darwin-indexer does not own the Elasticsearch cluster or Redis cache — those are shared infrastructure.

## Stores

### Elasticsearch Cluster (`elasticsearchCluster`)

| Property | Value |
|----------|-------|
| Type | elasticsearch |
| Architecture ref | `elasticsearchCluster` |
| Purpose | Stores fully-denormalized deal and hotel offer documents for search query execution |
| Ownership | shared |
| Migrations path | > No evidence found — index mappings managed at application startup or via migration scripts owned by the Relevance Platform Team |

#### Key Entities

| Entity / Index | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal index | Stores enriched deal documents for search | Deal ID, title, merchant data, taxonomy, geo, inventory, badges, review signals, pricing (Joda-Money), feature scores |
| Hotel offer index | Stores enriched hotel offer documents for search | Hotel offer ID, taxonomy, pricing, geo |

#### Access Patterns

- **Read**: Not applicable — darwin-indexer does not query Elasticsearch for search; it only reads index/alias metadata during alias switchover operations
- **Write**: Batch bulk-write of enriched documents during each indexing job run; uses Elasticsearch Bulk API for throughput efficiency
- **Indexes**: Blue/green index pairs maintained for zero-downtime alias switchover; alias points to the live index while the new index is built in the background

### PostgreSQL (`postgresql`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `postgresql` (Continuum shared PostgreSQL) |
| Purpose | Stores indexer run metadata: job state, offsets for incremental indexing, audit log of index operations |
| Ownership | owned |
| Migrations path | > No evidence found — migration path to be confirmed by service owner |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Index run state | Tracks the status of each indexing job run (started, completed, failed) | Run ID, job name, status, start time, end time |
| Incremental offsets | Persists the last processed offset for incremental (delta) index runs | Job name, last offset, updated timestamp |

#### Access Patterns

- **Read**: Reads last-known offset at the start of each incremental indexing run to determine which records to process
- **Write**: Writes run metadata and updates offsets upon job completion or failure
- **Indexes**: > No evidence found

### Watson Feature Bucket (`watsonItemFeatureBucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `watsonItemFeatureBucket` |
| Purpose | Stores and retrieves item-level feature vectors used by the Holmes ML ranking pipeline |
| Ownership | external (owned by Watson/Holmes platform) |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Object | Purpose | Key Fields |
|-----------------|---------|-----------|
| Item feature files | Per-item feature data used to populate `ItemIntrinsicFeatureEvent` | Item ID, feature vector |

#### Access Patterns

- **Read**: darwin-indexer reads item feature data from S3 during deal enrichment to populate feature events
- **Write**: darwin-indexer may write computed feature data back to S3 after enrichment
- **Indexes**: > Not applicable — S3 object storage

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumRedisCache` | redis | Reads sponsored and feature data during deal document enrichment; avoids repeated upstream service calls for frequently-accessed data | > No evidence found |

## Data Flows

1. Quartz scheduler triggers an indexing job run.
2. The Deal Aggregator fetches raw deal data from `continuumDealCatalogService` and enrichment data from Taxonomy, Geo, Merchant API, Inventory, Badges, UGC Review, and Merchant Place services.
3. Feature and sponsored data are read from `continuumRedisCache` to supplement document fields.
4. Item feature data is read from `watsonItemFeatureBucket` (S3).
5. Enriched documents are bulk-written to Elasticsearch (deal index or hotel offer index).
6. On full index completion, the Elasticsearch alias is atomically switched from the old index to the new one.
7. Run metadata and offsets are persisted to PostgreSQL.
8. `ItemIntrinsicFeatureEvent` messages are published to Kafka for the `holmesPlatform`.
