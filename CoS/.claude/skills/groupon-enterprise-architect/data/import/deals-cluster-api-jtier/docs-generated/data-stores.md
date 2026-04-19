---
service: "deals-cluster-api-jtier"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumDealsClusterDatabase"
    type: "postgresql"
    purpose: "Primary store for clusters, rules, top clusters, and tagging audit data"
---

# Data Stores

## Overview

The Deals Cluster API owns one primary data store: a PostgreSQL database provisioned via Groupon's DaaS (Database as a Service) platform. The database stores cluster definitions, cluster rule configurations, top cluster data, top cluster rule configurations, and tagging audit records. Connection pooling is provided by PgBouncer (configured in the Docker postgres image). The service also maintains an in-memory Guava cache for top-cluster query results, preloaded at application startup.

## Stores

### Deals Cluster Postgres (`continuumDealsClusterDatabase`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumDealsClusterDatabase` |
| Purpose | Primary persistence for clusters, rules, top clusters, top cluster rules, and tagging audit data |
| Ownership | owned |
| Migrations path | `jtier-migrations` library (managed via JTier migration bundle; Docker init script at `docker/postgres/01_init.sql`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| clusters | Stores computed deal cluster definitions and associated deal UUIDs | `uuid`, `clusterName`, `dealsCount`, `dealDataFrom`, `updatedAt`, `clusterDefinition` (JSON) |
| rules | Stores cluster rule configurations used by the Spark job | `id`, `name`, `filters` (JSON), `customFields` (JSON), `groupBy` (JSON), `outputData` (JSON), `clusterFilters` (JSON) |
| top_clusters | Stores top-performing cluster rankings per rule | `id`, `ruleId`, `compositeKey`, `data` (JSON), `filter`, `dealsCount` |
| top_clusters_rules | Stores top cluster rule definitions (ordering, groupBy, limit) | `id`, `name`, `description`, `clusterName`, `filters`, `groupBy`, `orderBy`, `limit`, `compositeKeyFields`, `dataToExpose` |
| tagging_audit | Persists a record of each tagging/untagging operation | `id`, `tagDate`, `tagName`, `tagUuid`, `useCaseId`, `status`, `createdAt` |
| quartz_* | Quartz scheduler tables for tagging workflow scheduling | Standard Quartz schema (managed by `jtier-quartz-postgres-migrations`) |
| auth_* | JTier authentication tables | Standard JTier auth schema (managed by `jtier-auth-postgres`) |

#### Access Patterns

- **Read**: Clusters, rules, and top-cluster data are queried by JAX-RS resource endpoints via JDBI DAOs. Top-cluster reads are served from the in-memory Guava cache after initial load.
- **Write**: Cluster and rule records are written by the Deals Cluster Spark Job via this API. Tagging audit entries are written by the Tagging Audit Service after each tagging operation. Rules are written via the `POST /rules` and `POST /topclustersrules` endpoints.
- **Indexes**: Not directly visible from DSL; standard DaaS PostgreSQL indexing applies.

#### Connection Pooling

PgBouncer is used for connection pooling in both session and transaction modes. Configuration files:
- `docker/postgres/app/session.ini`
- `docker/postgres/app/session-readonly.ini`
- `docker/postgres/app/transaction.ini`
- `docker/postgres/app/transaction-readonly.ini`

#### Replication

- **Strategy**: Primary/Secondary (as documented in `OWNERS_MANUAL.md`)
- **Backup**: Yes, per DaaS

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Top Clusters cache | in-memory (Guava Cache) | Caches top-cluster query results to serve `GET /topclusters` without DB reads | Preloaded at startup; TTL not specified in available config |

## Data Flows

- The Deals Cluster Spark Job reads rules from `continuumDealsClusterApi` via REST, computes clusters from MDS deal data on GDOOP/Cerebro, and writes resulting cluster records back through the API into `continuumDealsClusterDatabase`.
- Tagging use case execution reads cluster data from the database, publishes messages to JMS, workers consume messages and call the Marketing Deal Service, and audit records are written back to the database.
- Top-cluster data is loaded into the Guava in-memory cache at application startup from the PostgreSQL database.
