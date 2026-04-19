---
service: "watson-realtime"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

watson-realtime depends on four external infrastructure components and one internal service. All event ingestion flows through the shared Kafka cluster. Schema resolution for Janus events is performed via HTTP calls to Janus Metadata Service. Data is written to three external stores: Redis, Cassandra/Keyspaces, and PostgreSQL. Conveyor Cloud acts as the upstream publisher that populates the Kafka topics this service consumes. No inbound REST or gRPC calls are made to this service by other services.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Kafka Cluster | Kafka | Event consumption — source of all Janus events processed by every worker | yes | `kafkaCluster_9f3c` |
| Redis (RaaS) | Redis | Write target for KV data, deal view counts, RVD aggregations, user identities | yes | `raasRedis_3a1f` |
| Cassandra / Amazon Keyspaces | Cassandra | Write target for analytics counters; also trimmed by the table trimmer job | yes | `cassandraKeyspaces_5c9a` |
| PostgreSQL (Cookies DB) | PostgreSQL | Write target for bcookie-to-identity mappings | yes | `postgresCookiesDb_2f7a` |

### Kafka Cluster Detail

- **Protocol**: Kafka (kafka-clients 2.7.0 / kafka-streams 2.7.0)
- **Base URL / SDK**: Kafka broker addresses via consumer group configuration; topic names `janus-tier2_snc1`, `janus-impression_snc1`
- **Auth**: Not discoverable from architecture model (likely SASL/SSL for production)
- **Purpose**: All seven workers consume events from this cluster as the sole input source
- **Failure mode**: Workers pause consumption and retry; Kafka Streams state stores persist offsets so processing resumes from last committed offset on restart
- **Circuit breaker**: No — Kafka Streams handles broker unavailability with built-in retry and backoff

### Redis (RaaS) Detail

- **Protocol**: Redis protocol via Jedis 3.6.3
- **Base URL / SDK**: Redis connection configured via environment; Jedis connection pool
- **Auth**: Not discoverable from architecture model (likely Redis AUTH for production)
- **Purpose**: High-throughput write target for four workers (realtime KV, dealview, RVD, user identities)
- **Failure mode**: Write failures cause Kafka Streams processing exceptions; stream may lag or halt depending on exception handler configuration
- **Circuit breaker**: No evidence found

### Cassandra / Amazon Keyspaces Detail

- **Protocol**: Cassandra native protocol via cassandra-driver 3.11.0 with AWS SigV4 signing (aws-sigv4 3.0.3)
- **Base URL / SDK**: Keyspaces endpoint; AWS region and credentials required for SigV4
- **Auth**: AWS SigV4 (for Amazon Keyspaces managed service)
- **Purpose**: Durable storage for analytics impression and tier2 counters; also subject to scheduled trimming
- **Failure mode**: Write failures propagate as exceptions in the Kafka Streams topology; may cause processing lag
- **Circuit breaker**: No evidence found

### PostgreSQL (Cookies DB) Detail

- **Protocol**: JDBC via postgresql 42.5.3 driver with JDBI3 3.34.0
- **Base URL / SDK**: JDBC connection URL via environment configuration
- **Auth**: Database username/password (credentials via environment/secrets)
- **Purpose**: Persistent store for consumer bcookie-to-identity mappings built from Janus event stream
- **Failure mode**: Write failures propagate as stream processing exceptions; Kafka Streams retry mechanisms apply
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Janus Metadata Service | HTTP | Fetches Janus event schemas and field mappings used by cookies, dealview, realtime KV, RVD, and user identities workers | `janusMetadataService_4d1e` |

### Janus Metadata Service Detail

- **Protocol**: HTTP
- **Base URL / SDK**: URL configured via environment; responses cached in-process using Caffeine 3.0.3
- **Auth**: Not discoverable from architecture model
- **Purpose**: Provides field-level schema definitions and mapping rules for Janus events so workers can correctly extract and transform event payloads
- **Failure mode**: Cache (Caffeine) mitigates transient failures; sustained unavailability would degrade schema resolution for new event types
- **Circuit breaker**: No evidence found; Caffeine cache provides partial protection

### Conveyor Cloud (upstream event publisher)

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Conveyor Cloud | Kafka | Publishes curated Janus events to `kafkaCluster_9f3c` for consumption by this service | `conveyorCloud_7b2c` |

> Conveyor Cloud is an upstream publisher, not a dependency called by watson-realtime.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| watson-api | Redis / Cassandra / PostgreSQL | Reads data written by watson-realtime workers to serve ranking and analytics queries |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

Each worker's liveness is verified by a file-based health probe (exec health check). No HTTP-based health endpoints or circuit breaker patterns are present. Dependency health is monitored indirectly through Kafka consumer group lag metrics (offset lag against `kafkaCluster_9f3c`). Cassandra and Redis connectivity failures surface as stream processing errors in application logs.
