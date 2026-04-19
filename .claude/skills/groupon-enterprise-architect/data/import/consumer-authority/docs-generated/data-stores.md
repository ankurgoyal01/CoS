---
service: "consumer-authority"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumConsumerAuthorityWarehouse"
    type: "hive"
    purpose: "Output and staging tables for computed consumer attributes"
  - id: "hiveWarehouse"
    type: "hive"
    purpose: "Source table and partition metadata (shared, upstream)"
  - id: "hdfsStorage"
    type: "hdfs"
    purpose: "Managed table data files (shared, upstream)"
---

# Data Stores

## Overview

Consumer Authority reads source data from two shared upstream stores (the central Hive Warehouse and HDFS) and writes all computed output to its own Consumer Authority Warehouse, which is a set of Hive-managed tables backed by HDFS. There is no relational database, cache, or object store involved.

## Stores

### Consumer Authority Warehouse (`continuumConsumerAuthorityWarehouse`)

| Property | Value |
|----------|-------|
| Type | Hive / HDFS |
| Architecture ref | `continuumConsumerAuthorityWarehouse` |
| Purpose | Hive-backed output and staging tables for computed consumer attributes across NA, INTL, and GBL regions |
| Ownership | owned |
| Migrations path | > No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `user_attrs` | North America consumer attribute output partitions | user_id, attribute_name, attribute_value, run_date |
| `user_attrs_intl` | International consumer attribute output partitions | user_id, attribute_name, attribute_value, run_date |
| `user_attrs_gbl` | Global consumer attribute output partitions | user_id, attribute_name, attribute_value, run_date |

#### Access Patterns

- **Read**: `cdeMetadataAdapter` reads table locations and partition metadata; `cdeSparkExecutionEngine` reads staging partitions during multi-step pipelines
- **Write**: `cdeSparkExecutionEngine` writes partitioned output after each attribute computation run; partitions are written per region and per run date
- **Indexes**: Partition-based pruning by run date and region; no secondary indexes (standard Hive partitioning)

---

### Hive Warehouse (`hiveWarehouse`)

| Property | Value |
|----------|-------|
| Type | Hive |
| Architecture ref | `hiveWarehouse` |
| Purpose | Source table and partition metadata for data used by attribute computations |
| Ownership | shared (external) |
| Migrations path | > Not applicable — shared infrastructure |

#### Access Patterns

- **Read**: `continuumConsumerAuthorityService` queries the Hive Metastore via `cdeMetadataAdapter` to resolve table locations, schema, and partition layouts before submitting Spark jobs
- **Write**: Not applicable — Consumer Authority does not write to the shared Hive Warehouse

---

### HDFS Storage (`hdfsStorage`)

| Property | Value |
|----------|-------|
| Type | HDFS |
| Architecture ref | `hdfsStorage` |
| Purpose | Reads and writes managed table data files underlying Hive tables |
| Ownership | shared (external) |
| Migrations path | > Not applicable — shared infrastructure |

#### Access Patterns

- **Read**: Spark reads source data files via the Hive/HDFS layer during attribute transformations
- **Write**: `cdeSparkExecutionEngine` writes output Parquet/ORC data files to HDFS paths managed by the Consumer Authority Warehouse

## Caches

> No evidence found. Consumer Authority does not use Redis, Memcached, or in-memory caches.

## Data Flows

Source data flows from `hiveWarehouse` and `hdfsStorage` into `continuumConsumerAuthorityService` during Spark job execution. After transformations complete, `cdeSparkExecutionEngine` writes output partitions directly to `continuumConsumerAuthorityWarehouse` (backed by HDFS). `cdeExternalPublisher` then reads from the computed datasets and forwards derived signals to the `messageBus` and attribute metadata to `continuumAudienceManagementService`. No CDC or streaming replication is involved; all data movement is batch-oriented and partition-scoped per daily run.
