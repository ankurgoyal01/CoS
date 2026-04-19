---
service: "watson-realtime"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "raasRedis_3a1f"
    type: "redis"
    purpose: "Realtime KV data, deal view counts, RVD aggregations, user identities"
  - id: "cassandraKeyspaces_5c9a"
    type: "cassandra"
    purpose: "Analytics impression and tier2 counters"
  - id: "postgresCookiesDb_2f7a"
    type: "postgresql"
    purpose: "Consumer bcookie-to-identity mappings"
---

# Data Stores

## Overview

watson-realtime writes to three distinct persistence stores. Redis is the primary target for low-latency KV data serving four workers (realtime KV, dealview counts, RVD aggregations, user identities). Cassandra/Keyspaces stores analytics counters requiring durable time-series writes and is also maintained by the table trimmer. PostgreSQL holds cookie-to-identity mapping records written by the cookies worker. All stores are written to by this service; reads are performed exclusively by watson-api and other downstream consumers.

## Stores

### Redis — Realtime Data Store (`raasRedis_3a1f`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `raasRedis_3a1f` |
| Purpose | Stores realtime user/deal KV pairs, deal view counts, RVD aggregations, and user identity data for low-latency serving |
| Ownership | shared |
| Migrations path | Not applicable — schema-less key/value store |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Realtime KV keys | Per-user and per-deal realtime feature data | user ID, deal ID |
| Deal view counter keys | Running count of deal views per deal | deal ID |
| RVD aggregation keys | Realtime view data rollups | user ID, deal ID, time window |
| User identity keys | Enriched user identity records | user ID, bcookie |

#### Access Patterns

- **Read**: Performed by watson-api for ranking and analytics queries (not by this service)
- **Write**: Each worker uses Jedis to SET or increment keys on each processed event; high-throughput streaming writes
- **Indexes**: Not applicable — Redis key-value model; key design determines access pattern

### Cassandra / Amazon Keyspaces (`cassandraKeyspaces_5c9a`)

| Property | Value |
|----------|-------|
| Type | cassandra |
| Architecture ref | `cassandraKeyspaces_5c9a` |
| Purpose | Stores aggregated analytics counters for impression and tier2 events |
| Ownership | shared |
| Migrations path | Not applicable — managed by table trimmer job |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Analytics counters table | Aggregated impression and tier2 event counts by deal/user/time | deal ID, user ID, event type, time bucket |

#### Access Patterns

- **Read**: Performed by watson-api for analytics queries (not by this service)
- **Write**: `continuumAnalyticsKsService` uses the DataStax Cassandra driver (with AWS SigV4 signing for Keyspaces) to write counter increments on each processed event
- **Indexes**: Not applicable — Cassandra partition key design drives access patterns

### PostgreSQL — Cookie Mappings Database (`postgresCookiesDb_2f7a`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `postgresCookiesDb_2f7a` |
| Purpose | Stores consumer bcookie-to-user-identity mappings |
| Ownership | shared |
| Migrations path | Not applicable — managed externally; no migration path discoverable in this service |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Cookie mappings table | Maps bcookie identifiers to resolved user identities | bcookie, user ID |

#### Access Patterns

- **Read**: Performed by watson-api and/or other consumers (not by this service)
- **Write**: `continuumCookiesService` uses JDBI3 to upsert mappings on each processed Janus event
- **Indexes**: Not applicable — index configuration not discoverable from architecture model

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Schema/metadata cache | in-memory (Caffeine) | Caches Janus event schema and field mappings fetched from `janusMetadataService_4d1e` to avoid per-event HTTP calls | Not discoverable from architecture model |

## Data Flows

Events arrive from `kafkaCluster_9f3c` into each Kafka Streams worker. Each worker applies Janus schema resolution (via `janusMetadataService_4d1e`, with Caffeine in-process caching) and writes derived data to its target store. There is no CDC, ETL pipeline, or cross-store replication within this service. The Keyspaces Table Trimmer (`continuumKsTableTrimmerService`) runs on a schedule to delete aged rows from `cassandraKeyspaces_5c9a`, maintaining table size and query performance.
