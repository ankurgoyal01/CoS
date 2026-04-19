---
service: "AudiencePayloadSpark"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "cassandraKeyspaces"
    type: "cassandra"
    purpose: "Primary audience payload store — user/bcookie attributes and PA memberships"
  - id: "cassandraKeyspaces"
    type: "aws-keyspaces"
    purpose: "Cloud-native Cassandra-compatible store for user_data_main and SAD payloads"
  - id: "gcpBigtable"
    type: "bigtable"
    purpose: "Bigtable-backed store for CA attributes and derivation payloads"
  - id: "redisCluster"
    type: "redis"
    purpose: "CA attribute store for low-latency consumer attribute lookup"
  - id: "hiveMetastore"
    type: "hive"
    purpose: "Source of user/bcookie system tables and PA audience tables"
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark"]
---

# Data Stores

## Overview

AudiencePayloadSpark writes to four distinct storage systems: a legacy Cassandra cluster (primary payload store), AWS Keyspaces (cloud-native Cassandra API), GCP Bigtable (derivation and CA attributes), and Redis (CA attribute fast lookup). All source data is read from Hive tables managed by the AMS Hive database. The service owns no schema migrations — table schemas are managed by the AMS platform team.

## Stores

### Cassandra Cluster (`cassandraKeyspaces`)

| Property | Value |
|----------|-------|
| Type | Cassandra |
| Architecture ref | `cassandraKeyspaces` |
| Purpose | Primary store for user/bcookie attribute payloads and PA/SAD membership datasets |
| Ownership | shared |
| Migrations path | Not applicable — schema owned by AMS platform |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `user_attr2` | User attribute payload | `consumer_id`, per-attribute columns, `last_update_at` |
| `bcookie_attr_v1` | Bcookie attribute payload | `bcookie`, per-attribute columns, `last_update_at` |
| `user_pa_v1` | User PA membership | `consumer_id`, `pa_id` |
| `bcookie_pa_v1` | Bcookie PA membership | `bcookie`, `pa_id` |
| `user_sad_v1` (prefix `user_sad_`) | User SAD aggregated PA membership | `consumer_id`, `pa_id`, `sad_id`, `custompayload`, `labels` |
| `bcookie_sad_v1` (prefix `bcookie_sad_`) | Bcookie SAD aggregated PA membership | `bcookie`, `pa_id`, `sad_id` |
| `user_pa_agg` | User NonSAD PA aggregate | `consumer_id`, `pa_id`, `labels`, `custompayload` |
| `bcookie_pa_agg` | Bcookie NonSAD PA aggregate | `bcookie`, `pa_id`, `labels`, `custompayload` |
| `user_realtime_pa` | Realtime user PA membership | `consumer_id`, `pa_id` (keyspace: `ams_realtime`) |

#### Access Patterns

- **Read**: Reads existing Cassandra schema column names for delta calculation (`getCassandraUserAttributes`)
- **Write**: Bulk write via Spark Cassandra Connector (`spark.cassandra.output.*`); TTL applied to PA tables (`cassPaTableTtlInSeconds: 172800` seconds = 48 hours); consistency level `LOCAL_QUORUM`; DC-aware routing (`localDC: SNC1` for NA production, `SNC2` for NA staging)

### AWS Keyspaces (`cassandraKeyspaces` — cloud tier)

| Property | Value |
|----------|-------|
| Type | AWS Keyspaces (Cassandra-compatible) |
| Architecture ref | `cassandraKeyspaces` |
| Purpose | Cloud-native store for `user_data_main`, `bcookie_data_main`, `non_scheduled_audience_data`, and SAD metadata |
| Ownership | shared |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `user_data_main` | Main user attribute payload (cloud) | `id` (consumer_id), attribute columns |
| `bcookie_data_main` | Main bcookie attribute payload (cloud) | `id` (bcookie), attribute columns |
| `non_scheduled_audience_data` | NonSAD audience payload | `id`, audience data columns |
| `non_scheduled_audience_data_bcookie` | NonSAD bcookie audience payload | `id`, audience data columns |

#### Access Patterns

- **Read**: Direct CQL reads via `CassandraClientFactory` / DataStax Java Driver (for locking row checks)
- **Write**: `keyspace_connector` library writes; SSL/TLS via `cassandra_truststore.jks`; endpoint `cassandra.us-west-1.amazonaws.com:9142`; consistency `LOCAL_QUORUM`; timeout 20 seconds

### GCP Bigtable (`gcpBigtable`)

| Property | Value |
|----------|-------|
| Type | GCP Bigtable |
| Architecture ref | `gcpBigtable` |
| Purpose | Stores derivation attribute payloads and CA (Consumer Authority) attributes; also holds SAD metadata |
| Ownership | shared |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `user_data_main` | User derivation attributes (Bigtable table) | `id` (consumer_id), attribute columns |
| `bcookie_data_main` | Bcookie derivation attributes | `id` (bcookie), attribute columns |
| `ca_attributes` | CA attributes written by `CAAttributeBigTableWriterMain` | `consumer_id` / `bcookie`, attribute columns |

#### Access Patterns

- **Read**: `deleteRowFromBigtable` for stale record cleanup
- **Write**: `uploadToBigtable` via `BigtableHandler` / `bigtable_client` library; project `prj-grp-mktg-eng-prod-e034`, instance `grp-prod-bigtable-rtams-ins` (production); service account credentials loaded from GCS bucket `grpn-dnd-prod-analytics-grp-audience`

### Redis Cluster (`redisCluster`)

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `consumer-authority-user--redis.prod.prod.us-west-1.aws.groupondev.com:6379` | Redis | CA attribute store — consumer_id keyed attribute values for low-latency access by RTCIA | No TTL (managed by daily diff/remove cycle) |

#### Access Patterns

- **Read**: `SCAN` commands for calibration mode (batch scan of all keys to reconcile with today's dataset)
- **Write**: Bulk pipeline writes via `RedisClientV2` (Lettuce); writes metadata keys (`latest-version`, `name-<sha256>`, `type-<sha256>`) and per-consumer data rows (`consumer_id => version,val1,val2,...`); parallelism and pipeline size are configurable CLI flags
- **Remove**: Keys for consumers no longer in today's Hive table are removed using `leftanti` join diff; `DiffRatioThreshold = 0.1` guards against accidental mass deletions

### Hive (Source Data — `hiveMetastore`)

| Property | Value |
|----------|-------|
| Type | Apache Hive |
| Architecture ref | `hiveMetastore` |
| Purpose | Source of all audience attribute and PA membership data |
| Ownership | external / shared |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| System table (users) | User attribute system table looked up from AMS API or specified by operator | `consumer_id`, attribute columns |
| System table (bcookie) | Bcookie attribute system table | `bcookie`, attribute columns |
| PA audience tables | Per-PA Hive tables containing consumer/bcookie memberships | `consumer_id` or `bcookie` |
| `cia_realtime.user_attr_daily` | CA attributes source table for Redis/Bigtable writes | `consumer_id`, CA attribute columns |
| `user_attr_daily_consumer_id` / `user_attr_daily_consumer_id_last` | Hive tracking tables for CA Redis delta | `consumer_id` |

## Data Flows

1. **Attribute payload flow**: Hive system table -> Spark SQL (`getAttrQuery`) -> delta calculation -> write/delete to Cassandra (`user_attr2`, `bcookie_attr_v1`) and Bigtable (`user_data_main`, `bcookie_data_main`)
2. **PA membership flow**: AMS API search -> PA Hive tables -> Spark join/filter -> write to Cassandra (`user_pa_v1`, `bcookie_pa_v1`) with 48-hour TTL
3. **SAD aggregation flow**: PA Hive tables -> Spark map-reduce -> write to Cassandra SAD tables (`user_sad_*`) and Keyspaces SAD tables
4. **CA attribute flow**: `cia_realtime.user_attr_daily` -> Spark select -> pipeline write to Redis; delta cleanup via Hive tracking tables `user_attr_daily_consumer_id` / `user_attr_daily_consumer_id_last`
