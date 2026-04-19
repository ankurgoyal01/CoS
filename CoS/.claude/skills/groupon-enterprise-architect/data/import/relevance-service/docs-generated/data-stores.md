---
service: "relevance-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumFeynmanSearch"
    type: "elasticsearch"
    purpose: "Full-text search index for deal browse and search queries"
---

# Data Stores

## Overview

The Relevance Service's primary data store is Elasticsearch, accessed through the Feynman Search container. Elasticsearch powers full-text search and browse queries, storing indexed deal data optimized for relevance-scored retrieval. The Indexer component within RAPI builds and maintains these indexes by ingesting data in batch from the Enterprise Data Warehouse (EDW). The service also reads feature vectors from EDW for its ranking models.

## Stores

### Elasticsearch (Feynman Search) (`continuumFeynmanSearch`)

| Property | Value |
|----------|-------|
| Type | elasticsearch |
| Architecture ref | `continuumFeynmanSearch` |
| Purpose | Full-text search index for deal browse and search functionality |
| Ownership | owned |
| Migrations path | Managed via index templates and reindexing operations |

#### Key Entities

| Entity / Index | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal index | Primary deal search index containing deal metadata, categories, locations, and pricing for full-text search | Deal ID, title, category, location, price, merchant, status |
| Browse index | Category-based browse index for navigational deal discovery | Category hierarchy, deal associations, location facets |

#### Access Patterns

- **Read**: High-frequency query-time reads from search and browse API requests; queries include full-text match, geo-distance filters, category facets, and relevance-scored ranking
- **Write**: Batch index builds and incremental updates driven by the Indexer component; data sourced from EDW
- **Indexes**: Inverted indexes on deal text fields; doc-value fields for sorting and aggregation; geo-point indexes for location-based queries

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Feature vector cache | in-memory | Caches recently fetched feature vectors from EDW to reduce latency during ranking | Request-scoped / short TTL |

> Additional caching layers (e.g., Redis, Memcached) may exist in the implementation. Service owners should document any external cache dependencies identified in the source repository.

## Data Flows

1. **EDW to Indexer (batch)**: The Indexer component reads deal data and feature vectors from the Enterprise Data Warehouse in batch operations to build and refresh Elasticsearch indexes
2. **Indexer to Elasticsearch (write)**: Processed deal data is written to Elasticsearch indexes via bulk index operations
3. **Elasticsearch to Ranking Engine (read)**: Search queries hit Elasticsearch for candidate retrieval; results are passed to the Ranking Engine for relevance scoring
4. **EDW to Features Client (batch)**: The Features Client reads feature vectors from EDW for use by the Ranking Engine during scoring
5. **Feynman Search to Booster (partial migration)**: Search and ranking workloads are progressively being offloaded from Feynman Search / Elasticsearch to the Booster engine
