---
service: "gcp-prometheus"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "thanosObjectStorage"
    type: "gcs"
    purpose: "Long-term storage for Prometheus/Thanos metric blocks"
  - id: "thanosReceiveTsdb"
    type: "local-disk"
    purpose: "Short-term TSDB for recently received metric samples"
  - id: "thanosStoreCache"
    type: "local-disk"
    purpose: "Index cache for Store Gateway block metadata"
  - id: "grafanaDb"
    type: "relational (external)"
    purpose: "Grafana dashboard, user, and session persistence"
---

# Data Stores

## Overview

The `gcp-prometheus` stack uses GCS as the primary long-term data store for Thanos metric blocks, with local persistent volumes providing short-term storage for Thanos Receive TSDB and Store Gateway index caches. Grafana persists dashboard configuration to an external relational database (connection string provided via secret). Prometheus Server maintains a local TSDB that is flushed to Thanos Receive via remote write.

## Stores

### Thanos Object Storage — GCS Bucket (`thanosObjectStorage`)

| Property | Value |
|----------|-------|
| Type | GCS (Google Cloud Storage) |
| Architecture ref | `thanosObjectStorage` |
| Purpose | Long-term storage for compacted Prometheus/Thanos metric blocks |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity | Purpose | Key Fields |
|--------|---------|-----------|
| Thanos metric block | Stores immutable time-series data in 2h block files | ULID block ID, min/max time range, labels |
| Deletion marks | Marks blocks for deferred deletion | `deletion-mark.json` per block |

#### Access Patterns

- **Write**: `thanosReceive` writes newly ingested blocks to GCS after local flush. `thanosCompact` writes compacted and down-sampled blocks after processing.
- **Read**: `thanosStoreGateway` reads block metadata and series data from GCS to serve gRPC queries. `thanosCompact` reads existing blocks for compaction.
- **Indexes**: Thanos maintains an in-memory index cache on Store Gateway (2000MB per shard, `--index-cache-size=2000MB`).

---

### Thanos Receive Local TSDB (`thanosReceiveTsdb`)

| Property | Value |
|----------|-------|
| Type | Local disk (Kubernetes PVC) |
| Architecture ref | `thanosReceive` |
| Purpose | Short-term in-memory and on-disk TSDB for recently received metric samples |
| Ownership | owned |
| Migrations path | Not applicable |

#### Access Patterns

- **Write**: `thanosReceiveReceiver` appends remote-write samples to local TSDB at `/var/thanos/receive`.
- **Read**: `thanosReceiveStoreApi` reads recent blocks to serve gRPC queries from Thanos Query.
- **Retention**: 1 day (`--tsdb.retention=1d`). PVC size: 2000Gi per replica (5 replicas).

---

### Thanos Store Gateway Index Cache (`thanosStoreCache`)

| Property | Value |
|----------|-------|
| Type | Local disk (Kubernetes PVC) |
| Architecture ref | `thanosStoreGateway` |
| Purpose | Stores downloaded index and chunk data from GCS to reduce object storage reads |
| Ownership | owned |
| Migrations path | Not applicable |

#### Access Patterns

- **Write**: `thanosStoreGatewayObjectStorageReader` downloads block indexes from GCS into local cache at `/var/thanos/store`.
- **Read**: `thanosStoreGatewayStoreApi` reads cached index data to serve gRPC queries.
- **Sharding**: Three sharded StatefulSets (`thanos-store-1`, `thanos-store-2`, `thanos-store-3`) each cover distinct time windows (0-5d, 5d-30d, 30d-90d). PVC size: 1000Gi per replica.

---

### Grafana Database (`grafanaDb`)

| Property | Value |
|----------|-------|
| Type | Relational (external, type unspecified) |
| Architecture ref | `grafana` |
| Purpose | Persists Grafana dashboards, users, organisations, and session state |
| Ownership | shared (external) |
| Migrations path | Not applicable (managed by Grafana on startup) |

#### Access Patterns

- **Write**: Grafana writes dashboard saves, user provisioning, and session data.
- **Read**: Grafana reads dashboard definitions and user/session state on each request.
- Connection string sourced from Kubernetes secret `grafana` key `db-url` (env var `GF_DATABASE_URL`).

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Thanos Store Gateway index cache | in-memory (2000MB) | Reduces GCS reads for block index lookups | Eviction-based |
| Thanos Query Frontend | in-memory (query result cache) | Splits and caches PromQL range query results | Per query range |

## Data Flows

1. Prometheus Server scrapes targets and appends to local TSDB.
2. Prometheus Remote Write ships samples to Thanos Receive TSDB (1-day retention).
3. Thanos Receive flushes sealed 2-hour blocks to GCS (`thanosObjectStorage`).
4. Thanos Compact reads raw blocks from GCS, deduplicates by `prometheus_replica` label, applies down-sampling (5m resolution: 365d; 1h resolution: 2y), and writes compacted blocks back to GCS.
5. Thanos Store Gateway loads block indexes from GCS into local PVC cache; serves historical data to Thanos Query via gRPC.
6. Thanos Query fans out queries to both Thanos Store Gateway (historical) and Thanos Receive Store API (recent).
