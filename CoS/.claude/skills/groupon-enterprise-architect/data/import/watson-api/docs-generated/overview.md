---
service: "watson-api"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Analytics / Personalization"
platform: "Continuum"
team: "Watson"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.0 (jtier-service-pom)"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Watson API Overview

## Purpose

Watson API is a JTier-based Java service that exposes a family of HTTP APIs for reading and writing behavioral, personalization, and analytics data across Groupon's Continuum platform. It consolidates access to multiple data stores (Redis, Cassandra, HBase, PostgreSQL) behind a unified set of REST endpoints organized by functional component. Each deployed component handles a distinct domain — deal key-value storage, user key-value storage, email freshness signals, recently-viewed deals, Janus aggregation event counters, and user identity mapping.

## Scope

### In scope
- Deal-indexed key-value read/write via Redis (`/v1/dds/` endpoints)
- User-indexed key-value read/write via Redis (`/v1/cds/` endpoints)
- Email freshness score retrieval from Redis Avro store (`/v1/realtime/freshness/`)
- Recently-viewed deal retrieval from Redis sorted sets (`/v1/impressions/`)
- Janus aggregation event counter queries from Redis (`/v1/getEvents`)
- Bcookie-to-consumer-id mapping lookups from PostgreSQL (`/v1/bcookie_mapping/`)
- You-viewed activity retrieval from Redis (`/v1/you_viewed/`)
- Publishing KV write events to Kafka for downstream pipeline ingestion

### Out of scope
- Event ingestion and aggregation (handled upstream by Holmes/Darwin pipelines)
- Analytics counter writes (data arrives via Kafka consumers, not this API)
- User identity resolution (HBase reads handled by `useridentities` component, not exposed via current active DSL relationships)
- Deal search and ranking (handled by other Continuum services)

## Domain Context

- **Business domain**: Analytics / Personalization
- **Platform**: Continuum
- **Upstream consumers**: Recommendation engines, email marketing pipelines, deal display services, ranking services within Continuum
- **Downstream dependencies**: Redis clusters (KV, freshness, RVD, Janus), Cassandra cluster (analytics counters), HBase cluster (user identities), PostgreSQL (Janus bcookie mapping), Kafka cluster (KV event publishing)

## Stakeholders

| Role | Description |
|------|-------------|
| Watson team | Service owners; maintain API components and deploy all seven sub-services |
| Relevance / ML teams | Primary consumers of KV buckets (deal and user intrinsic/algo feature data) |
| Email marketing teams | Consumers of email freshness endpoint |
| Analytics / BI teams | Consumers of Janus aggregation event counter API |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `project.build.targetJdk=11` |
| Framework | Dropwizard / JTier | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | 11 (dev-java11-maven image) | `.ci/Dockerfile` |
| Build tool | Maven | — | `pom.xml` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-jdbi3` | (jtier-managed) | orm | JDBI3 database access for PostgreSQL |
| `jtier-daas-postgres` | (jtier-managed) | db-client | DaaS PostgreSQL connection pooling |
| `lettuce-core` | 6.1.5.RELEASE | db-client | Async Redis cluster and standalone client |
| `kafka-clients` | 2.7.0 | message-client | Kafka producer for KV event publishing |
| `postgresql` | 42.5.3 | db-client | JDBC driver for Janus PostgreSQL |
| `cassandra-driver-core` | 3.11.0 | db-client | Cassandra analytics counter reads |
| `aws-sigv4-auth-cassandra-java-driver-plugin_3` | 3.0.3 | auth | AWS SigV4 auth for Amazon Keyspaces |
| `aws-java-sdk-sts` | 1.12.239 | auth | AWS STS for Cassandra IAM credentials |
| `hbase-client` | 2.3.7 | db-client | HBase user identity reads |
| `avro` | 1.9.2 | serialization | Avro schema for email freshness and KV events |
| `snappy-java` | 1.1.7.7 | serialization | Snappy compression for KV payload bytes |
| `datastore-models-gen-1.8.2` | 0.3.33 | serialization | Holmes datastore model generation |
| `lombok` | 1.18.4 | validation | Boilerplate reduction (getters, builders) |
| `gson` | 2.8.5 | serialization | JSON serialization utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
