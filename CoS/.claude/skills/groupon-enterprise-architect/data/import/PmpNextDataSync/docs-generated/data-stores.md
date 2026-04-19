---
service: "PmpNextDataSync"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumPmpHudiBronzeLake"
    type: "gcs-hudi"
    purpose: "Bronze-layer Hudi MERGE_ON_READ tables containing synced operational data"
  - id: "externalPostgresOperationalDatabases"
    type: "postgresql"
    purpose: "Source operational databases read via JDBC"
---

# Data Stores

## Overview

PmpNextDataSync reads from multiple external PostgreSQL databases and writes to a single GCS-backed Apache Hudi data lake (bronze layer). The service also maintains a Hudi checkpoint table to track incremental sync progress per source table. It does not own any PostgreSQL databases itself — all relational sources are read-only dependencies.

## Stores

### PMP Hudi Bronze Lake (`continuumPmpHudiBronzeLake`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Storage + Apache Hudi (MERGE_ON_READ) |
| Architecture ref | `continuumPmpHudiBronzeLake` |
| Purpose | Durable bronze-layer storage for all synced PMP operational data, consumed by silver/gold Spark jobs |
| Ownership | owned |
| Base path (prod) | `gs://dataproc-staging-us-central1-810031506929-r0jh1mub/pmp/data/hudi-wh/bronze` |
| Base path (local) | `/tmp/hudi/hudi-wh` |

#### Key Entities (Hudi Tables Written)

| Hudi Table | Source | Operation | Record Key | Notes |
|------------|--------|-----------|-----------|-------|
| `hudi_cm_campaign_na` | `email_campaign.campaign` (NA) | upsert | `campaign_id` | Partitioned by `country` |
| `hudi_cm_deal_query_na` | `email_campaign.deal_query` (NA) | upsert | `id` | Partitioned by `brand` |
| `hudi_cm_campaign_emea` | `email_campaign.campaign` (EMEA) | upsert | `campaign_id` | Partitioned by `country` |
| `hudi_cm_deal_query_emea` | `email_campaign.deal_query` (EMEA) | upsert | `id` | Partitioned by `brand` |
| `hudi_gss_subscriptions_na` | `global_subscription_service.subscriptions` (NA) | upsert | `consumer_id,list_ns,list_id` | Bloom filter on `consumer_id` |
| `hudi_pts_device_token_na` | `mobile_push_token_service.device_tokens_new` (NA) | upsert | `device_token` | Partitioned by `token_status` |
| `hudi_pts_subscription_na` | `mobile_push_token_service.push_subscriptions` (NA) | upsert | `bcookie,sub_from,list_ns,list_id` | Partitioned by `list_ns,sub_from` |
| `hudi_na_email_rf_segment_affinity` | `arbitration.rf_user_elements` (NA) | insert_overwrite_table | `cid` | Full load |
| `hudi_arbitration_bg_cg_email_history_na` | `arbitration.bg_cg_email_history` (NA) | insert_overwrite_table | `cid` | Full load |
| `hudi_na_email_bg_cap` | `arbitration.bg_cg_cap_email_prod_v4` (NA) | insert_overwrite_table | composite | Full load |
| `hudi_na_bg_cg_days_gap` | `arbitration.bg_cg_days_gap` (NA) | insert_overwrite_table | composite | Full load |
| `hudi_na_email_user_features` | `arbitration.na_email_user_features` (NA) | insert_overwrite_table | `consumer_id` | Full load |
| `hudi_na_email_user_model_weights` | `arbitration.na_email_user_model_weights` (NA) | insert_overwrite_table | `consumer_id` | Full load |
| `hudi_na_email_campaign_features` | `arbitration.na_email_campaign_features` (NA) | insert_overwrite_table | `campaign_id` | Full load |
| `hudi_cid_open_time_buckets_na` | `arbitration.cid_open_time_buckets` (NA) | insert_overwrite_table | `cid,day_of_week` | Full load |
| `hudi_rf_segment_open_time_buckets_na` | `arbitration.rf_segment_open_time_buckets` (NA) | insert_overwrite_table | `rf_segment` | Full load |
| `hudi_na_mobile_click_time_buckets` | `arbitration.na_mobile_click_time_buckets` (NA) | insert_overwrite_table | `bcookie` | Full load |
| `hudi_na_mobile_app_open_time_buckets` | `arbitration.na_mobile_app_open_time_buckets` (NA) | insert_overwrite_table | `bcookie` | Full load |
| `hudi_bcookie_platform_na` | `arbitration.bcookie_platform` (NA) | insert_overwrite_table | `bcookie` | Full load |
| `hudi_na_mobile_rf_segment_click_time_buckets` | `arbitration.na_mobile_rf_segment_click_time_buckets` (NA) | insert_overwrite_table | composite | Full load |
| `hudi_na_push_rf_segment_affinity` | `arbitration.pn_rf_user_elements` (NA) | insert_overwrite_table | `bcookie` | Full load |
| `hudi_arbitration_bg_cg_push_history_na` | `arbitration.bg_cg_mobile_history` (NA) | insert_overwrite_table | `bcookie` | Full load |
| `hudi_norpm_ranking_cg_pn_na` | `arbitration.pn_norpm_ranking_affinity` (NA) | insert_overwrite_table | composite | Full load |
| `hudi_na_push_bg_cap` | `arbitration.bg_cg_cap_pn_prod_v4` (NA) | insert_overwrite_table | composite | Full load |
| `hudi_na_country_cap_v2` | `arbitration.country_cap_v2` (NA) | insert_overwrite_table | composite | Full load |
| `hudi_norpm_ranking_affinity_na_email` | `arbitration.norpm_ranking_affinity` (NA) | insert_overwrite_table | composite | Full load |
| `hudi_norpm_ranking_bg_affinity_na_email` | `arbitration.norpm_ranking_bg_affinity` (NA) | insert_overwrite_table | composite | Full load |
| `hudi_na_email_model` | `arbitration.na_email_model` (NA) | insert_overwrite_table | composite | Full load |
| `hudi__checkpoint_table` | Internal | upsert | per-job checkpoint key | Tracks incremental sync watermarks |

#### Access Patterns

- **Read**: Silver and gold Spark jobs read Hudi tables using Hudi Spark catalog (`org.apache.spark.sql.hudi.catalog.HoodieCatalog`).
- **Write**: DataSyncCore writes using `df.write.format("hudi").mode(SaveMode.Append)` with MERGE_ON_READ table type. Upsert operations use record key and precombine key; full-load operations use `insert_overwrite_table`.
- **Indexes**: Hudi metadata index enabled (`hoodie.metadata.enable=true`); column stats indexes and bloom filter indexes configured per table.

### PostgreSQL Operational Databases (`externalPostgresOperationalDatabases`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `externalPostgresOperationalDatabases` (stub) |
| Purpose | Source of truth for campaign, subscription, arbitration, and push token data |
| Ownership | external (read-only) |

#### Source Databases

| Database | JDBC Host | Schema | Tables Read |
|----------|-----------|--------|-------------|
| Email Campaign Management (NA) | `email-campaign-management-ro-na-production-db.gds.prod.gcp.groupondev.com:5432/email_campaign_prod` | `email_campaign` | `campaign`, `deal_query` |
| Email Campaign Management (EMEA) | `email_campaign_management-ro-emea-production-db.gds.prod.gcp.groupondev.com:5432/email_campaign_prod` | `email_campaign` | `campaign`, `deal_query` |
| Global Subscription Service (NA) | `global-subscription-service-ro-na-production-db.gds.prod.gcp.groupondev.com:5432/global_subscription_service_prod` | `global_subscription_service` | `subscriptions` |
| Arbitration Service (NA) | `arbitration-service-rw-na-production-db.gds.prod.gcp.groupondev.com:5432/arbitration_prod` | `arbitration` | Multiple tables (rf_user_elements, bg_cg_email_history, etc.) |
| Push Token Service (NA) | `push-token-service-ro-na-production-db.gds.prod.gcp.groupondev.com:5432/mobile_push_token_service_prod` | `mobile_push_token_service` | `device_tokens_new`, `push_subscriptions` |

#### Access Patterns

- **Read**: Checkpoint-aware JDBC queries — `SELECT <columns> FROM <table> WHERE <checkpoint_col> > '<last_checkpoint>'` for incremental loads; full table scan for full loads.
- **Partition bounds**: Service computes `MIN`/`MAX` of the partition column via a pre-query to enable parallel JDBC reads across multiple Spark partitions (default: 10–500 partitions depending on table).
- **Fetch size**: Configurable per flow; typically 3,000–10,000 rows per batch.

## Caches

> No evidence found in codebase. No caching layer is used.

## Data Flows

Source PostgreSQL databases feed the Hudi bronze lake via incremental or full-load JDBC extraction. Bronze Hudi tables are consumed by downstream silver transformation Spark jobs (e.g., `GSSTransformationJobNA`, `EmailCampaignTransformerNA`) which produce silver Hudi tables. Gold processor jobs (e.g., `NAEmailArbitrationProcessor`, `NAPushArbitrationProcessor`) then process silver data to produce final audience sets for campaign dispatch.
