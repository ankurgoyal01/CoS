---
service: "watson-api"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "redisCluster_16be82"
    type: "redis"
    purpose: "KV bucket storage, email freshness, and RVD sorted sets"
  - id: "cassandraCluster_6a7c58"
    type: "cassandra"
    purpose: "Analytics event counters"
  - id: "postgresDatabase_f9fa8e"
    type: "postgresql"
    purpose: "Janus bcookie-to-consumer-id mapping"
  - id: "hbaseCluster_e7d3a5"
    type: "hbase"
    purpose: "User identity data"
---

# Data Stores

## Overview

Watson API reads from and writes to four distinct data stores, each serving a specific functional component. Redis is the primary operational store for KV buckets, email freshness signals, recently-viewed deal sorted sets, and Janus aggregation event counters. Cassandra (Amazon Keyspaces) stores analytics counters. PostgreSQL holds the Janus bcookie mapping table. HBase provides user identity data. All stores are shared/external — Watson API does not own schema migrations for any of them.

## Stores

### Redis (`redisCluster_16be82`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `redisCluster_16be82` |
| Purpose | KV bucket storage (deal and user), email freshness (Avro), RVD sorted sets, Janus event counters |
| Ownership | shared |
| Migrations path | Not applicable — schema-less key-value store |

#### Key Entities

| Entity / Key Pattern | Purpose | Key Fields |
|----------------------|---------|-----------|
| `deal|{dealUUID}|{bucket}` | Deal KV bucket value | deal UUID, bucket name |
| `user|{consumerUUID}|{bucket}` | User KV bucket value | consumer UUID, bucket name |
| `user|{consumerUUID}|user-email-activity-freshness` | Serialized Avro `SerializableEmailFreshnessEvent` | consumer UUID |
| `user|{consumerUUID}|views` | RVD recently-viewed sorted set | consumer UUID, deal views |
| `user|{consumerUUID}|sales` | RVD purchase sorted set | consumer UUID, deal purchases |
| Janus aggregation keys (CRC32-sharded) | Per-deal event count time-series buckets | deal ID, event type, time window |

#### Access Patterns

- **Read**: Point lookups by entity UUID and bucket name; RVD uses `LRANGE` on sorted sets with time-window filtering (21-day lookback); Janus uses hash-sharded key resolution via CRC32
- **Write**: `SET` with TTL for KV buckets (TTL ranges from 3 days to 1 year depending on bucket); KV writes also trigger a Kafka event for downstream pipeline persistence
- **Indexes**: None — all reads are primary-key lookups

**TTL Defaults by bucket category:**
- Deal KV default: 180 days (`DEAL_KV_DEFAULT_EXPIRY`)
- User KV default: 30 days (`USER_KV_DEFAULT_EXPIRY`)
- Per-bucket overrides: 3 days, 10 days, 7 days (week), 30 days (month), 180 days (6 months), 365 days (year)

**Redis topology**: Watson API supports both cluster mode (`RedisClusterClient`) and standalone mode (`RedisStandaloneClient`) via the `redis.protocol` configuration field. RVD uses a separate list of two standalone Redis configs (`rvdRedis[0]` and `rvdRedis[1]`).

---

### Cassandra / Amazon Keyspaces (`cassandraCluster_6a7c58`)

| Property | Value |
|----------|-------|
| Type | cassandra (Amazon Keyspaces) |
| Architecture ref | `cassandraCluster_6a7c58` |
| Purpose | Analytics event counters read by the `analytics` component |
| Ownership | shared |
| Migrations path | Not applicable — owned by analytics pipeline |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Analytics counter tables | Aggregated deal/user event counts for relevance scoring | deal UUID, user UUID, time window |

#### Access Patterns

- **Read**: Analytics counter queries via `AnalyticsCassandraReader`; uses `DUAKeyspaceReader` and `DUAQueryCreator` for deal-user-attribute queries
- **Write**: No writes from this service — counters written by Holmes analytics pipeline
- **Auth**: AWS SigV4 authentication via `aws-sigv4-auth-cassandra-java-driver-plugin_3`; TLS enforced via Cassandra `withSSL()`

---

### PostgreSQL (`postgresDatabase_f9fa8e`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `postgresDatabase_f9fa8e` |
| Purpose | Janus bcookie-to-consumer-id mapping for the `janusaggregation` component |
| Ownership | shared |
| Migrations path | Not applicable — schema owned by Janus team |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| bcookie mapping table | Maps browser cookies to consumer UUIDs | consumer_id (UUID), bcookie values |

#### Access Patterns

- **Read**: `BcookieDAO.getAllBcookies(consumerId)` — retrieves all bcookies for a given consumer UUID via JDBI3
- **Write**: No writes from this service observed in current codebase
- **Connection**: JTier DaaS Postgres (`jtier-daas-postgres`) with pooled transaction data source

---

### HBase (`hbaseCluster_e7d3a5`)

| Property | Value |
|----------|-------|
| Type | hbase |
| Architecture ref | `hbaseCluster_e7d3a5` |
| Purpose | User identity data for the `useridentities` component |
| Ownership | shared (external, on-premise) |
| Migrations path | Not applicable — schema owned by Holmes identity pipeline |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| User identities table | User browser cookie to identity mappings | consumer UUID, bcookie suffix (`UIB`) |

#### Access Patterns

- **Read**: `AsyncHBaseClient` and `UserIdentityDAO` for identity lookups
- **Write**: No writes from this service; identity data written by Holmes pipeline
- **Connection**: ZooKeeper quorum at `cerebro-zk{1-5}.snc1:2181`; HDFS root at `hdfs://cerebro-namenode-vip.snc1/apps/hbase/data`

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Redis (KV buckets) | redis | Primary operational store for deal and user KV data | 3 days to 365 days (per-bucket) |
| Redis (email freshness) | redis | Avro-serialized email send/open freshness events | Per `user-email-activity-freshness` bucket TTL (30 days default) |
| Redis (RVD sorted sets) | redis | Recently-viewed deal and purchase data for display | Rolling 21-day lookback window |
| Redis (Janus aggregation) | redis | Time-windowed deal event counters | Managed by Janus aggregation pipeline |

## Data Flows

KV write requests arrive at the API, are immediately written to Redis with a TTL, and a `RealtimeKvEvent` is published to Kafka. The downstream Holmes/Darwin pipeline consumes this event for further processing and long-term persistence. Analytics counters in Cassandra are populated exclusively by the Holmes analytics pipeline and read (never written) by this service. Email freshness data is written to Redis by an upstream freshness pipeline and read by this service. HBase user identity data is written by the Holmes identity pipeline and read by the `useridentities` component.
