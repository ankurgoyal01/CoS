---
service: "afgt"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumAfgtHiveDataset"
    type: "hive-on-gcs"
    purpose: "Final and staging AFGT analytics tables in the IMA data lake"
  - id: "edw"
    type: "teradata"
    purpose: "Source enterprise data warehouse for transaction and dimension data"
---

# Data Stores

## Overview

AFGT reads from the Teradata Enterprise Data Warehouse (EDW) as its primary source and writes to the IMA Hive data lake on Google Cloud Storage as its final destination. The pipeline uses ephemeral intermediate Teradata tables in the `sb_rmaprod` sandbox schema for staging between BTEQ steps. Hive tables reside in GCS buckets managed by the IMA (Integrated Marketing Analytics) data store. AFGT does not own or manage any caches.

## Stores

### AFGT Hive Dataset (`continuumAfgtHiveDataset`)

| Property | Value |
|----------|-------|
| Type | Hive on GCS |
| Architecture ref | `continuumAfgtHiveDataset` |
| Purpose | Stores the staging table and final partitioned analytics table for AFGT output |
| Ownership | owned (written by this pipeline) |
| Migrations path | `source/sql/hive_load_final.hql`, `afgt_zr/hive_load_final.hql` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `ima.analytics_fgt_tmp_zo` | Sqoop-imported staging table from Teradata; intermediate input for final Hive load | `transaction_date`, `country_id`, `unified_user_id`, `unified_deal_id`, `order_uuid`, `parent_order_uuid` |
| `ima.analytics_fgt` | Final analytics table partitioned by `transaction_date` and `country_id`; consumed by BI/reporting | `transaction_date`, `country_id`, `unified_user_id`, `platform_key`, `action`, `gross_bookings_loc`, `gross_revenue_loc`, `auth_nob_loc`, `auth_nor_loc`, `ogp_loc`, `rfm_code`, `rfm_segment`, `go_segment`, `traffic_source`, `attribution_type` |

#### Access Patterns

- **Read**: `ima.analytics_fgt_tmp_zo` is read by `hive_load_final.hql` to JOIN with `ima.user_rfm_segment_act_react` and produce the final insert
- **Write**: `analytics_fgt_tmp_zo` is written via Sqoop import (20 mappers, split by `transaction_date`, field delimiter `\001`); `analytics_fgt` is written via `INSERT OVERWRITE ... PARTITION(transaction_date, country_id)` using dynamic partitioning with Tez engine
- **Indexes**: Dynamic partitioning on `transaction_date` and `country_id`; vectorized execution enabled; `hive.exec.max.dynamic.partitions` set to 10000

---

### Teradata Enterprise Data Warehouse (`edw`)

| Property | Value |
|----------|-------|
| Type | Teradata |
| Architecture ref | `edw` (external stub) |
| Purpose | Source of global financial transaction records, dimension tables, OGP, ILS, attribution, and segment data |
| Ownership | external (read-only; owned by EDW team) |
| Migrations path | Not applicable — read-only access via BTEQ/JDBC |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `user_edwprod.fact_gbl_transactions` | Primary source of global transaction facts | `transaction_date`, `order_uuid`, `parent_order_uuid`, `country_id`, `platform_key`, `action`, `transaction_qty`, `gross_bookings_loc` |
| `sb_rmaprod.analytics_fgt` | Teradata final AFGT table (pre-GCP); used for deactivation backfill window | `transaction_date`, `country_id`, `unified_user_id` |
| `sb_rmaprod.analytics_fgt_transfer_gcp` | Transfer staging table populated by BTEQ, then Sqoop-exported to Hive | All columns of `analytics_fgt` |
| `sb_rmaprod.afgt_stg1` through `sb_rmaprod.afgt_stg4` | Intermediate staging tables populated by `sb_afgt_stg1.sh` through stage 4 scripts | Various enrichment columns added at each stage |
| `sb_rmaprod.afgt_deal` | Deal dimension staging table populated by `sb_deals.sh` | `unified_deal_id`, `deal_permalink`, `pds_cat_id`, `grt_l1_cat_name` through `grt_l5_cat_name`, `is_wow`, `is_national` |
| `user_edwprod.fact_gbl_ogp_transactions` | Source for OGP and VFM amounts per transaction | `transaction_date`, `order_id`, `country_id`, `action`, `ogp_loc`, `vfm_od_loc`, `vfm_ils_loc` |
| `user_groupondw.gbl_order_attribution` | Global order attribution data for marketing attribution enrichment | `order_uuid`, `parent_order_uuid`, `country_id`, `attribution_type`, `ref_attr_class_key` |
| `user_groupondw.ref_attr_class_v2` | Attribution class reference for traffic source/type/sub-source lookup | `ref_attr_class_key`, `attribution_type`, `traffic_type`, `traffic_source`, `traffic_sub_source` |
| `user_edwprod.ils_deal_selection_log_raw` | ILS (Instant Local Sale) pricing log for EMEA discount calculation | `inventory_product_id`, `sale_start_utc`, `offer_sell_price`, `post_offer_sell_price` |
| `ima.user_rfm_segment_act_react` | RFM segment dimension for consumer segmentation enrichment (Hive) | `country_id`, `consumer_id`, `rfm_code`, `rfm_segment`, `valid_from`, `valid_end` |
| `sb_rmaprod.customer_go_segmentation` | GO segmentation (go_segment field) source | `consumer_id`, `report_date`, `go_segment` |

#### Access Patterns

- **Read**: BTEQ `.logon` connections using `$TD_DSN_NAME/$USER_TD,$USER_TD_PASS`; connection DSN `teradata.groupondev.com`, port 1025, default DB `sb_rmaprod`, user `ub_ma_emea`
- **Write**: BTEQ `DELETE` and `INSERT INTO` operations on `sb_rmaprod.*` staging tables; these are Teradata sandbox tables owned by the pipeline
- **Indexes**: Teradata Primary Index implicit on key columns; Sqoop uses `--split-by transaction_date` with `--num-mappers 20`

## Caches

> Not applicable — AFGT does not use any cache layer.

## Data Flows

1. Teradata EDW (`user_edwprod.fact_gbl_transactions`) is queried via BTEQ to populate `sb_rmaprod.afgt_stg1` through `sb_rmaprod.afgt_stg4` across multiple enrichment stages.
2. The enriched data from `sb_rmaprod.afgt_stg4` is written to `sb_rmaprod.analytics_fgt` (Teradata final table) via `sb_final_table.sh`.
3. The BTEQ extraction script (`afgt_td_extract.sh`) copies a date-windowed slice of `sb_rmaprod.analytics_fgt` plus a 386-day deactivation backfill window into `sb_rmaprod.analytics_fgt_transfer_gcp`.
4. Sqoop imports `sb_rmaprod.analytics_fgt_transfer_gcp` from Teradata JDBC into `ima.analytics_fgt_tmp_zo` on GCS (20 mappers, field delimiter `\001`).
5. `hive_load_final.hql` reads `ima.analytics_fgt_tmp_zo`, joins with `ima.user_rfm_segment_act_react` for RFM scores, and writes the final `ima.analytics_fgt` table partitioned by `transaction_date` and `country_id`.
