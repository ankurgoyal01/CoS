---
service: "AudiencePayloadSpark"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 2
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
---

# Integrations

## Overview

AudiencePayloadSpark depends on five external infrastructure services (Cassandra, AWS Keyspaces, GCP Bigtable, Redis, Hive/YARN) and two internal Groupon services (AMS API, RTCIA via downstream data consumption). All integrations are outbound writes except the AMS API, which is queried for PA metadata and system table lookups. There is no inbound integration — this service is triggered by `spark-submit` from `continuumAudiencePayloadOps`.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Cassandra Cluster | Spark Cassandra Connector | Writes attribute and PA/SAD payload records | yes | `cassandraKeyspaces` |
| AWS Keyspaces | DataStax Java Driver / keyspace_connector | Writes cloud-tier attribute and SAD payload records; SAD metadata locking | yes | `cassandraKeyspaces` |
| GCP Bigtable | bigtable_client (gRPC) | Writes derivation attributes and CA attributes | yes | `gcpBigtable` |
| Redis Cluster | Jedis / Lettuce (Redis protocol) | Writes CA attributes for real-time consumer attribute lookup | yes | `redisCluster` |
| Apache Hive / YARN | Spark SQL with Hive support | Reads all source audience and attribute tables | yes | `hiveMetastore` / `yarnCluster` |

### Cassandra Cluster Detail

- **Protocol**: Spark Cassandra Connector (embedded in Spark job)
- **Hosts (production NA)**: `ams-rt2-cassandra1.snc1` through `ams-rt2-cassandra16.snc1`; cluster name `ams_rt_cassandra_cluster3`
- **Auth**: DC-aware; `LOCAL_QUORUM` consistency; `localDC: SNC1` (production NA)
- **Purpose**: Primary write target for all user/bcookie attribute (`user_attr2`, `bcookie_attr_v1`) and PA/SAD membership tables
- **Failure mode**: Spark job fails; Fabric retry logic re-submits jobs
- **Circuit breaker**: No evidence found in codebase

### AWS Keyspaces Detail

- **Protocol**: DataStax Java Driver; `com.groupon.cde:keyspace_connector 0.7`
- **Base URL**: `cassandra.us-west-1.amazonaws.com:9142`
- **Auth**: AWS IAM (`AWSCredentials` with `accessKeyId` and `secretAccessKey` from JSON config); SSL via `cassandra_truststore.jks`
- **Purpose**: Cloud-native Cassandra-compatible store for `audience_service` keyspace (`user_data_main`, `bcookie_data_main`, SAD tables); also stores SAD metadata locking rows
- **Failure mode**: `HiveToKeyspaceWriter` job fails and cleans up the locking row via `sys.addShutdownHook`
- **Circuit breaker**: No evidence found in codebase

### GCP Bigtable Detail

- **Protocol**: `com.groupon.crm:bigtable_client 0.3.2-SNAPSHOT` (gRPC via `io.grpc:grpc-netty 1.53.0`)
- **Project (production)**: `prj-grp-mktg-eng-prod-e034`; instance `grp-prod-bigtable-rtams-ins`
- **Auth**: GCP service account JSON loaded from GCS bucket `grpn-dnd-prod-analytics-grp-audience`
- **Purpose**: Stores derivation attribute payloads (`user_data_main`, `bcookie_data_main`) and CA attributes (`ca_attributes`)
- **Failure mode**: Spark job throws and logs exception; derivation writes will retry on next scheduled run
- **Circuit breaker**: No evidence found in codebase

### Redis Cluster Detail

- **Protocol**: Jedis 2.9.0 / Lettuce 6.0.2.RELEASE (Redis protocol, port 6379)
- **Host (production NA)**: `consumer-authority-user--redis.prod.prod.us-west-1.aws.groupondev.com:6379`
- **Auth**: No evidence of password-based auth in config files
- **Purpose**: Writes versioned CA attribute records (metadata keys + per-consumer data) for real-time consumer attribute lookups by downstream RTCIA API
- **Failure mode**: Spark job fails; daily cron retry applies
- **Circuit breaker**: `DiffRatioThreshold = 0.1` guards against mass deletion of keys when diff exceeds 10% of consumers

### AMS API (Internal)

- **Protocol**: HTTP (OkHttp 4.6.0, scalaj-http 2.3.0)
- **Base URL (production)**: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com`
- **Host header**: `ams.production.service`
- **Auth**: Host-header routing via edge proxy
- **Purpose**: (1) `GET /getSourcedAudience/1?type=system&systemSource=users|bcookie` — resolves latest system table name; (2) `GET /searchPublishedAudience?startDate=...&endDate=...&sad=...&state=...` — fetches PA details for a time range; (3) `PUT /published-audience/update-record-count` — updates PA record counts post-aggregation
- **Failure mode**: Retry with exponential backoff (3 retries, starting 4-second interval doubling each attempt — `AudienceUtil.retry`)
- **Circuit breaker**: Retry with backoff only; no circuit breaker

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| AMS API | HTTP | PA search, system table lookup, record count update | `amsApi` |
| Apache Hive | Spark SQL | Reads source user/bcookie attribute and PA membership tables | `hiveMetastore` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `continuumAudiencePayloadOps` | spark-submit | Submits all Spark payload jobs |
| Other Spark applications (Derivation, PublishedAudience) | SBT library dependency | Import `audiencepayloadspark_2.12` as a library |

> Downstream read consumers of the data written by this service (RTCIA, etc.) are tracked in the central architecture model, not this repository.

## Dependency Health

- **AMS API**: Retry with exponential backoff (`n=3`, interval doubles from 4s). Connection timeout 5s, read timeout 90s.
- **Cassandra**: Throughput-limited writes (`spark.cassandra.output.throughput_mb_per_sec = 0.04` MB/s for NA; concurrent writes = 50 for EMEA). No circuit breaker.
- **Redis**: `DiffRatioThreshold = 0.1` prevents mass-deletion if today's dataset shrinks unexpectedly.
- **HiveToKeyspaces**: Mutex locking row (`writing`) in Keyspaces prevents concurrent runs; shutdown hook ensures cleanup on failure.
