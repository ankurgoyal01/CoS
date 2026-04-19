---
service: "minio"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "minioLocalVolume"
    type: "object-storage"
    purpose: "Primary object data store — MinIO serves objects from this local filesystem path"
---

# Data Stores

## Overview

MinIO's primary data persistence mechanism is a local filesystem volume mounted inside the container at `/home/shared`. The `minio server /home/shared` command instructs MinIO to use this path as its data directory, where all bucket metadata and object data are stored. There are no external databases, caches, or secondary stores configured in this repository.

## Stores

### MinIO Local Volume (`minioLocalVolume`)

| Property | Value |
|----------|-------|
| Type | object-storage (local filesystem via container volume) |
| Architecture ref | `continuumMinioService` |
| Purpose | Primary storage for all bucket contents and object data |
| Ownership | owned |
| Migrations path | Not applicable — no schema migrations; MinIO manages its own internal data layout |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Buckets | Logical containers for grouping objects | bucket name, creation date, region, ACL policy |
| Objects | Stored binary files/blobs identified by key within a bucket | bucket, key, ETag, content-type, last-modified, size |
| Multipart uploads | In-progress large-file uploads split into parts | uploadId, parts, bucket, key |

#### Access Patterns

- **Read**: S3 GET requests retrieve objects by bucket name and object key; HEAD requests retrieve metadata only
- **Write**: S3 PUT requests write new objects; multipart upload assembles large files from sequentially uploaded parts
- **Indexes**: MinIO uses its own internal XL storage format for indexing objects; no user-configurable indexes

## Caches

> No evidence found in codebase. No external cache (Redis, Memcached, etc.) is configured.

## Data Flows

Object data flows directly from API clients to the MinIO container's local volume at `/home/shared`. No ETL, CDC, replication, or secondary store pipelines are configured in this repository. Durability and replication within a cluster would require MinIO's erasure-coding or distributed mode configuration, which is not present in the current single-server deployment mode (`minio server /home/shared`).
