---
service: "janus-muncher"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "hdfsStorage"
    type: "gcs"
    purpose: "Primary input and output storage for Parquet event files"
  - id: "hiveWarehouse"
    type: "hive"
    purpose: "Partition metadata for janus_all and junoHourly analytics tables"
  - id: "ultronMysql"
    type: "mysql"
    purpose: "Ultron job state and watermark persistence"
---

# Data Stores

## Overview

Janus Muncher's data storage is centred on Google Cloud Storage (GCS) as the primary file store for all Parquet input and output. Hive Metastore is used exclusively for partition metadata management (not data storage). Ultron's MySQL database is accessed for job retention cleanup operations. The service itself owns no databases — it writes to shared GCS bucket paths managed by the data-engineering platform.

## Stores

### GCS Input — Janus Yati Canonical Bucket (`hdfsStorage`)

| Property | Value |
|----------|-------|
| Type | GCS (accessed via Hadoop FileSystem API) |
| Architecture ref | `hdfsStorage` |
| Purpose | Source input of Parquet canonical Janus event files written by Janus Yati |
| Ownership | External (owned by Janus Yati pipeline) |
| Migrations path | Not applicable |

#### Key Paths

| Path Template | Purpose | Key Fields |
|---------------|---------|-----------|
| `gs://grpn-dnd-prod-pipelines-yati-canonicals/kafka/region=na/source=janus-all/ds=$dates/hour=$hours/*` | Non-SOX Janus event canonical input | `ds` (date), `hour` |
| `gs://grpn-dnd-prod-etl-grp-gdoop-sox-db/kafka/region={na,intl}/source={janus-cloud-all-sox,...}/ds=$dates/hour=$hours/*` | SOX Janus event canonical input | `ds`, `hour` |

#### Access Patterns

- **Read**: Batch-scanned per hourly watermark window; file listing by date/hour partition directories; skip files newer than `skipNewFilesMinutes` (5 min in production)
- **Write**: Not applicable — this is a read-only input source
- **Indexes**: GCS prefix-based directory partitioning by `ds` and `hour`

---

### GCS Output — Janus All Bucket (`hdfsStorage`)

| Property | Value |
|----------|-------|
| Type | GCS (accessed via Hadoop FileSystem API) |
| Architecture ref | `hdfsStorage` |
| Purpose | Deduplicated Janus All event output partitioned by date and hour |
| Ownership | Owned (written by this service) |
| Migrations path | Not applicable |

#### Key Paths

| Path | Purpose | Key Fields |
|------|---------|-----------|
| `gs://grpn-dnd-prod-pipelines-pde/user/grp_gdoop_platform-data-eng/prod/janus/` | Non-SOX Janus All output | `ds`, `hour` |
| `gs://grpn-dnd-prod-etl-grp-gdoop-sox-db/user/grp_gdoop_sox/janus_sox/prod/muncher/janus/` | SOX Janus All output | `ds`, `hour` |
| `gs://grpn-dnd-prod-pipelines-pde/user/grp_gdoop_platform-data-eng/prod/janusAllStaging/` | Intermediate staging path (cleaned up after job) | job context ID |

#### Access Patterns

- **Read**: Replay and compaction jobs re-read previously written Parquet files
- **Write**: Deduplicated Parquet records written per hourly batch; staged first then atomically moved to final path

---

### GCS Output — Juno Hourly Bucket (`hdfsStorage`)

| Property | Value |
|----------|-------|
| Type | GCS (accessed via Hadoop FileSystem API) |
| Architecture ref | `hdfsStorage` |
| Purpose | Analytics-partitioned Juno Hourly event output for EDW consumption |
| Ownership | Owned (written by this service) |
| Migrations path | Not applicable |

#### Key Paths

| Path | Purpose | Key Fields |
|------|---------|-----------|
| `gs://grpn-dnd-prod-pipelines-pde/user/grp_gdoop_platform-data-eng/prod/juno/junoHourly/` | Juno Hourly output | `eventDate`, `platform`, `eventDestination` |
| `gs://grpn-dnd-analytics-pde/user/grp_gdoop_platform-data-eng/prod/juno/junoHourly/` | Cerebro analytics copy path | `eventDate`, `platform`, `eventDestination` |
| `gs://grpn-dnd-prod-pipelines-pde/.../juno/junoHourlyStaging/` | Juno staging path (cleaned up on completion) | job context ID |
| `gs://grpn-dnd-prod-pipelines-pde/.../juno/trash/` | Trash path for failed/superseded staging files | date, hour, job context ID |

#### Access Patterns

- **Read**: Replay merge jobs re-read Juno output for merge operations
- **Write**: Partitioned by `eventDate`, `platform`, `eventDestination`; GZIP-compressed Parquet; up to 1,280,000 rows per output file (event-type-specific overrides for `emailSend`, `searchBrowseView`, `purchaseFunnel`, `dealImpression`); events matching `abExperiment` excluded from Juno output

---

### Hive Metastore (`hiveWarehouse`)

| Property | Value |
|----------|-------|
| Type | Hive (JDBC via HiveServer2) |
| Architecture ref | `hiveWarehouse` |
| Purpose | Partition metadata management for `janus_all` and `junoHourly` Hive tables |
| Ownership | Shared (managed by data platform) |
| Migrations path | Not applicable — partitions are added/repaired at runtime by `MetadataManager` |

#### Key Entities

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| `grp_gdoop_pde.janus_all` | Non-SOX Janus All Hive table | `ds`, `hour` partitions |
| `grp_gdoop_pde.junoHourly` | Non-SOX Juno Hourly Hive table | `eventDate`, `platform`, `eventDestination` partitions |
| `grp_gdoop_sox_db.janus_all` | SOX Janus All Hive table | `ds`, `hour` partitions |
| `grp_gdoop_sox_db.junoHourly` | SOX Juno Hourly Hive table | partitioned columns |

#### Access Patterns

- **Read**: `muncher-hive-partition-creator` DAG reads existing partition state to determine which partitions need to be added
- **Write**: `MetadataManager` Spark class issues Hive DDL to add/repair partitions after each Spark write; JDBC connections to `analytics.data-comp.prod.gcp.groupondev.com:8443` via HiveServer2 HTTP transport mode with SSL

---

### Ultron MySQL DB (`ultronMysql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | Not in central model (stub-only: `unknown_ultronstateapi_5f651053`) |
| Purpose | Ultron job retention cleanup; removing stale job run records beyond 30-day retention |
| Ownership | External (owned by Ultron service) |
| Migrations path | Not applicable |

#### Key Entities

| Table / Job | Purpose | Key Fields |
|-------------|---------|-----------|
| Ultron job records | Job run state, watermarks, and status for all Janus/Juno pipeline jobs | `jobName`, `groupName`, `retentionDays` |

#### Access Patterns

- **Read**: Ultron State Client reads watermark and job state via Ultron HTTP API (`ultron-api.production.service`)
- **Write**: `UltronDbCleaner` connects directly via JDBC (`jdbc:mysql://ultron-api-rw-na-production-db.gds.prod.gcp.groupondev.com:3306/ultron_prod`) to purge records older than 30 days for ~50 configured job names

## Caches

> No evidence found in codebase. No cache layer is used; Spark's in-memory `spark.catalog.clearCache()` is called at end of each delta job run to release cached DataFrames.

## Data Flows

Input Parquet files (written by Janus Yati to GCS) are read by the Transformation Pipeline. Records are staged to a temporary GCS staging path, then deduplicated and written to the Janus All output path. The deduplicated Janus All Parquet files are re-read and transformed into Juno format, then written to the Juno Hourly output path. After each write, the Hive Metastore is updated with new partition metadata via the `muncher-hive-partition-creator` DAG. Staging paths are atomically moved or trashed on job completion/failure.
