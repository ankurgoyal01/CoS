---
service: "watson-realtime"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Search Ranking / Analytics"
platform: "Continuum"
team: "dnd-ds-search-ranking@groupon.com"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Kafka Streams"
  framework_version: "2.7.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# watson-realtime Overview

## Purpose

watson-realtime is a collection of Kafka Streams processing jobs that consume curated Janus event streams and write derived data to multiple persistence stores in real time. Each worker is purpose-built for a specific data target — Redis KV stores, Cassandra/Keyspaces analytics counters, or a PostgreSQL cookie-mapping database — enabling watson-api to serve low-latency ranking and analytics data to downstream consumers. The service acts as the real-time ingestion layer between Groupon's event infrastructure (Janus/Conveyor) and the watson-api read path.

## Scope

### In scope

- Consuming `janus-tier2_snc1` and `janus-impression_snc1` Kafka topics
- Writing realtime user/deal KV data to Redis (`continuumRealtimeKvService`)
- Writing analytics impression and tier2 counters to Cassandra/Keyspaces (`continuumAnalyticsKsService`)
- Writing consumer bcookie-to-identity mappings to PostgreSQL (`continuumCookiesService`)
- Writing deal view counts to Redis (`continuumDealviewService`)
- Writing realtime view data (RVD) aggregations to Redis (`continuumRvdService`)
- Enriching and writing user identity data to Redis (`continuumUserIdentitiesService`)
- Trimming aged rows from Cassandra/Keyspaces tables (`continuumKsTableTrimmerService`)
- Fetching event schemas and field mappings from Janus Metadata Service

### Out of scope

- Serving API responses to clients (handled by watson-api)
- Publishing events to Kafka (this service is a pure consumer/writer)
- Producing or managing the upstream Janus event streams (owned by Conveyor/Janus)
- User-facing web or mobile interfaces

## Domain Context

- **Business domain**: Search Ranking / Analytics
- **Platform**: Continuum
- **Upstream consumers**: watson-api (reads from Redis, Cassandra/Keyspaces, and PostgreSQL populated by these workers)
- **Downstream dependencies**: Janus Event Broker (Kafka), Janus Metadata Service (HTTP), Redis (`raasRedis_3a1f`), Cassandra/Keyspaces (`cassandraKeyspaces_5c9a`), PostgreSQL (`postgresCookiesDb_2f7a`)

## Stakeholders

| Role | Description |
|------|-------------|
| Owning team | dnd-ds-search-ranking@groupon.com — responsible for development, operations, and on-call |
| Primary consumer | watson-api team — depends on data freshness and correctness for ranking/analytics queries |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | inventory summary |
| Framework | Kafka Streams | 2.7.0 | inventory summary |
| Runtime | JVM | 11 | inventory summary |
| Build tool | Maven | — | inventory summary |
| Package manager | Maven | — | pom.xml |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| kafka-streams | 2.7.0 | message-client | Kafka Streams DSL and processor API for stream processing |
| kafka-clients | 2.7.0 | message-client | Kafka producer/consumer client |
| jedis | 3.6.3 | db-client | Redis client for KV, dealview, RVD, and user identity writes |
| cassandra-driver | 3.11.0 | db-client | DataStax Cassandra driver for analytics counter writes |
| aws-sigv4 | 3.0.3 | auth | AWS SigV4 request signing for Amazon Keyspaces (managed Cassandra) |
| janus-thin-mapper | 1.6 | serialization | Janus event field mapping and schema resolution |
| avro | 1.8.2 | serialization | Avro schema deserialization for Janus event payloads |
| caffeine | 3.0.3 | state-management | In-process cache for schema lookups and metadata |
| jdbi3 | 3.34.0 | db-client | SQL mapping for PostgreSQL cookie-mapping writes |
| postgresql | 42.5.3 | db-client | JDBC driver for PostgreSQL |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
