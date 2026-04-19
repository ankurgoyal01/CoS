---
service: "zookeeper"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "zookeeperDataPersistence"
    type: "filesystem"
    purpose: "Znode state snapshots and write-ahead transaction logs for crash recovery and quorum replication"
---

# Data Stores

## Overview

ZooKeeper owns a single durable data store: a filesystem-backed combination of periodic snapshots and a write-ahead transaction log. All znode state is held in memory and periodically flushed to disk as a snapshot, with every write operation also appended to the transaction log. On restart, ZooKeeper replays the transaction log on top of the latest snapshot to restore state. There is no external relational database, cache, or object store.

## Stores

### ZooKeeper Data Persistence (`zookeeperDataPersistence`)

| Property | Value |
|----------|-------|
| Type | filesystem (snapshot + transaction log) |
| Architecture ref | `zookeeperDataPersistence` |
| Purpose | Durable storage of znode state for crash recovery and quorum replication |
| Ownership | owned |
| Migrations path | Not applicable — data layout managed by ZooKeeper server internals |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Snapshot file | Point-in-time serialization of the full znode tree | `dataDir`, zxid (transaction ID), node data, ACLs |
| Transaction log file | Sequential append-only log of every write operation | `dataLogDir` (defaults to `dataDir`), zxid, request type, payload |
| `myid` file | Server identity file used in quorum ensemble | Single integer identifying this server in `zoo.cfg` |

#### Access Patterns

- **Read**: On server startup, the `zookeeperDataPersistence` component reads the most recent snapshot from `dataDir` and replays subsequent transaction log entries to restore in-memory state.
- **Write**: Every client write operation committed by the `requestProcessorPipeline` is synchronously appended to the transaction log before acknowledgement. Snapshots are written asynchronously at configurable intervals (when transaction log size exceeds threshold).
- **Indexes**: No external indexes. The in-memory znode tree is the primary index structure; snapshot and log files are keyed by zxid.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| In-memory znode tree | in-memory (JVM heap) | Full replica of all znode data and metadata; primary serving cache for read operations | No expiry — authoritative state |

> The JVM heap is the operational cache. Default heap for the server is `ZK_SERVER_HEAP=1000` MB (1 GB), configurable via `ZK_SERVER_HEAP` environment variable in `bin/zkEnv.sh`.

## Data Flows

- Client write requests flow through the `requestProcessorPipeline`, are forwarded to the leader via the `quorumProtocolEngine` if this server is a follower, replicated to a quorum of servers, and then committed to the transaction log by `zookeeperDataPersistence` before acknowledgement is sent to the client.
- Snapshots are written to `dataDir` in the background. Old snapshots are eligible for autopurge when `autopurge.snapRetainCount` and `autopurge.purgeInterval` are configured in `zoo.cfg`.
- The `zookeeperLoggraph` container reads transaction log files directly from `dataDir` for offline analysis and visualization.
