---
service: "clam"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "hdfsCheckpoint"
    type: "hdfs"
    purpose: "Spark Structured Streaming checkpoint and group state storage"
---

# Data Stores

## Overview

CLAM owns one durable data store: an HDFS directory used as the Spark Structured Streaming checkpoint location. This stores Kafka offset progress and serialized TDigest group state (via Kryo encoding) so that the job can resume after a restart without data loss or reprocessing from the beginning of a topic. CLAM does not own any relational database, cache, or object store.

## Stores

### HDFS Checkpoint Store (`hdfsCheckpoint`)

| Property | Value |
|----------|-------|
| Type | HDFS (Hadoop Distributed File System) |
| Architecture ref | `unknownSparkCheckpointStore_8af4b0ce` (stub — not yet federated into workspace) |
| Purpose | Stores Spark Structured Streaming checkpoint data: committed Kafka offsets and serialized per-group TDigest state |
| Ownership | owned |
| Path (prod) | `/user/grp_gdoop_metrics/clam_spark_app/checkpoint/` |
| Path (local) | `spark-checkpoint/` (relative to working directory) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Kafka offset log | Tracks which Kafka offsets have been committed per partition so that the streaming job resumes correctly after restart | Topic, partition, offset |
| Group state store | Serialized TDigest objects keyed by `(bucketKey, timestampMs)` — the accumulated histogram state for each metric cluster and time minute | `bucketKey` (string), timestamp (long, nanoseconds), TDigest centroid data (Kryo) |

#### Access Patterns

- **Read**: On job startup, `SparkSession` reads the checkpoint directory to restore committed offsets and in-flight group state. The `ClamConfig.checkpointPath` field drives the `checkpointLocation` Spark option.
- **Write**: After each 1-minute trigger, Spark writes updated Kafka offsets and changed TDigest state entries to the checkpoint directory. The Kryo serializer (`org.apache.spark.serializer.KryoSerializer`) is used; buffer size is configured to 1024 MB max.
- **Deletion**: Checkpoint can be cleared manually via `hdfs dfs -rm -r /user/grp_gdoop_metrics/clam_spark_app/checkpoint/` — this is done during deploys that require a clean state reset (controlled by `delete_hdfs` Ansible parameter).

## Caches

> No evidence found in codebase. CLAM uses no Redis, Memcached, or in-memory cache.

## Data Flows

Kafka → HDFS (checkpoint write on every micro-batch trigger) → Kafka (aggregated output). The HDFS checkpoint is write-through state; it does not serve as a queryable data store. All queryable aggregate data flows through the output Kafka topic to downstream consumers.
