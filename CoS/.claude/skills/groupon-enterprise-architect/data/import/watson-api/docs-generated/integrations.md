---
service: "watson-api"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 0
---

# Integrations

## Overview

Watson API has five data-store dependencies and one messaging dependency, all of which are infrastructure-level integrations rather than service-to-service REST calls. There are no known direct HTTP calls to other Groupon microservices from within Watson API's codebase. All dependencies are accessed via client libraries configured at startup. Upstream callers of Watson API are Continuum platform services and ML/analytics pipelines — these relationships are tracked in the central architecture model rather than discoverable from this repository.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Redis Cluster | Redis TCP (TLS) | KV bucket read/write; email freshness read; RVD sorted set read | yes | `redisCluster_16be82` |
| Cassandra / Amazon Keyspaces | CQL / AWS SigV4 + TLS | Analytics counter reads for `analytics` component | yes | `cassandraCluster_6a7c58` |
| PostgreSQL (Janus) | JDBC | Bcookie-to-consumer-id mapping reads for `janusaggregation` component | yes | `postgresDatabase_f9fa8e` |
| HBase | HBase RPC (ZooKeeper) | User identity reads for `useridentities` component | yes | `hbaseCluster_e7d3a5` |
| Kafka Cluster | Kafka producer (SSL / mTLS) | Publishes `RealtimeKvEvent` on KV writes | yes | `kafkaCluster_065a01` |

### Redis Detail

- **Protocol**: Redis binary protocol over TCP; TLS and cluster/standalone modes supported
- **Client**: Lettuce 6.1.5.RELEASE (`lettuce-core`)
- **Auth**: TLS client certificates mounted at `/var/groupon/certs`; configuration in `redis.protocol`, `redis.hostPorts`, `redis.connectionTimeout`
- **Purpose**: Primary operational store for all KV bucket reads/writes, email freshness data, RVD sorted sets, and Janus event counters
- **Failure mode**: `WebApplicationException` returned to caller; Redis errors surface as 500 responses
- **Circuit breaker**: No evidence found in codebase

### Cassandra / Amazon Keyspaces Detail

- **Protocol**: CQL over TLS with AWS SigV4 authentication
- **Client**: DataStax `cassandra-driver-core` 3.11.0 + `aws-sigv4-auth-cassandra-java-driver-plugin_3` 3.0.3
- **Auth**: AWS STS assumed role credentials via `aws-java-sdk-sts`; region configured via `cassandra.region`
- **Purpose**: Analytics counter reads for the `analytics` deployment component
- **Failure mode**: Exceptions surfaced as 500 responses; `maxReadWaitInSecs` controls read timeout
- **Circuit breaker**: No evidence found in codebase

### PostgreSQL (Janus) Detail

- **Protocol**: JDBC via JDBI3
- **Client**: `jtier-jdbi3`, `jtier-daas-postgres`, `postgresql` 42.5.3
- **Auth**: DaaS-managed connection pool; credentials injected by JTier platform secrets
- **Purpose**: Bcookie-to-consumer-id mapping lookups for the `janusaggregation` deployment component
- **Failure mode**: `SQLException` caught and returned as JSON error response
- **Circuit breaker**: No evidence found in codebase

### HBase Detail

- **Protocol**: HBase client RPC via ZooKeeper (`cerebro-zk{1-5}.snc1:2181`)
- **Client**: `hbase-client` 2.3.7; async access via `AsyncHBaseClient`
- **Auth**: Simple (non-Kerberos) as configured in `hbase-site.xml`
- **Purpose**: User identity reads for the `useridentities` deployment component
- **Failure mode**: Exceptions propagated to caller
- **Circuit breaker**: No evidence found in codebase

### Kafka Detail

- **Protocol**: Kafka producer API; SSL or mTLS depending on `KAFKA_TLS_ENABLED` / `KAFKA_MTLS_ENABLED` env vars
- **Client**: `kafka-clients` 2.7.0; custom `KvKafkaProducer` wrapper
- **Auth**: JKS keystore at `kafka.keyStoreFile`; password via `JKS_MSK_PASSWORD` env var (secret)
- **Purpose**: Publish `RealtimeKvEvent` records on every KV write for downstream Holmes/Darwin pipeline ingestion
- **Failure mode**: `AbstractKafkaProducerCallback.onFailure()` called; logged as error; HTTP response is returned to caller regardless (fire-and-forget delivery)
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

> No evidence found in codebase. Watson API does not call other Groupon microservices via HTTP or gRPC.

## Consumed By

> Upstream consumers are tracked in the central architecture model. From code evidence, the following libraries import Watson API's KV API patterns: Holmes/Darwin data processing pipeline (`dataprocessing-common` dependency in `pom.xml`), relevance and recommendation services within Continuum.

## Dependency Health

- Watson API registers a `WatsonApiHealthCheck` with Dropwizard, accessible at the admin port (8081)
- No per-dependency health checks are wired for Redis, Cassandra, PostgreSQL, or HBase in the current codebase
- APM is enabled on all deployment components (`apm.enabled: true` in component YAMLs)
