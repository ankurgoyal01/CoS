---
service: "raas"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumRaasMetadataMysql"
    type: "mysql"
    purpose: "Primary inventory metadata store"
  - id: "continuumRaasMetadataPostgres"
    type: "postgresql"
    purpose: "Secondary mirror of monitoring metadata"
  - id: "filesystem-cache"
    type: "filesystem"
    purpose: "Atomic JSON snapshots of Redislabs API responses"
---

# Data Stores

## Overview

RaaS uses two relational databases for persistent metadata and a local filesystem cache for intermediate API snapshots. MySQL is the primary store for all cluster inventory entities. PostgreSQL mirrors monitoring metadata for update jobs. The filesystem cache acts as an intermediary between the API Caching Service and all consumers (Info Updater, Monitoring Service, Checks Runner).

## Stores

### RaaS Metadata MySQL (`continuumRaasMetadataMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumRaasMetadataMysql` |
| Purpose | Primary MySQL store for RaaS inventory metadata used by raas-info and monitoring update jobs |
| Ownership | owned |
| Migrations path | > No evidence found — managed by Rails ActiveRecord migrations in the Info Service |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| clusters | Stores managed Redis cluster records | cluster id, name, status |
| nodes | Stores per-cluster node inventory | node id, cluster id, address, status |
| dbs | Stores Redis database records per cluster | db id, cluster id, name, endpoints |
| endpoints | Stores database endpoint addresses | endpoint id, db id, address, port |
| shards | Stores shard topology per database | shard id, db id, role, status |

#### Access Patterns

- **Read**: `continuumRaasInfoService` reads cluster, node, DB, endpoint, and shard records to serve API responses; `continuumRaasMonitoringService` reads for monitor config generation
- **Write**: `continuumRaasInfoService_raasInfoUpdaterJob` upserts normalized entities after parsing cached snapshots; `continuumRaasMonitoringService_raasMonDbSyncJob` swaps temporary tables and writes refreshed monitoring metadata
- **Indexes**: No evidence found from architecture model

### RaaS Metadata PostgreSQL (`continuumRaasMetadataPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumRaasMetadataPostgres` |
| Purpose | Secondary PostgreSQL mirror of monitoring metadata used by update jobs |
| Ownership | owned |
| Migrations path | > No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| monitoring metadata | Mirror of MySQL monitoring records for update job consumption | Mirrors MySQL schema |

#### Access Patterns

- **Read**: `continuumRaasMonitoringService` reads mirrored records for aggregation jobs
- **Write**: `continuumRaasMonitoringService_raasMonDbSyncJob` publishes mirrored monitoring metadata via table-swap pattern
- **Indexes**: No evidence found

### Filesystem Cache (`api_cache` / `raas_info` directories)

| Property | Value |
|----------|-------|
| Type | filesystem |
| Architecture ref | `continuumRaasApiCachingService` (API Cache Storage component) |
| Purpose | Atomic JSON snapshots of Redislabs cluster, node, DB telemetry for local consumption |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `api_cache/` snapshots | Cluster and DB telemetry fetched from Redislabs API | Per-cluster JSON payloads |
| `raas_info/` snapshots | Aggregated rladmin and status data for Info Service sync | Per-cluster rladmin JSON |

#### Access Patterns

- **Read**: `continuumRaasInfoService_raasInfoUpdaterJob`, `continuumRaasMonitoringService` jobs, and `continuumRaasChecksRunnerService_raasChecksOrchestrator` all read from filesystem cache
- **Write**: `continuumRaasApiCachingService_raasApiCacheCollector` writes atomic JSON snapshots
- **Indexes**: Not applicable (filesystem)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `api_cache` / `raas_info` directories | filesystem | Intermediate storage of Redislabs API and rladmin snapshots between collection and consumption | Refreshed per collection job run; no explicit TTL in architecture model |

## Data Flows

1. `continuumRaasApiCachingService_raasApiCacheCollector` fetches telemetry from `continuumRaasRedislabsApi` and writes atomic JSON to the filesystem cache.
2. `continuumRaasInfoService_raasInfoUpdaterJob` reads filesystem cache, parses snapshots, and upserts normalized entities into `continuumRaasMetadataMysql`.
3. `continuumRaasMonitoringService` jobs read filesystem cache and write refreshed monitoring metadata into both `continuumRaasMetadataMysql` and `continuumRaasMetadataPostgres` via a temporary table-swap pattern.
4. `continuumRaasChecksRunnerService` reads filesystem cache directly for health check evaluation — it does not write to either database.
