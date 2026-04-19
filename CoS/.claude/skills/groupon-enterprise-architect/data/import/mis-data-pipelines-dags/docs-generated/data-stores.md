---
service: "mis-data-pipelines-dags"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "edw"
    type: "hive"
    purpose: "Source and sink for deal performance, archival, and analytics data"
  - id: "gcs-mds-bucket"
    type: "gcs"
    purpose: "Primary landing zone for archived MDS deal files and DPS pipeline outputs"
  - id: "gcs-bloomreach-bucket"
    type: "gcs"
    purpose: "Bloomreach SEM/CDP feed file storage"
  - id: "bigQuery"
    type: "bigquery"
    purpose: "Analytical output store for downstream reporting"
---

# Data Stores

## Overview

`mis-data-pipelines-dags` is not a stateful service in the traditional sense — it does not own a primary operational database. Instead it orchestrates reads from and writes to a set of shared platform-level stores: Hive/EDW for analytical tables, GCS for raw and archived data files, and BigQuery for downstream reporting outputs. The service manages partition lifecycle (creation, retention, cleanup) across these stores as part of its archival and performance pipeline jobs.

## Stores

### Hive / Enterprise Data Warehouse (`edw`)

| Property | Value |
|----------|-------|
| Type | hive |
| Architecture ref | `edw` |
| Purpose | Source for deal performance, active deals, and historical analytics; sink for archived MDS data, deal performance aggregates, deal attributes, and Tableau reporting tables |
| Ownership | shared (managed by data platform team) |
| Migrations path | Not applicable — schema managed by data platform |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `grp_gdoop_mars_mds_db.mds_production` | Archived MDS deal snapshot table (source of truth for archival pipelines) | `dt`, `country_partition`, `brand_partition`, `active`, `trends.conversion` |
| `grp_gdoop_mars_mds_db.mds_flat_production` | Flat (latest) MDS deal partition per country/brand | `country_partition`, `brand_partition` |
| `grp_gdoop_mars_mds_db.mds_archive_production` | Historical archive partitioned by date, country, brand | `dt`, `country_partition`, `brand_partition` |
| `grp_gdoop_mars_mds_db.mds_stats` | Aggregated deal statistics for Tableau (deal counts, purchases, revenue, RPV) | `dt`, `country`, `brand`, `channel`, `division_id`, category hierarchy fields |
| `active_deals` | Source Hive table for the MDS Backfill job — supplies newly added deal IDs | deal ID fields |

#### Access Patterns

- **Read**: Archival pipeline reads full deal snapshots from `mds_production` per country/brand/date partition; deal performance jobs read hourly/daily deal performance events; Backfill job reads `active_deals` to identify new deals
- **Write**: Archival pipeline inserts partitions into `mds_flat_production`, `mds_archive_production`, and `mds_production`; Tableau refresh jobs write into `mds_stats` and related aggregation tables; cleanup jobs drop partitions older than the retention window (92 days for flat, 732 days for archive)
- **Indexes**: Hive partition columns (`dt`, `country_partition`, `brand_partition`) are the primary access dimensions

### GCS MDS Analytics Bucket (`gcs-mds-bucket`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `cloudPlatform` |
| Purpose | Raw deal data landing zone, archive partition storage, and DPS (deal performance) pipeline output directory |
| Ownership | shared (managed by MIS Engineering within GCP project `prj-grp-mktg-eng-prod-e034`) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `gs://grpn-dnd-prod-analytics-grp-mars-mds/user/grp_gdoop_mars_mds/mds_flat_production/` | Latest MDS deal flat files per country/brand | `country_partition=`, `brand_partition=` path segments |
| `gs://grpn-dnd-prod-analytics-grp-mars-mds/user/grp_gdoop_mars_mds/mds_archive_production/` | Date-partitioned compressed MDS deal archives | `dt=`, `country_partition=`, `brand_partition=` path segments |
| `gs://grpn-dnd-prod-analytics-grp-mars-mds/user/grp_gdoop_mars_mds/dps/events/` | Deal performance ingestion pipeline outputs | `date=` path segments, 7-day retention |
| `gs://grpn-dnd-prod-analytics-grp-mars-mds/user/grp_gdoop_mars_mds/dps/time_granularity=hourly/event_source=impressionAttributed/` | Deal performance bucketing outputs | `date=` path segments, 30-day retention |
| `gs://grpn-dnd-prod-analytics-grp-mars-mds/user/grp_gdoop_mars_mds/mds_archive_production` (deals cluster) | MDS archive location read by Deals Cluster job | deal ID partition data |

#### Access Patterns

- **Read**: Deals Cluster job reads archived MDS deal data from GCS; initialization scripts load Hive JSON SerDe jars from `gs://grpn-dnd-prod-analytics-common/`
- **Write**: Archival processor writes flat files (uncompressed) and archive files (gzip-compressed) per country/brand/date; DPS pipeline writes ingestion and bucketing event outputs; cleanup job deletes files older than retention thresholds using `gsutil rm`

### GCS Bloomreach SEM/CDP Feeds Bucket (`gcs-bloomreach-bucket`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `cloudPlatform` |
| Purpose | Staging area for Bloomreach SEM/CDP XML feed files per country and feed type |
| Ownership | shared (managed by MIS Engineering) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `gs://grpn-dnd-prod-analytics-bloomreach-sem-cdp-feeds/bloomreach/cdp/{country}/{feed_type}/*.xml` | Bloomreach CDP feed files for deals, deal_variants, and merchant feed types | Country (US, CA, GB, IE, FR, DE, IT, ES, NL, BE, PL, AE, AU), feed type (deals, deal_variants, merchant), date in filename (`YYYYMMDD`) |

#### Access Patterns

- **Read**: Cleanup DAG lists files via `gsutil ls` to identify files beyond the 2-day retention window
- **Write**: Written by upstream feed generation pipelines (not this service); this service only performs cleanup/deletion

### BigQuery (`bigQuery`)

| Property | Value |
|----------|-------|
| Type | bigquery |
| Architecture ref | `bigQuery` |
| Purpose | Analytical output target for downstream reporting workflows |
| Ownership | shared (GCP platform) |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: Not identified in codebase
- **Write**: DAG Orchestrator publishes analytical outputs to BigQuery via BigQuery API (specific table targets not identified in available config files)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Redis queue | redis (external, managed by batch worker infrastructure) | Receives deal IDs enqueued by Janus Streaming and Backfill Spark jobs for async batch processing | Not configured in this service |

## Data Flows

Deal data flows through the following pipeline stages:
1. MDS API (source) -> GCS flat file -> Hive partition (`mds_flat_production`, `mds_archive_production`, `mds_production`)
2. Hive `mds_production` -> Tableau Hive aggregation tables (`mds_stats`, `mds_edw_weekly`, etc.) -> Tableau extract API
3. Hive `active_deals` -> MDS Backfill Spark job -> Redis queue -> batch worker
4. Kafka (Janus tier-2) -> Janus Spark Streaming job -> Redis queue -> batch worker
5. Hive deal performance events -> DPS Spark jobs (ingestion -> bucketing -> export) -> GCS
6. GCS archived MDS data -> Deals Cluster Spark job -> clustered deal outputs
7. Cleanup jobs prune GCS files and Hive partitions on rolling retention windows
