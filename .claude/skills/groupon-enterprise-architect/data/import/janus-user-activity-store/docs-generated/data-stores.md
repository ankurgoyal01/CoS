---
service: "janus-user-activity-store"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "bigtableRealtimeStore"
    type: "bigtable"
    purpose: "Per-platform user activity records keyed by consumerId"
  - id: "gcs-parquet-source"
    type: "gcs"
    purpose: "Hourly Janus canonical event Parquet input (read-only)"
---

# Data Stores

## Overview

The service writes to Google Cloud Bigtable (`bigtableRealtimeStore`) as its primary output store and reads from GCS Parquet files as its input source. Bigtable holds per-platform user activity records keyed by consumer UUID, organized into monthly tables with two column families. The GCS bucket is read-only from this service's perspective — it is owned and populated by the upstream Janus canonical pipeline.

## Stores

### Google Cloud Bigtable — User Activity Tables (`bigtableRealtimeStore`)

| Property | Value |
|----------|-------|
| Type | bigtable (via HBase API) |
| Architecture ref | `bigtableRealtimeStore` |
| Purpose | Stores filtered and translated Janus user activity records, keyed by consumer UUID, for efficient per-user retrieval |
| Ownership | shared — Bigtable instance owned by datalake team; tables managed by this service |
| Migrations path | `orchestrator/janus_user_activity_create_bigtable_tables.py` (create), `orchestrator/janus_user_activity_purge_bigtable_tables.py` (purge) |

#### Key Entities

| Table Name | Purpose | Key Fields |
|------------|---------|-----------|
| `data_eng_mobile_user_activity_{MM}_{YYYY}` | Mobile platform user activity events for a given month | Row key: `consumerId` (UUID); column qualifier: JSON event attributes; column value: event name |
| `data_eng_web_user_activity_{MM}_{YYYY}` | Web platform user activity events for a given month | Row key: `consumerId` (UUID); column qualifier: JSON event attributes; column value: event name |
| `data_eng_email_user_activity_{MM}_{YYYY}` | Email platform user activity events for a given month | Row key: `consumerId` (UUID); column qualifier: JSON event attributes; column value: event name |

Each table has two column families:
- `a` — core family: `emailOpenHeader`, `emailSend`, `pushNotification`, `locationTracking`, `dealView`, `genericPageView`, `search`
- `extended` — extended family: `dealPurchase`

Tables use MaxVersions GC rule (retain only 1 version per cell).

#### Table Pre-Split Keys

| Table | Split Keys |
|-------|-----------|
| `data_eng_mobile_user_activity` | `40000000`, `80000000`, `c0000000` |
| `data_eng_web_user_activity` | `5fd47054-289b-11e2-8ce8-00259069d5fe`, `c0000000` |
| `data_eng_email_user_activity` | 10 pre-defined UUID-based split points |

#### Access Patterns

- **Read**: Not performed by this service. Downstream consumers read directly from Bigtable by `consumerId` row key.
- **Write**: Bulk `Put` operations per partition, grouped by platform. Row key is `consumerId` (bytes). Column qualifier is a JSON string of event attributes. Column value is the event name string. `fullUrl` attribute is truncated to 10,000 characters if the qualifier exceeds that length.
- **Indexes**: Bigtable row key pre-splits by UUID prefix ranges ensure even distribution across nodes.

### GCS Janus Canonical Parquet Bucket (read-only input)

| Property | Value |
|----------|-------|
| Type | gcs (Google Cloud Storage, Parquet format) |
| Architecture ref | stub-only — `unknown_januscanonicalparquetbucket_4f5d0e35` (not in central model) |
| Purpose | Hourly Janus canonical event partitions consumed as Spark input |
| Ownership | external — owned by the Janus canonical pipeline |
| Migrations path | Not applicable — read-only |

#### Key Entities

| Path Pattern | Purpose | Key Fields |
|-------------|---------|-----------|
| `gs://grpn-dnd-prod-pipelines-yati-canonicals/kafka/region=na/source=janus-all/ds={date}/hour={hour}/` | Production hourly Janus event partitions | `consumerId`, `platform`, `event`, `eventTime`, `value` (JSON map) |
| `gs://grpn-dnd-dev-pipelines-pde/kafka/region=na/source=janus-all/ds={date}/hour={hour}/` | Dev hourly partitions | Same schema |
| `gs://grpn-dnd-stable-pipelines-pde/kafka/region=na/source=janus-all/ds={date}/hour={hour}/` | Stable hourly partitions | Same schema |

#### Access Patterns

- **Read**: Spark `spark.read.parquet(parquetFilesPath)` reads entire hourly partition into a DataFrame. The `value` column is parsed from a JSON string into a `Map[String, String]` using `from_json`.
- **Write**: Not applicable — this service never writes to GCS.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `BigTableConnectionPool` | in-memory (per JVM) | Caches HBase `Connection` per Spark executor to avoid reconnection overhead per partition | JVM lifetime (executor session) |

## Data Flows

1. Upstream Janus pipeline writes hourly canonical events as Parquet to GCS.
2. Airflow DAG (`janus-user-activity-process`) triggers at `05 * * * *` (5 minutes past each hour).
3. Spark job reads the Parquet partition for that hour, translates qualifying records into `UserActivity` objects, and bulk-writes to Bigtable.
4. Monthly provisioning DAG creates next-month tables on the 1st of each month at 16:10 UTC.
5. Monthly purge DAG removes tables older than 732 days on the 1st of each month at 16:10 UTC.
