---
service: "ams"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumAudienceManagementDatabase"
    type: "mysql"
    purpose: "Primary audience metadata, definitions, scheduling, and audit records"
  - id: "bigtableCluster"
    type: "bigtable"
    purpose: "Realtime audience attribute reads"
  - id: "cassandraCluster"
    type: "cassandra"
    purpose: "Published audience and metadata record reads"
  - id: "redis"
    type: "redis"
    purpose: "Caching layer"
---

# Data Stores

## Overview

AMS uses a multi-store persistence strategy. MySQL (`continuumAudienceManagementDatabase`) is the primary store for all audience domain metadata and operational records. Bigtable and Cassandra serve as read-optimized stores for audience attributes and published audience records respectively, populated by Spark jobs and read via `ams_integrationClients`. Redis provides a caching layer accessed through the Lettuce client.

## Stores

### Audience Management Database (`continuumAudienceManagementDatabase`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumAudienceManagementDatabase` |
| Purpose | Stores audience metadata, definitions, scheduling, and operational records |
| Ownership | owned |
| Migrations path | Managed by Flyway 3.2.1 |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Audience | Core audience definition and lifecycle state | Audience ID, type, status, criteria reference, timestamps |
| Criteria | Audience criteria definitions used for segment evaluation | Criteria ID, expression, type, metadata |
| Export | Export job records linking audiences to output destinations | Export ID, audience ID, destination, status |
| Schedule | Execution schedule definitions for recurring audience compute | Schedule ID, audience ID, cron expression, last-run metadata |
| Audit Log | Lifecycle event records for audience operations | Log ID, entity type, entity ID, action, actor, timestamp |

#### Access Patterns

- **Read**: Criteria resolution, audience status queries, schedule lookups, audit log retrieval — all via `ams_persistenceLayer` using Hibernate/JDBI DAOs
- **Write**: Audience state transitions, export record creation, schedule updates, audit entries — written by `ams_audienceOrchestration` and `ams_integrationClients` via `ams_persistenceLayer`
- **Indexes**: Managed via Flyway migrations; specific index names not discoverable from DSL inventory

---

### Bigtable Cluster (`bigtableCluster`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Bigtable |
| Architecture ref | `bigtableCluster` |
| Purpose | Reads realtime audience attributes for ad targeting and evaluation |
| Ownership | shared |
| Client library | Google Cloud Bigtable 2.19.2 |

#### Access Patterns

- **Read**: `ams_integrationClients` performs point reads for audience attribute lookups keyed by audience or member identifier
- **Write**: Populated by external Spark jobs; AMS does not write to Bigtable directly

---

### Cassandra Cluster (`cassandraCluster`)

| Property | Value |
|----------|-------|
| Type | Apache Cassandra |
| Architecture ref | `cassandraCluster` |
| Purpose | Reads published audience records and metadata for downstream consumption |
| Ownership | shared |
| Client library | Cassandra Driver 3.7.2 |

#### Access Patterns

- **Read**: `ams_integrationClients` reads published audience records and metadata during export and job state management
- **Write**: Populated by AMS Spark jobs as part of published audience workflows

---

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Redis | Redis (via Lettuce 4.4.4) | Caching layer for audience lookups and intermediate results | Not discoverable from inventory |

## Data Flows

1. Audience metadata is written to and read from MySQL (`continuumAudienceManagementDatabase`) as the system of record.
2. Spark jobs (orchestrated via Livy Gateway) compute audience membership and write results to Bigtable and Cassandra.
3. `ams_integrationClients` reads computed attributes from Bigtable and published records from Cassandra to support API responses and export orchestration.
4. Redis caches intermediate results to reduce load on primary stores.
5. Flyway 3.2.1 manages MySQL schema versioning and migrations at startup.
