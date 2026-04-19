---
service: "ams"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

AMS has four external platform-level dependencies and one internal Continuum data store. All external calls are made through the `ams_integrationClients` component. The most critical path dependency is Livy Gateway — if unavailable, no Spark-based audience computation can proceed. Kafka, Bigtable, and Cassandra are required for the full published audience lifecycle.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Livy Gateway | REST/HTTP | Submit and monitor Spark audience computation jobs | yes | `livyGateway` |
| Kafka Broker | Kafka | Publish `audience_ams_pa_create` events on audience completion | yes | `kafkaBroker` |
| Google Cloud Bigtable | Bigtable client (gRPC) | Read realtime audience attributes for evaluation and export | yes | `bigtableCluster` |
| Apache Cassandra | Cassandra driver | Read published audience records and metadata | yes | `cassandraCluster` |

### Livy Gateway Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: HttpComponents HTTP client; base URL configured via environment
- **Auth**: AWS SigV4 request signing
- **Purpose**: AMS submits Spark jobs for sourced, published, and joined audience calculations through Livy Gateway. It also polls job status via YARN monitoring endpoints.
- **Failure mode**: Audience computation jobs cannot be submitted or tracked; scheduled and on-demand audience calculations fail until the gateway recovers
- **Circuit breaker**: No evidence found

### Kafka Broker Detail

- **Protocol**: Kafka producer (Kafka client 0.11.0.2)
- **Base URL / SDK**: Kafka broker address configured via environment
- **Auth**: No evidence of additional auth beyond network-level access
- **Purpose**: Publishes `audience_ams_pa_create` events when a published audience Spark job completes successfully, notifying downstream consumers (ads targeting, CRM)
- **Failure mode**: Published audience events are not delivered to consumers; downstream systems may operate on stale audience data
- **Circuit breaker**: No evidence found

### Google Cloud Bigtable Detail

- **Protocol**: Bigtable client (Google Cloud Bigtable 2.19.2, gRPC-backed)
- **Base URL / SDK**: Google Cloud Bigtable SDK; project and instance configured via environment
- **Auth**: AWS SigV4 / GCP credentials configured via environment
- **Purpose**: Reads realtime audience attributes used in ad targeting evaluation and export workflows
- **Failure mode**: Audience attribute lookups return errors or empty results; export and evaluation flows are degraded
- **Circuit breaker**: No evidence found

### Apache Cassandra Detail

- **Protocol**: Cassandra driver (Cassandra Driver 3.7.2)
- **Base URL / SDK**: Contact points and keyspace configured via environment
- **Auth**: Cassandra credentials configured via environment
- **Purpose**: Reads published audience records and associated metadata during export orchestration and job state management
- **Failure mode**: Published audience reads fail; export orchestration and downstream audience serving are degraded
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Audience Management Database | JPA/JDBC | Read and write all audience domain data, schedules, criteria, exports, and audit records | `continuumAudienceManagementDatabase` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include ads targeting platforms, CRM pipelines, and reporting workloads that call AMS REST APIs or consume the `audience_ams_pa_create` Kafka topic.

## Dependency Health

- AMS exposes `/grpn/healthcheck` for platform-level health monitoring
- Dependency health checks for Livy, Kafka, Bigtable, and Cassandra are not discoverable from the repository inventory; operational procedures to be defined by the service owner
