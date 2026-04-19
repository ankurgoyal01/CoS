---
service: "AudienceCalculationSpark"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "hiveWarehouse"
    type: "hive"
    purpose: "Stores sourced, calculated, and published audience Hive tables"
  - id: "hdfsStorage"
    type: "hdfs"
    purpose: "Stores uploaded CSV source files and output PA CSV/JSON artifacts"
  - id: "cassandraAudienceStore"
    type: "cassandra"
    purpose: "Stores PA membership payloads for non-realtime audience delivery"
  - id: "bigtableRealtimeStore"
    type: "bigtable"
    purpose: "Stores realtime PA membership payloads (NA region only)"
---

# Data Stores

## Overview

AudienceCalculationSpark reads from and writes to four data stores. Hive and HDFS (both on CerebroV2) are the primary operational stores for audience table data and file artifacts. Cassandra stores PA payload membership for downstream non-realtime delivery, and GCP Bigtable provides realtime PA membership (NA only). The service does not own the schemas for any of these stores — they are shared infrastructure managed by the Audience Management and Data Systems teams.

## Stores

### Hive Warehouse (`hiveWarehouse`)

| Property | Value |
|----------|-------|
| Type | Apache Hive (Parquet/Snappy tables on CerebroV2 HDFS) |
| Architecture ref | `hiveWarehouse` |
| Purpose | Stores sourced audience (SA), calculated audience (CA), and published audience (PA) Hive tables used throughout the audience pipeline |
| Ownership | Shared |
| Migrations path | Not applicable — schemas are created dynamically by Spark SQL at job runtime |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `<database>.<audienceTable>` (SA table) | Stores sourced audience rows after ingestion | `consumer_id` or `bcookie`, optionally `custom_payload` |
| `<database>.<outputTableName>` (CA table) | Stores identity-transform results | `consumer_id` or `bcookie` |
| `<database>.published_<paId>_<label>_<ts>` (PA segment table) | Stores published audience rows per segment | `consumer_id` or `bcookie`, `segment`, optionally `custom_payload` |
| `<database>.feedback_pa_<paId>` (feedback table) | EDW feedback staging table for PA results | `bcookie`, `audience_id`, `audience_name`, `selector`, `calculated_at` |

#### Access Patterns

- **Read**: Spark SQL `SELECT` on existing SA/PA tables for dedup, union, or joined flows; `USE <database>` scoping before all queries
- **Write**: `DataFrame.write.format("parquet").option("compression","snappy").mode(SaveMode.Overwrite).saveAsTable(...)` for SA/CA/PA tables; `createOrReplaceTempView` for intermediate processing
- **Indexes**: No explicit indexes — Hive partition pruning not observed for these audience tables

---

### HDFS Storage (`hdfsStorage`)

| Property | Value |
|----------|-------|
| Type | HDFS (CerebroV2) |
| Architecture ref | `hdfsStorage` |
| Purpose | Holds uploaded CSV source files for SA ingestion; stores PA segment CSV exports, EDW feedback CSV files, and deal-bucket JSON files |
| Ownership | Shared |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `<publishHdfsURIPrefix>/<csvFile>` | Uploaded source CSV for CSV-type SA | `consumer_id` or `bcookie` + user-defined fields |
| `<paCsvPath>/<segCsvFile>` (e.g. `pa_<paId>_..._<label>.csv`) | PA segment CSV exported for downstream delivery | `consumer_id` or `bcookie`, `segment`, optionally `custom_payload` |
| `<feedbackCsvPath>/feedback_pa_<paId>.csv` | EDW feedback CSV for data warehouse ingestion | `bcookie`, `audience_id`, `audience_name`, `selector`, `calculated_at` |
| `<paCsvPath>/pa_<paId>_dealbuckets.json` | Deal-bucket JSON metadata per PA | `published_audience_id`, `oc_deal_bucket`, `rs_deal_bucket`, `ga_deal_bucket`, `gg_deal_bucket` |

#### Access Patterns

- **Read**: `SparkSession.read.format("csv").option("header","true")` for uploaded SA source files; HDFS file system API for header validation
- **Write**: `CiaFileUtil.parquetToCSV` converts Parquet Hive tables to CSV via HDFS; `CiaFileUtil.generateJSON` writes deal-bucket JSON

---

### Cassandra Audience Store (`cassandraAudienceStore`)

| Property | Value |
|----------|-------|
| Type | Apache Cassandra |
| Architecture ref | `cassandraAudienceStore` |
| Purpose | Stores PA membership payloads used for non-realtime audience targeting and email delivery |
| Ownership | Shared |
| Migrations path | Not applicable — managed by AudiencePayloadSpark and CRM infra |

#### Key Entities

> The specific keyspace and table names are managed by the `audiencepayloadspark` library (`PAPayloadGenerator`) and are not directly visible in this codebase.

#### Access Patterns

- **Write**: `PAPayloadGenerator.mapPaDataFrameToCassandra(df.repartition(200), paId, sadId, hasCustomPayload)` — batches PA rows from a DataFrame into Cassandra using spark-cassandra-connector
- Skipped for EMEA region, Universal payload type with realtime enabled, or when `enablePayload = false`

---

### Bigtable Realtime Store (`bigtableRealtimeStore`)

| Property | Value |
|----------|-------|
| Type | GCP Bigtable |
| Architecture ref | `bigtableRealtimeStore` |
| Purpose | Stores realtime PA membership payloads for NA region, enabling low-latency audience lookups |
| Ownership | Shared |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `user_data_main` (consumer_id-keyed) | Realtime PA membership for consumer_id audiences | `consumer_id` (row key), `<paId>` column in `realTimeInfo` column family |
| `bcookie_data_main` (bcookie-keyed) | Realtime PA membership for bcookie audiences | `bcookie` (row key), `<paId>` column in `realTimeInfo` column family |

#### Access Patterns

- **Write**: `BigtableHandler.uploadToBigtable(df.repartition(50), paId.toString)` — uploads a DataFrame to Bigtable with column name equal to the PA ID
- Column value format: `<paId>;<sadId>;<custom_payload>;<segment>` (semicolon-delimited)
- NA region only; EMEA and Universal payload types are skipped

#### GCP Configuration

| Environment | GCP Project | Bigtable Instance |
|-------------|-------------|-------------------|
| Production NA | `prj-grp-mktg-eng-prod-e034` | `grp-prod-bigtable-rtams-ins` |
| Staging (Cloud) NA | `prj-grp-mktg-eng-stable-29d2` | `grp-stable-bigtable-rtams-ins` |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Spark in-memory DataFrame cache | In-memory (Spark) | Avoids recomputing base DataFrames during segmentation and duplicate checks | Job-lifetime (evicted at job end) |

## Data Flows

1. AMS places an uploaded CSV file on HDFS → SA job reads it into a DataFrame → writes Parquet Hive SA table
2. SA Hive table → CA / Identity Transform job reads SA, runs SQL transform → writes CA Hive table
3. SA/CA Hive tables → PA job joins them via `sourceDataFrameCreationQuery` → creates PA segment Hive tables
4. PA Hive tables → `CiaFileUtil.parquetToCSV` → PA segment CSV files on HDFS
5. PA DataFrame → `PAPayloadGenerator.mapPaDataFrameToCassandra` → Cassandra membership records
6. PA DataFrame → `BigtableHandler.uploadToBigtable` → Bigtable realtime membership records (NA only)
