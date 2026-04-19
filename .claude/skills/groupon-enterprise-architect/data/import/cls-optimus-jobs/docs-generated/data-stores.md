---
service: "cls-optimus-jobs"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumClsHiveWarehouse"
    type: "hive"
    purpose: "Source and target Hive tables for all CLS non-ping location pipelines"
---

# Data Stores

## Overview

CLS Optimus Jobs operates exclusively against the `grp_gdoop_cls_db` Hive database (the CLS Hive Warehouse) hosted on the Cerebro Hadoop cluster. This database serves as both the landing zone for ingested location data and the final target for coalesced non-ping records. An intermediate HDFS landing path under `/user/grp_gdoop_cls/optimus/` is used as a staging area for Teradata-exported files before Hive loads. The job suite reads source records from the Janus dataset (`grp_gdoop_pde.janus_all`) and transactional databases accessed via Teradata DSNs.

## Stores

### CLS Hive Warehouse (`continuumClsHiveWarehouse`)

| Property | Value |
|----------|-------|
| Type | Hive (ORC, TextInputFormat) |
| Architecture ref | `continuumClsHiveWarehouse` |
| Purpose | Source and target for all CLS non-ping billing, shipping, CDS, and coalesce pipelines |
| Ownership | owned |
| Migrations path | Not applicable — tables are created/recreated via `CREATE TABLE IF NOT EXISTS` / `DROP TABLE` statements within job HQL |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `grp_gdoop_cls_db.cls_billing_address_na` | Stores NA billing addresses extracted from Teradata `user_gp.user_billing_records` | `billing_uuid`, `consumer_id`, `city`, `state`, `country_code`, `postal_zipcode`, `created_at`, `updated_at`, partition: `record_date` |
| `grp_gdoop_cls_db.cls_billing_address_emea` | Stores EMEA billing addresses extracted from Teradata EMEA billing system | `billing_uuid`, `consumer_id`, `city`, `state`, `country_code`, `postal_zipcode`, `created_at`, `updated_at`, partition: `record_date` |
| `grp_gdoop_cls_db.cls_billing_address_na_tmp` / `cls_billing_address_na_tmpTbl` | Temporary external table pointing to HDFS billing/na landing zone; dropped and recreated per job run | `billing_uuid`, `consumer_id`, `city`, `state`, `country_code`, `postal_zipcode`, `created_at`, `updated_at` |
| `grp_gdoop_cls_db.cls_billing_address_emea_tmpTbl` | Temporary external table pointing to HDFS billing/emea landing zone | `billing_uuid`, `consumer_id`, `city`, `state`, `country_code`, `postal_zipcode`, `created_at`, `updated_at` |
| `grp_gdoop_cls_db.cls_shipping_na` | Stores NA shipping address data from Teradata `user_gp.orders` | `orders_uuid`, `consumer_id`, `shipping_city`, `shipping_state`, `shipping_country`, `shipping_zip`, `created_at`, `updated_at`, `record_date`, partition: `country_code` |
| `grp_gdoop_cls_db.cls_shipping_emea` | Stores EMEA shipping address data from Teradata EMEA orders | `orders_uuid`, `consumer_id`, `shipping_city`, `shipping_state`, `shipping_country`, `shipping_zip`, `created_at`, `updated_at`, `record_date`, partition: `country_code` |
| `grp_gdoop_cls_db.cls_shipping_na_ext` | External table pointing to HDFS shipping/na landing zone | `orders_uuid`, `consumer_id`, `shipping_city`, `shipping_state`, `shipping_country`, `country_code`, `shipping_zip`, `created_at`, `updated_at` |
| `grp_gdoop_cls_db.cls_shipping_emea_ext` | External table pointing to HDFS shipping/emea landing zone | Same structure as `cls_shipping_na_ext` |
| `grp_gdoop_cls_db.cls_user_profile_locations_na` | Stores CDS user profile location records from `user_gp.user_profile_locations` and Janus | `cds_cid`, `cds_consumer_id`, `cds_location_tag`, `cds_rounded_latitude`, `cds_rounded_longitude`, `cds_city`, `cds_state`, `cds_zipcode`, `record_date`, partition: `cds_country_code` |
| `grp_gdoop_cls_db.coalesce_nonping` | Final unified non-ping location dataset (delta loads write directly here) | `consumer_id`, `bcookie`, `location_tag`, `rounded_latitude`, `rounded_longitude`, `pipeline_source`, `division`, `created_at`, `updated_at`, `nonping_city`, `nonping_state`, `postal_zipcode`, `record_date`, partitions: `country_code`, `record_month` |
| `grp_gdoop_cls_db.coalesce_nonping_staging` | Staging target for backfill coalesce jobs | Same schema as `coalesce_nonping` |
| `grp_gdoop_cls_db.coalesce_nonping_billing_na_temp` | Intermediate temp table for billing NA coalesce transform step | Same schema as `coalesce_nonping` |
| `grp_gdoop_cls_db.coalesce_nonping_billing_emea_temp` | Intermediate temp table for billing EMEA coalesce transform step | Same schema as `coalesce_nonping` |
| `grp_gdoop_cls_db.coalesce_nonping_shipping_na_temp` | Intermediate temp table for shipping NA coalesce transform step | Same schema as `coalesce_nonping` |
| `grp_gdoop_cls_db.coalesce_nonping_shipping_emea_temp` | Intermediate temp table for shipping EMEA coalesce transform step | Same schema as `coalesce_nonping` |
| `grp_gdoop_cls_db.coalesce_nonping_cds_na_temp` | Intermediate temp table for CDS NA coalesce transform step | Same schema as `coalesce_nonping` |
| `grp_gdoop_cls_db.country_pincode_lat_lng_lookup_optimized` | Reference table mapping postal code + country code to rounded latitude/longitude | `strippped_zipcode`, `country_code`, `rounded_latitude`, `rounded_longitude` |
| `grp_gdoop_pde.janus_all` | External Janus event dataset — source for CDS Janus delta job | `consumerId`, `locationtypename`, `latitude`, `longitude`, `eventtime`, `city`, `geostate`, `postalcode`, `country`, `ds`, `event` |

#### Access Patterns

- **Read**: Jobs query source tables filtered by `record_date` (delta) or without date filter (backfill); UUID regex validation applied in WHERE clause to filter malformed `consumer_id` values.
- **Write**: INSERT INTO ... PARTITION with dynamic partitioning enabled (`hive.exec.dynamic.partition.mode = nostrict`); ORC format used for managed tables; temp tables are dropped and recreated at the start of each coalesce job run.
- **Indexes**: No explicit Hive indexes configured; partitioning on `record_date`, `country_code`, and `record_month` provides partition pruning.

## Caches

> No evidence found in codebase. No caching layer is used by this service.

## Data Flows

Data moves through two distinct phases:

1. **Ingestion phase**: Teradata transactional data is exported to local files via Optimus `SQLExport` tasks, then copied to HDFS (`/user/grp_gdoop_cls/optimus/billing/`, `/shipping/`, `/cds/`) via `RemoteHadoopClient.py`. External Hive tables are pointed at these HDFS paths and data is loaded into partitioned managed tables via `INSERT INTO ... SELECT FROM`.

2. **Coalesce phase**: Each source table (`cls_billing_address_na`, `cls_billing_address_emea`, `cls_shipping_na`, `cls_shipping_emea`, `cls_user_profile_locations_na`) is read into a per-source temp table with normalisation applied (UUID filter, zipcode validation, country code allowlist). Temp table records are then joined against `country_pincode_lat_lng_lookup_optimized` to enrich with lat/lng and inserted into `coalesce_nonping_staging` (backfill) or `coalesce_nonping` (delta).

Table information: [CLS Hive Tables on Confluence](https://confluence.groupondev.com/pages/viewpage.action?spaceKey=MAR&title=Customer+Location+Service+Tables)
