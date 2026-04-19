---
service: "mds-feed-job"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "gcs-mds-snapshots"
    type: "gcs"
    purpose: "MDS deal snapshot input data"
  - id: "gcs-feed-staging"
    type: "gcs"
    purpose: "Feed output staging and publishing"
  - id: "hdfs-mds-snapshots"
    type: "hdfs"
    purpose: "MDS deal snapshot input data (HDFS path)"
  - id: "edw"
    type: "teradata"
    purpose: "SEM source datasets for enrichment and filtering"
  - id: "bigQuery"
    type: "bigquery"
    purpose: "Gift-booster enrichment signals"
  - id: "postgresql-metadata"
    type: "postgresql"
    purpose: "Feed and batch metadata"
---

# Data Stores

## Overview

MDS Feed Job is primarily a read-heavy batch job. It reads MDS deal snapshot data from GCS/HDFS distributed storage via Spark (Hive metastore), enriches with signals from BigQuery and Teradata EDW, and writes processed feed files back to GCS staging. PostgreSQL is used for feed/batch metadata (lifecycle state, configuration). The job does not own any of the upstream data stores; it reads from shared platform storage and writes its output files to a GCS staging area.

## Stores

### GCS — MDS Snapshot Input (`gcs-mds-snapshots`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Storage (GCS) |
| Architecture ref | `continuumMdsFeedJob` |
| Purpose | Source MDS deal snapshot files consumed by Spark read jobs |
| Ownership | shared (owned by MDS/data engineering) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| MDS deal snapshot | Partitioned Spark-readable dataset of deal and merchant records | deal ID, division, locale, snapshot timestamp |

#### Access Patterns

- **Read**: Spark reads partitioned MDS snapshot datasets via Hive metastore or direct GCS path
- **Write**: Not written by this job (read-only input)
- **Indexes**: Partition-based access by date/division

---

### GCS — Feed Staging Output (`gcs-feed-staging`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Storage (GCS) |
| Architecture ref | `continuumMdsFeedJob` |
| Purpose | Staging area for validated feed output files before distribution to downstream consumers |
| Ownership | owned (written exclusively by this job) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Feed output file | Partner/ads/search feed in CSV, XML, or other format | feed type, locale, batch ID, timestamp |

#### Access Patterns

- **Read**: Not applicable — downstream consumers (Google Merchant Center, partner systems) pull or receive uploads
- **Write**: `publishingAndValidation` component writes validated feed files after transformer pipeline completes
- **Indexes**: Directory/prefix-based by feed type and batch run

---

### HDFS — MDS Snapshot Input (`hdfs-mds-snapshots`)

| Property | Value |
|----------|-------|
| Type | HDFS (Hadoop Distributed File System) |
| Architecture ref | `continuumMdsFeedJob` |
| Purpose | Alternative distributed storage path for MDS snapshot reads (Hadoop cluster context) |
| Ownership | shared (owned by MDS/data engineering) |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: Spark reads via Hadoop client 3.3.6; path configuration determines GCS vs HDFS at runtime
- **Write**: Not written by this job

---

### EDW — Teradata (`edw`)

| Property | Value |
|----------|-------|
| Type | Teradata (JDBC) |
| Architecture ref | `edw` |
| Purpose | SEM source datasets used for enrichment and filtering of SEM feed generation |
| Ownership | external (Enterprise Data Warehouse) |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: JDBC queries via Teradata JDBC driver 17.20; reads SEM keyword and deal mapping datasets
- **Write**: Not written by this job

---

### BigQuery (`bigQuery`)

| Property | Value |
|----------|-------|
| Type | Google BigQuery |
| Architecture ref | `bigQuery` |
| Purpose | Gift-booster enrichment signals consumed during transformer pipeline enrichment |
| Ownership | external (Google Cloud / data platform) |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: BigQuery API reads during transformer enrichment step; gift-booster score or signal per deal
- **Write**: Not written by this job

---

### PostgreSQL — Feed/Batch Metadata (`postgresql-metadata`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumMdsFeedJob` |
| Purpose | Feed configuration and batch lifecycle metadata (feed run state, scheduling metadata) |
| Ownership | shared (accessed via Feed API / Marketing Deal Service integration) |
| Migrations path | Not applicable — schema managed externally |

#### Access Patterns

- **Read**: `feedOrchestrator` reads feed configuration and batch state at job start-up
- **Write**: `publishingAndValidation` updates batch lifecycle status on completion or failure

## Caches

> No evidence found. No in-memory, Redis, or Memcached caching layer is present in the architecture inventory.

## Data Flows

1. **Snapshot ingestion**: Spark reads MDS snapshots from GCS/HDFS via Hive metastore partitions.
2. **Enrichment**: During transformer pipeline execution, `externalApiAdapters` fetches live data from upstream services; BigQuery and EDW are read for signal enrichment.
3. **Output staging**: `publishingAndValidation` writes finalized feed files to GCS staging.
4. **Metadata update**: Batch lifecycle status is written back to PostgreSQL via the Feed API (Marketing Deal Service) HTTPS calls.
