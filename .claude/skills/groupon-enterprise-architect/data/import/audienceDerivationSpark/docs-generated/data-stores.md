---
service: "audienceDerivationSpark"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "hdfsStorage"
    type: "hdfs"
    purpose: "Configuration file staging and derived table output storage"
  - id: "hiveMetastore"
    type: "hive"
    purpose: "Source and derived audience table storage"
---

# Data Stores

## Overview

Audience Derivation Spark reads from and writes to the Groupon Hadoop data ecosystem. Source data lives in Hive tables backed by HDFS on the Cerebro cluster. Derived output tables are written back to Hive, also backed by HDFS. YAML configuration files that drive the derivation pipeline are staged to HDFS before each job run. The service also writes audience payload records to Cassandra (via `audiencepayloadspark`) and delta attribute records to Bigtable, though those stores are managed by the `audiencepayloadspark` dependency rather than directly by this repo.

## Stores

### HDFS Storage (`hdfsStorage`)

| Property | Value |
|----------|-------|
| Type | hdfs |
| Architecture ref | `hdfsStorage` |
| Purpose | Config file staging (YAML derivation config dirs) and intermediate/output table data |
| Ownership | shared |
| Migrations path | Not applicable |

#### Key Paths

| Path | Purpose |
|------|---------|
| `hdfs://cerebro-namenode/user/audiencedeploy/derivation/{stage}/` | Root for derivation YAML config uploads |
| `hdfs://cerebro-namenode/user/audiencedeploy/derivation/{stage}/usersTablesNA/` | NA users derivation YAML config |
| `hdfs://cerebro-namenode/user/audiencedeploy/derivation/{stage}/usersTablesEMEA/` | EMEA users derivation YAML config |
| `hdfs://cerebro-namenode/user/audiencedeploy/derivation/{stage}/bcookieTablesNA/` | NA bcookie derivation YAML config |
| `hdfs://cerebro-namenode/user/audiencedeploy/derivation/{stage}/bcookieTablesEMEA/` | EMEA bcookie derivation YAML config |

#### Access Patterns

- **Read**: Spark jobs read YAML config files at job startup to load tempview query sequences
- **Write**: `fabfile.py` deploy task uploads config directories; Spark Hive jobs write derived table data to HDFS-backed Hive locations

### Hive Metastore (`hiveMetastore`)

| Property | Value |
|----------|-------|
| Type | hive |
| Architecture ref | `hiveMetastore` |
| Purpose | Source and derived audience tables — primary input/output store for the derivation pipeline |
| Ownership | shared |
| Migrations path | Table DDL generated from YAML config (`generalTableQueries` in config YAML) |

#### Key Source Tables (Inputs)

| Table | Region | Purpose | Key Fields |
|-------|--------|---------|-----------|
| `prod_groupondw.user_entity_attribute_02` | NA | Core user attributes | `user_key`, `user_id`, `consumer_id`, `email_domain`, `active_customer`, `gender`, `country` |
| `prod_groupondw.user_entity_attribute_03` | NA | User engagement metrics | matchkeys 1–15, email/site/mobile engagement days |
| `prod_groupondw.mobile_push_notification` | NA/EMEA | Bcookie mobile engagement data | `bcookie`, `platform`, `user_uuid`, `country_code`, push engagement metrics |
| `cia_realtime.user_attr_daily` | NA | Daily user attribute snapshot | user-level daily attribute fields |
| Various EMEA source tables | EMEA | EMEA user entity attributes, subscriptions, billing | country_id, user_id, subscription data |

#### Key Derived Output Tables

| Table | Region | Purpose | Partition Keys |
|-------|--------|---------|----------------|
| `users_derived_{timestamp}` | NA | Enriched NA users system table | `user_category`, `user_brand_affiliation` |
| `users_derived_{timestamp}` | EMEA | Enriched EMEA users system table | `user_category`, `country_iso_code_2` |
| `bcookie_derived_{timestamp}` | NA/EMEA | Enriched bcookie (mobile) system table | (no partition shown in config) |
| LINK SAD base table | NA/EMEA | Deal-targeting optimization base dataset | Derived by `LinkSadBaseTableGenerator` |

#### Key Intermediate Tempviews (NA Users Pipeline — 17 steps)

| Tempview | Step | Purpose |
|----------|------|---------|
| `user_entity_attribute_02_derived` | 01–02 | Source user attributes with date casting and derived fields (age, deal buckets, timezone) |
| `user_entity_attribute_03` | 02 | User engagement attributes |
| `user_category` | 03 | User category classification |
| `dim_user` | 05 | Dimension user join |
| `customer_agg_entity` | 06 | Customer aggregation attributes |
| `living_social_attr` | 11 | LivingSocial user attributes |
| `agg_user_ord_seg_day_na` | 12 | Order/segment aggregations |
| `temp_users_derived_table` | 13 | Pre-final assembly tempview |
| `purchase_targeting_agg` | 14 | Purchase targeting aggregations |
| `user_attr_daily` | 15 | Daily attribute snapshot |
| `users_tempview` | 16 | Final pre-write tempview |
| `users_derived` | 17 | Final output write |

#### Access Patterns

- **Read**: Spark SQL reads source Hive tables at job start; each tempview step reads the previous step's output
- **Write**: Final `INSERT OVERWRITE TABLE` writes the derived timestamped table; partition mode is `nonstrict` dynamic partitioning
- **Indexes**: Hive partitioning by `user_category` / `user_brand_affiliation` (NA) or `user_category` / `country_iso_code_2` (EMEA)

## Caches

> No caches are used by this service. Spark in-memory caching of DataFrames/RDDs may occur within job execution for performance, but no persistent external cache stores are used.

## Data Flows

1. YAML configuration files are uploaded from `config/` directories to `hdfs://cerebro-namenode/user/audiencedeploy/derivation/{stage}/{configDir}/` during `fab deploy`.
2. At job start, the Spark application reads YAML configs from HDFS to build the ordered list of tempview SQL steps.
3. Each tempview step reads from the previous step (or a source Hive table) and registers a new Spark SQL tempview.
4. After all tempview steps complete, the final `INSERT OVERWRITE TABLE` writes the derived timestamp-named table to the Hive Metastore.
5. After successful derivation, `FieldSyncMain` reads the derived schema from Hive and syncs field metadata to the AMS MySQL database.
6. Base table Parquet files for testing are stored in `base_tables/` within the repo (e.g., `base_tables/users_derived_na/`, `base_tables/bcookie_derived_emea/`).
