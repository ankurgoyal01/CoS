---
service: "watson-api"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumWatsonApiService"]
---

# Architecture Context

## System Context

Watson API is a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It acts as a data-access layer exposing behavioral and personalization signals stored in Redis, Cassandra, HBase, and PostgreSQL. Upstream services within Continuum and ML pipelines call Watson API's REST endpoints to read recommendation feature vectors, personalization buckets, email freshness scores, recently-viewed deal lists, and aggregated event counters. The service publishes KV write events to a Kafka cluster for downstream streaming ingestion by Holmes/Darwin data pipelines.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Watson API Service | `continuumWatsonApiService` | Service | Java, Dropwizard/JTier | 1.0.x | JTier-based Java service providing analytics, KV, freshness, and RVD APIs. Deployed as seven distinct Kubernetes components sharing a single Docker image. |

## Components by Container

### Watson API Service (`continuumWatsonApiService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources | HTTP resources for all Watson API endpoint groups (deal-kv, user-kv, email-freshness, RVD, Janus aggregation, bcookie mapping, you-viewed) | JAX-RS |
| Watson API Service (core) | Component dispatch by `DEPLOY_COMPONENT` env var; bootstraps sub-service resources and wires DAO/client dependencies | Java |
| Data Access Layer | DAO implementations for each store type: KvDAO, RvdDAO, EmailFreshnessRedisDAO, EventCountersDAO, BcookieDAO, ViewsDAO | Java |
| Kafka Producer | Publishes `RealtimeKvEvent` records to Kafka topic on KV write operations | Kafka client 2.7.0 |
| Redis Clients | Reads and writes KV buckets, freshness data, and RVD sorted sets; supports both cluster and standalone Redis topologies | Lettuce 6.1.5 |
| Cassandra Client | Reads analytics counters from Amazon Keyspaces (Cassandra-compatible) using AWS SigV4 auth | Cassandra driver 3.11.0 |
| PostgreSQL Client | Reads Janus bcookie-to-consumer-id mapping via JDBI3 | JDBC / postgresql 42.5.3 |
| HBase Client | Reads user identities from on-premise HBase cluster | HBase client 2.3.7 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumWatsonApiService` | `kafkaCluster_065a01` | Publishes KV events for downstream pipeline ingestion | Kafka (SSL/mTLS) |
| `continuumWatsonApiService` | `redisCluster_16be82` | Reads/writes KV buckets, freshness data, and RVD sorted sets | Redis (TLS) |
| `continuumWatsonApiService` | `cassandraCluster_6a7c58` | Queries analytics counters | CQL / AWS SigV4 |
| `continuumWatsonApiService` | `postgresDatabase_f9fa8e` | Reads/writes Janus aggregation bcookie data | JDBC |
| `continuumWatsonApiService` | `hbaseCluster_e7d3a5` | Reads user identities | HBase RPC |

> Note: Target systems (`kafkaCluster_065a01`, `redisCluster_16be82`, `cassandraCluster_6a7c58`, `postgresDatabase_f9fa8e`, `hbaseCluster_e7d3a5`) are defined as stubs in the local DSL workspace because they are not currently included in the federated central model. Relationships are commented out in `models/relations.dsl` with `stub_only` annotations.

## Architecture Diagram References

- System context: `contexts-continuumWatsonApiService`
- Container: `continuumWatsonApiService-container`
- Component: `continuumWatsonApiService-components`
