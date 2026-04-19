---
service: "ads-jobframework"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumAdsJobframeworkHiveWarehouse"
    type: "hive"
    purpose: "Primary source and sink for ad event data, reporting tables, and taxonomy"
  - id: "continuumAdsJobframeworkMySql"
    type: "mysql"
    purpose: "Ad inventory and campaign metadata"
  - id: "continuumAdsJobframeworkTeradata"
    type: "teradata"
    purpose: "PPID audience export source"
  - id: "continuumAdsJobframeworkGcsBucket"
    type: "gcs"
    purpose: "Output sink for feed files and audience exports"
---

# Data Stores

## Overview

ads-jobframework is a Spark batch processor that reads from and writes to four data stores: the Groupon Hive Data Lake (primary read source and write destination for reporting tables), a MySQL database (ad inventory metadata), Teradata (PPID audience source), and GCS (output file feeds). The service does not own a primary operational database — it reads from shared enterprise data sources and writes derived analytics back into Hive or GCS.

## Stores

### Groupon Data Lake / Hive (`continuumAdsJobframeworkHiveWarehouse`)

| Property | Value |
|----------|-------|
| Type | hive |
| Architecture ref | `continuumAdsJobframeworkHiveWarehouse` |
| Purpose | Read source for raw event data and taxonomy; write destination for aggregated reporting tables |
| Ownership | shared |
| Migrations path | Not applicable — external data lake |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `grp_gdoop_pde.junoHourly` | Raw hourly event log (impressions, clicks, page views, email events) | `eventdate`, `eventtime`, `sponsoredadid`, `eventdestination`, `platform`, `bcookie`, `dealuuid`, `event` |
| `user_edwprod.fact_gbl_transactions` | Global transaction fact table for order attribution | `ds`, `action`, `order_uuid`, `user_uuid`, `deal_uuid`, `bcookie`, `auth_nob_loc`, `auth_nor_loc`, `country_id` |
| `cia_realtime.user_attrs_gbl` | Global customer demographic attributes | `consumer_id`, `record_date`, `age`, `gender`, `last_billing_zip`, `country_code`, `last_purchase_date` |
| `cia_realtime.user_attrs` | US customer behavioral attributes for uplift modeling | `consumer_id`, `record_date`, `recency_9block`, `frequency_9block`, `purchase_count_30`, `predicted_cv`, `gender` |
| `cia_realtime.user_attr_daily` | Daily user attribute snapshots (US) | `consumer_id`, `record_date` |
| `cia_realtime.user_attr_daily_intl` | Daily user attribute snapshots (international) | `consumer_id`, `record_date` |
| `grp_gdoop_marketing_analytics_db.me_orders_fgt` | Marketing-attributed order data | `transaction_date`, `bcookie`, `deal_id`, `order_uuid`, `country_id`, `attribution_type` |
| `prod_groupondw.dim_gbl_deal_lob` | Deal-to-category taxonomy mapping | `deal_id`, `country_id`, `pds_cat_id`, `grt_l1_cat_name`, `grt_l2_cat_name` |
| `prod_groupondw.dim_category_relation` | Category hierarchy relationship map | `source_category_id`, `target_category_id` |
| `prod_groupondw.dim_segment_category_map` | Category-to-segment mapping | `category_id`, `taxonomy_name` |
| `ai_reporting.pv_with_impressions` | Aggregated US web page-views with ad impression and click metrics | `pageid`, `eventdate`, `ad_impression`, `impression`, `impression_click` |
| `ai_reporting.pv_with_impressions_intl` | International variant of `pv_with_impressions` | `pageid`, `eventdate` |
| `ai_reporting.sl_imp_clicks` | Sponsored listing impressions, clicks, and attributed orders (web) | `bcookie`, `dealuuid`, `eventdate`, `platform`, `partition_name` |
| `grp_gdoop_local_ds_db.est_maxcpc_by_dealid` | ROAS-based max CPC recommendations per deal | `dealuuid`, `maxcpc_roas2` |

#### Access Patterns

- **Read**: Spark SQL queries with date-range predicates on partition columns (`eventdate`, `ds`, `record_date`) to limit scan scope
- **Write**: `insertInto` (append mode) for `pv_with_impressions`; `write.mode(SaveMode.Overwrite).saveAsTable` for blocklist tables; `insert overwrite ... PARTITION` for `sl_imp_clicks`
- **Indexes**: Hive partition pruning on `eventdate`, `ds`, `record_date`

---

### Ads Jobframework MySQL (`continuumAdsJobframeworkMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumAdsJobframeworkMySql` |
| Purpose | Ad inventory and campaign metadata (e.g., `citrusad_campaigns`) |
| Ownership | owned |
| Migrations path | Not discoverable from this repo |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `ad_inv_serv_prod.*` (prod) / `ad_inv_serv_stg.*` (staging) | Ad inventory and CitrusAd campaign metadata | Campaign IDs, wallet IDs, deal UUIDs |

#### Access Patterns

- **Read**: JDBC queries via Spark `spark.read.jdbc` for campaign and inventory metadata joins
- **Write**: Not observed from this repo
- **Indexes**: Not discoverable from this repo

---

### Teradata Sandbox (`continuumAdsJobframeworkTeradata`)

| Property | Value |
|----------|-------|
| Type | teradata |
| Architecture ref | `continuumAdsJobframeworkTeradata` |
| Purpose | PPID (Publisher Provided Identifier) audience export source for DFP targeting |
| Ownership | external / shared |
| Migrations path | Not applicable — external source |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `sandbox.ppid_export` | PPID audience members for DFP audience targeting | `cookie_encrypted`, `list_id`, `delete`, `process_consent` |

#### Access Patterns

- **Read**: Full table scan via Teradata JDBC using `PPIDAudienceJob` (via CDE `TeraDataSparkConnection`)
- **Write**: None — Teradata is read-only for this service
- **Indexes**: Not discoverable from this repo

---

### GCS Analytics Bucket (`continuumAdsJobframeworkGcsBucket`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `continuumAdsJobframeworkGcsBucket` |
| Purpose | Output sink for all file-based feeds and audience exports delivered to CitrusAd and DFP |
| Ownership | owned (prod: `grpn-dnd-prod-analytics-grp-ai-reporting`) |
| Migrations path | Not applicable — object storage |

#### Key Entities

| Path | Purpose | Format |
|------|---------|--------|
| `gs://{bucket}/user/grp_gdoop_ai_reporting/feed/customer` | Hashed customer demographic feed for CitrusAd | TSV (tab-delimited, header, 10 partitions) |
| `gs://{bucket}/user/grp_gdoop_ai_reporting/feed/order/deal` | Hashed order/session feed for CitrusAd conversion attribution | TSV (tab-delimited, header, 1 partition) |
| `gs://{bucket}/user/grp_gdoop_ai_reporting/feed/deal_max_cpc` | ROAS-based max CPC recommendations per deal | TSV.gz (gzip compressed) |
| `gs://gdfp_cookieupload_21693248851/PPID_audience_export_{datetime}.csv` | SHA-256 hashed PPID audience export for DFP | CSV with header, max 10M rows per file |

#### Access Patterns

- **Read**: Not observed for GCS (write-only sink)
- **Write**: Overwrite mode; `coalesce(1)` or `coalesce(10)` to control output file count; CSV/TSV format via `com.databricks.spark.csv`

## Caches

> No evidence found in codebase. No caching layer is in use.

## Data Flows

1. `grp_gdoop_pde.junoHourly` (Hive) is read by impression/click report jobs and SL aggregation jobs; results are posted as HTTP callbacks to CitrusAd and written into `ai_reporting.*` Hive tables.
2. `user_edwprod.fact_gbl_transactions` (Hive) is read by `OrderFeedJob` and `UpliftModelPrediction`; results are written to GCS feeds or Hive blocklist tables.
3. `cia_realtime.user_attrs_gbl` (Hive) is read by `CustomerFeedJob`; hashed results are written to GCS customer feed.
4. `sandbox.ppid_export` (Teradata) is read by `PPIDAudienceJob`; SHA-256 hashed results are written to GCS PPID CSV.
5. `ai_reporting.pv_with_impressions` (Hive) is produced by `PVWithImpressions` and consumed by downstream analytics dashboards.
