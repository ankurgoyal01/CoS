---
service: "partner-service"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumPartnerServicePostgres"
    type: "postgresql"
    purpose: "Partner configuration, ingestion state, and operational records"
---

# Data Stores

## Overview

Partner Service owns a single PostgreSQL database (`continuumPartnerServicePostgres`) as its primary and only data store. The database holds all partner configuration, ingestion pipeline state, mapping records, audit log entries, and simulator state. Schema is managed through Flyway migrations. There are no caches or secondary stores identified in the inventory.

## Stores

### Partner Service Postgres (`continuumPartnerServicePostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumPartnerServicePostgres` |
| Purpose | Primary relational datastore for partner configuration, ingestion state, and operational records |
| Ownership | owned |
| Migrations path | Managed via Flyway (exact path not enumerated in inventory) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Partner records | Stores 3PIP partner identity, configuration, and status | partner ID, name, status, configuration payload |
| Partner mappings | Associates partner entities with Groupon deal and division identifiers | partner ID, deal ID, division ID, mapping type |
| Product-place associations | Links partner product records to geographic place metadata | product ID, place ID, association status |
| Ingestion state | Tracks current and historical state of partner data ingestion pipelines | partner ID, ingestion stage, state, updated timestamp |
| Audit log | Immutable append-only log of all partner-affecting operations | event type, actor, partner ID, before/after state, timestamp |
| Simulator entities | Stores simulator session and result data for integration testing | session ID, scenario, status, result payload |

#### Access Patterns

- **Read**: Domain services query partner config and mapping records by partner ID; audit log is queried by time range and partner ID; simulator reads session state by session ID
- **Write**: Onboarding and reconciliation workflows write partner records and mapping updates; all write operations produce a corresponding audit log entry; ingestion state is updated incrementally per workflow stage
- **Indexes**: Not enumerated in the inventory; assumed to cover primary keys and partner ID foreign keys based on access patterns

## Caches

> No evidence found. Partner Service does not use an external or in-process cache.

## Data Flows

Partner Service is the authoritative writer for all entities in `continuumPartnerServicePostgres`. No CDC, replication, or ETL pipelines from this database were identified in the inventory. Downstream services receive partner state updates via MBus events published after successful database writes.
