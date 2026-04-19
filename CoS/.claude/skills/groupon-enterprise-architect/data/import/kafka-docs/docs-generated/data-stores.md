---
service: "kafka-docs"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "kafkaBrokerStorage"
    type: "kafka-log-segments"
    purpose: "Persistent topic log storage across brokers"
  - id: "zookeeperCluster"
    type: "zookeeper"
    purpose: "Cluster metadata, broker coordination, and legacy offset storage"
---

# Data Stores

## Overview

The Kafka platform manages two categories of persistent storage: broker log segment storage (where topic messages are retained) and ZooKeeper clusters (for cluster coordination metadata). The `kafka-docs` documentation site itself is stateless and owns no data stores. The broker log segments are distributed across all broker hosts in each cluster with a replication factor of 3.

## Stores

### Kafka Broker Log Storage (`kafkaBrokerStorage`)

| Property | Value |
|----------|-------|
| Type | Kafka log segments (append-only, partitioned) |
| Architecture ref | `continuumKafkaDocsSite` (documented platform) |
| Purpose | Persistent, partitioned, replicated storage for all Kafka topic messages |
| Ownership | owned (Data Systems team) |
| Migrations path | Not applicable — topic management via `kafka-topics.sh` and `kafkat` tool |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Topic partition log | Stores messages for one partition of a topic | Offset, timestamp, message bytes |
| `__consumer_offsets` | Internal Kafka topic storing consumer group committed offsets (0.9+ client default) | Consumer group ID, topic, partition, offset |

#### Access Patterns

- **Read**: Consumers fetch messages sequentially from a partition leader starting at a committed or requested offset. Old-format (0.8) consumers require `fetch.message.max.bytes=10000000`.
- **Write**: Producers write to the partition leader; the leader replicates to 2 follower brokers. Default `message.max.bytes` = 10,000,000 bytes.
- **Indexes**: Kafka maintains per-segment `.index` and `.timeindex` files for offset and timestamp lookups.

#### Retention Policy

- Default topic retention: **96 hours** on production clusters
- Default offset retention: **1 day** (consumer groups stopped > 1 day lose stored offsets)
- Default partition count: **25** per topic on production clusters
- Replication factor: **3** (tolerates up to 2 broker failures without data loss)
- Capacity trigger: At **80% disk utilization**, new broker hardware is provisioned; at **90%**, retention reduction is considered

### ZooKeeper Cluster (`zookeeperCluster`)

| Property | Value |
|----------|-------|
| Type | Apache ZooKeeper 3.3.6 |
| Architecture ref | `continuumKafkaDocsSite` (documented platform) |
| Purpose | Broker coordination, leader election, cluster metadata, and legacy consumer offset storage |
| Ownership | owned (Data Systems team) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `/brokers/ids/<id>` | Registry of active broker metadata | Broker ID, host, port |
| `/config/topics/<topic>` | Per-topic configuration overrides (e.g., retention) | retention.ms |
| Legacy consumer offsets | Offsets for 0.8-era consumers (ZooKeeper storage) — migration to Kafka storage recommended | Consumer group, topic, partition, offset |

#### Access Patterns

- **Read**: Brokers and legacy clients read cluster state and offsets. ZooKeeper 4-letter word commands (`ruok`, `stat`) are used for health checks.
- **Write**: Kafka brokers register themselves and update partition leadership on leader election. Legacy consumers commit offsets.
- **Cluster size**: 5 ZooKeeper nodes per cluster (tolerates up to 2 simultaneous node failures)

## Caches

> No evidence found in codebase. No separate caching layer is used; Kafka's OS page cache is the primary read-path acceleration mechanism.

## Data Flows

- Producers write to topic partition leaders on local cluster brokers.
- MirrorMaker reads from local cluster topics (SNC1 Local, SAC1 Local) and writes to aggregate cluster topics (SNC1 Aggregate, SAC1 Aggregate), enabling cross-colo merged consumption.
- Offset data flows from consumer groups into the internal `__consumer_offsets` topic (modern clients) or ZooKeeper (legacy 0.8 clients).
- `kafka-active-audit` produces and consumes synthetic messages to audit topics to validate end-to-end producer/consumer path health.
