---
service: "vespa-indexer"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "vespaCluster"
    type: "vespa"
    purpose: "Primary search index — stores all deal option documents"
  - id: "cloudPlatform"
    type: "gcs"
    purpose: "Stores MDS feed files consumed during scheduled deal refresh"
  - id: "bigQuery"
    type: "bigquery"
    purpose: "Source of ML ranking features applied to Vespa documents"
---

# Data Stores

## Overview

Vespa Indexer writes to one store (`vespaCluster`) and reads from two external data sources (`cloudPlatform` / GCS, `bigQuery`). The service does not own any database of its own; it is a pure ingestion pipeline. All data stores are external to the service and managed by other teams or GCP.

## Stores

### Vespa Cluster (`vespaCluster`)

| Property | Value |
|----------|-------|
| Type | vespa |
| Architecture ref | `vespaCluster` |
| Purpose | Primary search index — stores all deal option documents for search and recommendation queries |
| Ownership | external (managed by Vespa/Groupon search platform team) |
| Migrations path | Schema defined in `.cursor/vespa/option.sd` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `option` document | One Vespa document per deal option | `id` (`option_<deal_option_id>`), `deal_id`, `deal_uuid`, `deal_title`, `option_title`, `status` (ACTIVE/INACTIVE), `price`, `value`, `discount_percent`, `margin`, `currency`, `is_local`, `is_goods`, `is_adult`, `is_bookable`, `redemption_locations`, `redemption_locations_gps`, `category_hierarchy`, `merchant_name`, `start_at`, `option_duration_days`, `fs_deal_gppi_coec`, `fs_deal_cvr_coec`, `fs_option_gppi_coec`, `fs_option_cvr_coec`, `fs_dist_gppi_b0` … `fs_dist_gppi_b8`, `embedding` (tensor) |

#### Access Patterns

- **Read**: Health check only (`vespa_client.is_healthy()`)
- **Write**: Full document feed (`feed_document`) for creates/full updates; partial update (`update_document`) for feature-only or real-time partial updates
- **Indexes**: BM25 text indexes on `deal_title`, `option_title`, `category_hierarchy`, `merchant_name`, `tags_name`; HNSW index on `embedding` tensor (384 dimensions, prenormalized-angular distance); `fast-search` attributes on `deal_id`, `status`, `price`, `is_local`, `redemption_locations_gps`, `category_hierarchy_uuid`, `start_at`

---

### Google Cloud Storage — MDS Feed (`cloudPlatform`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `cloudPlatform` |
| Purpose | Stores gzipped newline-delimited JSON MDS feed files; read during scheduled deal refresh to extract deal UUIDs |
| Ownership | external (GCP / Groupon central data platform) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `mds_feeds/vespa_ai_US.gz` (configurable via `MDS_FEED_FILE_NAME`) | Gzipped NDJSON file; each line is a JSON object with a `deal_uuid` field | `deal_uuid` |

#### Access Patterns

- **Read**: Streaming download in 8 MB chunks via `download_blob_async_stream()`; each line parsed for `deal_uuid` only (memory-efficient, no full entity parsing)
- **Write**: Not applicable — this service only reads from GCS
- **Indexes**: Not applicable

---

### Google BigQuery — ML Feature Tables (`bigQuery`)

| Property | Value |
|----------|-------|
| Type | bigquery |
| Architecture ref | `bigQuery` |
| Purpose | Source of ML ranking features (COEC signals, distance bucket priors) applied to Vespa documents |
| Ownership | external (managed by Data Science / ML teams) |
| Migrations path | Not applicable — tables owned externally |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deal_feature_table` (configured via `DEAL_FEATURE_TABLE`) | Deal-level COEC features | `deal_id`, `deal_cvr_coec_log_30d`, `deal_gppi_coec_log_30d` |
| `deal_option_feature_table` (configured via `DEAL_OPTION_FEATURE_TABLE`) | Option-level COEC features | `option_id`, `option_cvr_coec_log_30d`, `option_gppi_coec_log_30d` |
| `prj-grp-relevance-dev-2867.fs.deal_distance_bucket_prior_v2` (default for `DEAL_DISTANCE_BUCKET_TABLE`) | Deal-level distance bucket priors | `deal_id`, `log_oe_b0` … `log_oe_b8` |
| `category_feature_table` (configured via `CATEGORY_FEATURE_TABLE`) | Category-level features | Category identifiers and feature values |

#### Access Patterns

- **Read**: Batched queries (batch size configurable via `FEATURE_BATCH_SIZE`, default 500) with up to `FEATURE_REFRESH_MAX_WORKERS` (default 10) concurrent async tasks; queries are keyed by `deal_id` or `option_id`
- **Write**: Not applicable — this service only reads from BigQuery
- **Indexes**: Not applicable — managed externally

## Caches

> No evidence found in codebase. This service does not use an explicit cache layer.

## Data Flows

1. GCS feed file is streamed line-by-line to extract deal UUIDs.
2. UUIDs are batched (up to `REFRESH_BATCH_SIZE` = 50 per request) and sent to MDS REST API.
3. Full deal option records returned by MDS REST are enriched with BigQuery ML features.
4. Enriched documents are written to Vespa via `pyvespa`.
5. Real-time MessageBus events bypass GCS/MDS REST for the data fetch step and write directly to Vespa using data carried in the event payload, optionally enriched with BigQuery features for CREATE events.
