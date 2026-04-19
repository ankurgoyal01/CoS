---
service: "kafka"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumKafkaLogStorage"
    type: "filesystem"
    purpose: "Persistent topic-partition segment files"
  - id: "continuumKafkaMetadataLog"
    type: "filesystem"
    purpose: "KRaft controller quorum metadata log"
  - id: "rocksdb-streams-state"
    type: "rocksdb"
    purpose: "Kafka Streams stateful operator state stores"
---

# Data Stores

## Overview

Kafka's storage model is entirely file-based. Topic-partition data is stored as immutable, append-only segment files on the broker's local filesystem (`continuumKafkaLogStorage`). Cluster metadata (partition assignments, topic configs, broker registrations) is stored in the KRaft metadata log (`continuumKafkaMetadataLog`) — also a filesystem-backed replicated log. Kafka Streams applications (deployed separately) use RocksDB for persistent state stores when running stateful operations such as aggregations and joins.

## Stores

### Kafka Log Storage (`continuumKafkaLogStorage`)

| Property | Value |
|----------|-------|
| Type | filesystem (append-only segment files) |
| Architecture ref | `continuumKafkaLogStorage` |
| Purpose | Durable, ordered storage for all topic-partition records |
| Ownership | owned |
| Migrations path | Not applicable — schema-free log storage |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Segment file (`.log`) | Stores raw record batches for a topic-partition offset range | Base offset, record batch headers, compressed payloads |
| Index file (`.index`) | Maps logical offsets to physical byte positions in the segment | Offset, position |
| Time index file (`.timeindex`) | Maps timestamps to offsets for time-based offset lookup | Timestamp, offset |

#### Access Patterns

- **Read**: `kafkaBrokerLogManager` reads segment files to serve `Fetch` API requests; reads are random-access via the index file for offset seeks, then sequential for record delivery
- **Write**: `kafkaBrokerLogManager` appends record batches to the active segment file; segments are rolled when they reach the configured size or time threshold
- **Indexes**: Sparse offset index and time index are maintained per segment; rebuilt automatically if missing on broker restart

---

### KRaft Metadata Log (`continuumKafkaMetadataLog`)

| Property | Value |
|----------|-------|
| Type | filesystem (Raft-replicated metadata log) |
| Architecture ref | `continuumKafkaMetadataLog` |
| Purpose | Authoritative, replicated source of truth for all cluster metadata |
| Ownership | owned |
| Migrations path | Not applicable — metadata records are versioned at the protocol level |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Metadata record | Encodes a single change to cluster state (topic creation, partition reassignment, broker registration, etc.) | Record type, offset, epoch, payload (protobuf) |
| Metadata snapshot | Point-in-time snapshot of full cluster state, used to accelerate controller restart | Snapshot offset, epoch, serialized state |

#### Access Patterns

- **Read**: `kafkaControllerMetadataLoader` reads the log on startup to replay to current state; `continuumKafkaBroker` reads committed snapshots and deltas to track metadata changes
- **Write**: `kafkaControllerQuorumManager` (active controller only) appends metadata records; followers replicate by fetching from the leader
- **Indexes**: Standard Kafka log indexes apply; snapshots reduce replay time on restart

---

### RocksDB Streams State Store (`rocksdb-streams-state`)

| Property | Value |
|----------|-------|
| Type | RocksDB (embedded key-value store) |
| Architecture ref | Not applicable — used by Kafka Streams applications deployed separately |
| Purpose | Persistent local state for stateful Kafka Streams operators (aggregations, joins, tables) |
| Ownership | owned by each Streams application instance |
| Migrations path | Managed via changelog topics in Kafka; state is rebuilt from changelog on recovery |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| State store partition | Local RocksDB instance backing one Streams task | Task ID, key-value records |
| Changelog topic | Kafka topic mirroring all RocksDB writes for durability and failover | Partition key, serialized value |

#### Access Patterns

- **Read**: Streams topology nodes perform point lookups and range scans against RocksDB for join and aggregation operations
- **Write**: Every state store write is synchronously mirrored to the changelog topic; RocksDB write-ahead log ensures durability
- **Indexes**: RocksDB manages its own LSM-tree indexes internally

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Page cache (OS-level) | in-memory | Brokers rely on the OS page cache to serve hot partitions without disk I/O | OS-managed |
| Fetch response cache | in-memory | Broker caches responses to identical fetch requests to reduce redundant log reads | Per-request |

## Data Flows

- **Produce path**: Producer client writes record batch to `continuumKafkaBroker` (Network API) → `kafkaBrokerLogManager` appends to active segment in `continuumKafkaLogStorage` → Replica Manager replicates to follower brokers' log storage
- **Metadata propagation**: `continuumKafkaController` appends metadata change to `continuumKafkaMetadataLog` → controller pushes update to all `continuumKafkaBroker` instances → brokers update in-memory metadata cache
- **Streams state recovery**: On task restart, Kafka Streams replays the changelog topic from the last checkpointed offset into a fresh RocksDB instance until it catches up to the current end offset
