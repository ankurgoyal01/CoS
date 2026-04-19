---
service: "seo-deal-redirect"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumSeoHiveWarehouse"
    type: "hive"
    purpose: "Primary staging and output tables for redirect pipeline"
  - id: "gcpCloudStorage"
    type: "gcs"
    purpose: "Reference data CSVs, Parquet artifacts, and processed redirect snapshots"
  - id: "edwprod-hive"
    type: "hive"
    purpose: "Source deal and merchant data from Groupon EDW"
---

# Data Stores

## Overview

SEO Deal Redirect uses Apache Hive (via GCP Dataproc Metastore) as its primary data store for pipeline staging tables and output. GCP Cloud Storage (GCS) provides reference data (exclusion lists, manual redirects, taxonomy Parquet files) and intermediate Parquet output. The pipeline reads source deal data from the Groupon Enterprise Data Warehouse (EDW) Hive databases. The service owns its SEO-specific Hive database but reads from several shared EDW databases.

## Stores

### SEO Hive Warehouse (`continuumSeoHiveWarehouse`)

| Property | Value |
|----------|-------|
| Type | Hive (GCP Dataproc Metastore) |
| Architecture ref | `continuumSeoHiveWarehouse` |
| Purpose | Pipeline staging and output tables |
| Ownership | owned |
| Migrations path | `exclusion/ddl/`, `manual_redirects/ddl/`, `api_upload_table_population/ddl/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `grp_gdoop_seo_db.daily_deals` | Current snapshot of all eligible deals for the run date | `deal_uuid`, `deal_permalink`, `merchant_id`, `deal_lat`, `deal_lng`, `locality`, `pds_cat_id`, `grt_l2_cat_id`, `status`, `country` |
| `grp_gdoop_seo_db.daily_expired_to_live_deal_mapping` | Initial mapping of expired deal UUIDs to candidate live deal UUIDs | `expired_uuid`, `expired_deal_permalink`, `live_uuid`, `live_deal_permalink`, `country`, `confidence_level`, `dt` |
| `grp_gdoop_seo_db.daily_expired_to_live_deduped` | Deduplicated redirect mappings (most recent + highest confidence per expired deal) | `expired_uuid`, `live_uuid`, `dt`, `confidence_level` |
| `grp_gdoop_seo_db.daily_expired_to_live_no_cycles` | Final mappings with redirect cycles removed | `expired_uuid`, `live_uuid`, `expired_deal_permalink`, `live_deal_permalink`, `country` |
| `final_redirect_mapping` | Final output table; complete redirect rows with full live deal URLs and action flags | `expired_uuid`, `expired_deal_permalink`, `live_uuid`, `live_deal_url`, `action`, `country`, `dt` |
| `grp_gdoop_seo_db.deal_exclusion_list` | Deals explicitly excluded from redirect processing | `deal_uuid`, `deal_permalink`, `dt` |
| `grp_gdoop_seo_db.deal_exclusion_list_raw` | Raw external table loaded from exclusion CSV | `deal_uuid`, `deal_permalink` |
| `grp_gdoop_seo_db.manual_redirects` | Partitioned table of manually defined expired-to-live mappings | `expired_uuid`, `live_uuid`, `dt` |
| `grp_gdoop_seo_db.manual_redirects_raw` | Raw external table loaded from manual redirects CSV | `expired_uuid`, `live_uuid` |
| `grp_gdoop_seo_db.pds_blacklist` | PDS category IDs excluded from non-active merchant redirect processing | `pds_id` |
| `grp_gdoop_seo_db.processed_non_active_merchant_redirects` | Audit table for non-active merchant redirect results | `deal_uuid`, `redirect_to`, `run_date` |
| `grp_gdoop_seo_db.previously_processed_redirects` | Snapshot of last API upload run used to detect new/changed deals | `expired_uuid`, `expired_deal_permalink`, `live_deal_url` |
| `grp_gdoop_seo_db.deal_performance` | Aggregated performance metrics for pre-2019 deals | `deal_uuid`, `dt` |

#### Access Patterns

- **Read**: Hive SQL via PySpark `HiveContext`; partitioned reads filtered on `dt` to limit scanned data
- **Write**: Hive `INSERT OVERWRITE` and `INSERT INTO ... PARTITION(dt=...)` statements; Spark `DataFrame.write.parquet()` for `final_redirect_mapping`
- **Indexes**: Hive partitioning on `dt` column is the primary data pruning mechanism across all staging tables

### GCP Cloud Storage (`gcpCloudStorage`)

| Property | Value |
|----------|-------|
| Type | GCS (Object Storage) |
| Architecture ref | `gcpCloudStorage` (stub) |
| Purpose | Reference data, Parquet artifacts, initialization scripts |
| Ownership | shared |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Path | Purpose | Key Fields |
|----------------|---------|-----------|
| `data/prod/exclusion_list.csv` | Deal UUIDs excluded from redirect processing | `deal_uuid`, `deal_permalink` |
| `data/prod/manual_redirects.csv` | Manually defined expired-to-live redirect pairs | `expired_uuid`, `live_uuid` |
| `data/prod/pds_id_bl.csv` | PDS category ID blacklist | `pds_id` |
| `data/prod/lpapi/lpapi_localized_location_data.parquet` | LPAPI location reference data for non-active merchant job | `location_id`, `lat`, `lon`, locale fields |
| `data/prod/taxonomies/*.parquet` | Merchant and customer taxonomy data for redirect URL construction | taxonomy IDs, permalinks |
| `{base_path}{final_write_path}/dt={run_date}/` | Parquet output of `final_redirect_mapping` per run date | `expired_uuid`, `live_deal_url`, `action` |
| `gs://grpn-dnd-prod-analytics-common/` | Shared analytics GCS bucket; holds init scripts and common artifacts | — |

#### Access Patterns

- **Read**: `gsutil` / Spark `read.parquet()` and `read.csv()` for reference data files; Spark reads Parquet output partitions
- **Write**: Spark `DataFrame.repartition(1).write.mode('append').partitionBy('dt').parquet(...)` writes final redirect output

### Groupon EDW — Source Databases

| Property | Value |
|----------|-------|
| Type | Hive (read-only source) |
| Architecture ref | > Not modeled as a separate container in this service's DSL |
| Purpose | Source of deal status, merchant, location, and category data |
| Ownership | external (EDW team) |
| Migrations path | > Not applicable — read-only |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `edwprod.ods_deal` | Master deal records including status and merchant linkage | `deal_uuid`, `deal_permalink`, `status`, `merchant_id` |
| `edwprod.ods_merch_product` | Merchant product data | `merchant_id`, `pds_cat_id` |
| `dw.mv_dim_pds_grt_map` | PDS-to-GRT category mapping | `pds_cat_id`, `grt_l2_cat_id` |
| `edwprod.redemption_location_unity` | Deal redemption location data (lat/lng, locality) | `deal_uuid`, `deal_lat`, `deal_lng`, `locality` |
| `svc_goods_bundling_db` (alias `goods_db`) | NA goods/bundled deal data | deal and mapping tables |
| `grp_gdoop_gods_db` (alias `goods_emea_db`) | EMEA goods deal data | deal and mapping tables |

## Caches

> No evidence found in codebase. No Redis, Memcached, or in-memory caching layer is used. The `previously_processed_redirects` Hive table provides a coarse run-to-run comparison cache for the API upload job.

## Data Flows

1. Reference CSV files are loaded from GCS into raw Hive external tables (`deal_exclusion_list_raw`, `manual_redirects_raw`, `pds_blacklist`) at the start of each DAG run.
2. Hive ETL scripts join EDW source tables (`edwprod.ods_deal`, `edwprod.redemption_location_unity`, etc.) to populate `daily_deals`.
3. `daily_deals` is joined with itself (expired status vs. launched status) to produce `daily_expired_to_live_deal_mapping`.
4. Deduplication and cycle-removal HQL scripts transform the mapping table through `daily_expired_to_live_deduped` → `daily_expired_to_live_no_cycles`.
5. The `api_upload_table_population` Spark job reads `daily_expired_to_live_no_cycles`, constructs full URLs, and writes Parquet output to GCS at `{base_path}/final_redirect_mapping/dt={run_date}/`.
6. Hive `MSCK REPAIR TABLE final_redirect_mapping` registers the new GCS partition.
7. The `api_upload` Spark job reads the Parquet output, diffs against `previously_processed_redirects`, and HTTP PUT's changed records to the SEO Deal API.
