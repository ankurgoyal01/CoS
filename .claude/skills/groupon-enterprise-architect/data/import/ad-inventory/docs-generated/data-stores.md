---
service: "ad-inventory"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumAdInventoryMySQL"
    type: "mysql"
    purpose: "Primary relational store for audiences, placements, reports, metrics, and job metadata"
  - id: "continuumAdInventoryRedis"
    type: "redis"
    purpose: "Audience membership and ad content cache for fast eligibility checks"
  - id: "continuumAdInventoryHive"
    type: "hive"
    purpose: "Analytical warehouse for materialized ad performance report tables"
  - id: "continuumAdInventoryGcs"
    type: "gcs"
    purpose: "Object storage for bloom filter files and staged report CSVs"
---

# Data Stores

## Overview

Ad Inventory uses four distinct data stores with clearly separated concerns: MySQL for operational relational data, Redis for high-speed cache lookups during placement serving, a Hive warehouse for analytics on downloaded ad performance reports, and a GCS bucket for intermediate file staging between the report download and Hive ingestion pipeline stages.

## Stores

### Ad Inventory MySQL (`continuumAdInventoryMySQL`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumAdInventoryMySQL` |
| Purpose | Primary relational store for audiences, targets, reports, click events, and job state |
| Ownership | owned |
| Migrations path | `src/main/resources/db` (git submodule, managed via jtier-migrations / Liquibase) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Audience definitions | Stores audience metadata and bloom filter file references | audience ID, name, region, bloom filter GCS path |
| Audience targets | Maps placements to eligible audience definitions by country and ad format | placement ID, country, audience ID, ad format |
| Report definitions | Stores scheduled report configurations (source type, date range, refresh window) | report ID, source type (DFP/LIVEINTENT/ROKT), start date, refresh window |
| Report instances | Tracks individual report run executions and their lifecycle state | instance ID, report ID, status (QUEUED/RUNNING/COMPLETED/KILLED), start/end date, last running stage |
| Report history / metrics log | Stores per-run metrics and verification outcomes | instance ID, rows processed, verification pass/fail |
| Sponsored click events | Persists sponsored listing click data forwarded to CitrusAd | click ID, deal UUID, bc cookie, campaign reference |

#### Access Patterns

- **Read**: Audience and audience-target lookups at cache load time; report instance and history queries during scheduler evaluation; click record lookups for deduplication
- **Write**: Audience CRUD on management API calls; report instance lifecycle updates on each job execution phase; click event persistence on each `/ai/api/v1/slc/{id}` call
- **Indexes**: Not visible from source; expected indexes on audience ID, report ID, instance status, and placement ID

### Ad Inventory Redis (`continuumAdInventoryRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumAdInventoryRedis` |
| Purpose | Fast audience eligibility cache supporting sub-millisecond placement serving |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Audience membership (bloom filter) | Stores serialized audience bloom filter data for c_cookie / b_cookie membership checks | audience ID + segment → bloom filter bytes |
| Audience target content | Caches `AudienceTargetContent` lists keyed by placement, country, and ad format | placement ID + country + ad format → list of audience targets |

#### Access Patterns

- **Read**: On every `/ai/api/v1/placement` request; `AudienceApi.getTargetedAudiences()` reads from `audienceTargetCache` and `audienceCache` using Guava cache backed by Redis
- **Write**: On `AudienceLoadJob` execution and on admin cache refresh (`DELETE /admin/v1/caches`)
- **Config**: Default port 6379; max pool size 1024; timeout 3000ms; SSL configurable

### Ad Inventory Hive Warehouse (`continuumAdInventoryHive`)

| Property | Value |
|----------|-------|
| Type | hive |
| Architecture ref | `continuumAdInventoryHive` |
| Purpose | Analytical warehouse for materialized ad performance report tables (DFP, LiveIntent, Rokt) |
| Ownership | owned |
| Migrations path | Tables created dynamically by `HiveReportTableCreatorTask` and `LiveIntentReportTask` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| DFP report tables | One table per DFP report definition, partitioned by date | source, report name, report ID, version, date partition |
| LiveIntent report tables | LiveIntent performance data partitioned by date | report name, date partition |
| Rokt report tables | Normalized Rokt CSV data partitioned by date | report name, date partition |

#### Access Patterns

- **Read**: Analytics consumers query Hive directly; `ReportVerification` reads row counts to validate completeness
- **Write**: `HiveReportTableCreatorTask` creates tables and runs `LOAD DATA` from GCS-staged CSVs; `LiveIntentReportTask` creates and populates LiveIntent partitions

### Ad Inventory GCS Bucket (`continuumAdInventoryGcs`)

| Property | Value |
|----------|-------|
| Type | gcs (Google Cloud Storage) |
| Architecture ref | `continuumAdInventoryGcs` |
| Purpose | Intermediate staging for report CSVs and persistent storage for audience bloom filter files |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Bloom filter files | Binary bloom filter data for each audience definition | GCS path: `baseDir/dbDir/<audienceId>/<segment>.bf` |
| Staged report CSVs | Raw downloaded CSVs from DFP/Rokt prior to validation | GCS path keyed by report name and date |
| Validated report CSVs | Schema-validated CSVs ready for Hive load | Separate GCS prefix after `ReportValidationTask` promotes the file |

#### Access Patterns

- **Read**: `GCPClient` downloads bloom filter files during `AudienceLoadJob`; `HiveReportTableCreatorTask` reads validated CSVs for Hive `LOAD DATA`
- **Write**: `GCPClient` uploads staged CSVs after DFP download; `ReportValidationTask` uploads validated files; bloom filters written on audience create/update
- **Config**: Bucket name, project ID, and service account credentials configured via `adsgcpclientconfig` config block

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `audienceCache` | in-memory (Guava Cache) + Redis | Stores `Audience` objects (bloom filters) keyed by audience ID and segment | Refreshed on `AudienceLoadJob` and admin cache flush |
| `audienceTargetCache` | in-memory (Guava Cache) + Redis | Stores `AudienceTargetContent` lists keyed by placement + country + ad format | Refreshed on `AudienceLoadJob` and admin cache flush |

## Data Flows

1. **Report ingestion pipeline**: DFP/Rokt reports are downloaded as CSVs → staged to `continuumAdInventoryGcs` → validated by `ReportValidationTask` → promoted to validated GCS path → loaded into `continuumAdInventoryHive` tables → run metadata persisted in `continuumAdInventoryMySQL`
2. **Audience cache warm-up**: Audience definitions and targets are read from `continuumAdInventoryMySQL` → bloom filter files fetched from `continuumAdInventoryGcs` → loaded into `continuumAdInventoryRedis` and in-memory Guava caches
3. **Click events**: Each `/ai/api/v1/slc/{id}` call persists a click record in `continuumAdInventoryMySQL` and forwards the event to CitrusAd via HTTP
