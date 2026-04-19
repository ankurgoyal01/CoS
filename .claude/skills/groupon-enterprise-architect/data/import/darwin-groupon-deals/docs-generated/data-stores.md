---
service: "darwin-groupon-deals"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "elasticsearchClusterExt_b8f21c"
    type: "elasticsearch"
    purpose: "Deal index for full-text and filtered search"
  - id: "redisClusterExt_9d0c11"
    type: "redis"
    purpose: "Response cache for deal search results"
  - id: "watsonObjectStorageExt_3a1f2c"
    type: "object-storage"
    purpose: "ML model artifacts and feature data"
---

# Data Stores

## Overview

The Darwin Aggregator Service does not own a primary transactional database. It reads deal data from a shared Elasticsearch index, caches aggregated responses in Redis to reduce latency on repeated queries, and loads ML model artifacts from Watson Object Storage. All three stores are external/shared resources — the service is a consumer, not an owner.

## Stores

### Elasticsearch Deal Index (`elasticsearchClusterExt_b8f21c`)

| Property | Value |
|----------|-------|
| Type | elasticsearch |
| Architecture ref | `elasticsearchClusterExt_b8f21c` |
| Purpose | Full-text and filtered deal search queries |
| Ownership | shared / external |
| Migrations path | Not applicable — index managed by Deal Catalog pipeline |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal index | Stores searchable deal documents for query-time retrieval | deal ID, title, category, geo, price, availability, boost signals |

#### Access Patterns

- **Read**: Query-time searches for deals matching user query, geo, category, and filter parameters; executed by `aggregationEngine` via `externalClients`
- **Write**: Not applicable — Darwin does not write to the deal index
- **Indexes**: Managed by the upstream Deal Catalog indexing pipeline; not configured by this service

---

### Watson Object Storage — ML Models (`watsonObjectStorageExt_3a1f2c`)

| Property | Value |
|----------|-------|
| Type | object-storage |
| Architecture ref | `watsonObjectStorageExt_3a1f2c` |
| Purpose | Stores ML model artifacts and feature data used for relevance ranking |
| Ownership | external (managed by ML/Relevance ML pipelines) |
| Migrations path | Not applicable — artifacts published by ML training pipelines |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Model artifact buckets | Binary model objects loaded by `modelStore` at startup or on refresh | model version, feature weights, ranking parameters |

#### Access Patterns

- **Read**: `modelStore` component reads model artifacts from object storage buckets, typically at service startup or on model version refresh
- **Write**: Not applicable — Darwin does not write model artifacts
- **Indexes**: Not applicable

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `redisClusterExt_9d0c11` | redis | Caches serialized deal search responses to reduce upstream fan-out latency on repeated queries | Not discoverable from inventory — confirm with service owner |

### Cache Access Patterns

- **Read**: `cacheLayer` component checks Redis for a cached response before invoking `aggregationEngine`; a cache hit short-circuits the full aggregation pipeline
- **Write**: `cacheLayer` writes the aggregated response to Redis after a successful aggregation; payloads serialized using Kryo (5.6.2)

## Data Flows

1. Inbound search request arrives at `apiResource`
2. `cacheLayer` checks `redisClusterExt_9d0c11` — on hit, returns cached response immediately
3. On cache miss, `aggregationEngine` fans out to Elasticsearch (`elasticsearchClusterExt_b8f21c`) and upstream services
4. `modelStore` supplies current ML model artifacts from `watsonObjectStorageExt_3a1f2c` to score and rank results
5. Ranked results are written back to `redisClusterExt_9d0c11` by `cacheLayer` before returning to the caller
