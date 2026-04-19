---
service: "ingestion-jtier"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumIngestionJtierPostgres"
    type: "postgresql"
    purpose: "Primary relational store for partner, offer, availability, and ingestion state"
  - id: "continuumIngestionJtierRedis"
    type: "redis"
    purpose: "Cache and distributed locks for ingestion coordination"
---

# Data Stores

## Overview

ingestion-jtier owns two data stores: a PostgreSQL database as its primary system of record for all partner feed, offer, and ingestion state data; and a Redis instance used for cache operations and distributed lock coordination across parallel ingestion jobs. Both stores are owned by this service and are not shared with other services.

## Stores

### Ingestion PostgreSQL (`continuumIngestionJtierPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumIngestionJtierPostgres` |
| Purpose | Primary relational store for partners, offers, availability records, and ingestion run state |
| Ownership | owned |
| Migrations path | `> No evidence found — migration tooling not confirmed from inventory` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `partners` | Stores third-party partner configuration and metadata | partnerId, partnerName, feedType, status, pausedAt |
| `offers` | Records individual offers extracted from partner feeds | offerId, partnerId, externalOfferId, status, blacklisted, createdAt, updatedAt |
| `availability` | Tracks offer/deal availability windows and capacity | offerId, dealId, startTime, endTime, capacity, syncedAt |
| `ingestion_runs` | Audit log of ingestion run history | runId, partnerId, triggeredBy, startedAt, completedAt, status, recordsProcessed |
| `deal_deletions` | Queue of deals pending deletion processing | dealId, offerId, partnerId, queuedAt, processedAt |
| `distribution_constraints` | Distribution constraint rules applied to deals | constraintId, dealId, ruleType, value, updatedAt |

#### Access Patterns

- **Read**: Queries partner configuration before each feed run; reads offer records to determine create vs. update; reads availability windows for delta sync; reads deletion queue during deal deletion processing
- **Write**: Inserts/updates offer records after each extraction; writes ingestion run audit entries on job start and completion; updates availability records after each sync; marks deletion queue entries as processed
- **Indexes**: Primary key indexes on `partnerId`, `offerId`, `dealId`; expected index on `ingestion_runs.startedAt` for history queries; expected index on `deal_deletions.processedAt` for queue drain operations

### Ingestion Redis (`continuumIngestionJtierRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumIngestionJtierRedis` |
| Purpose | Cache for frequently accessed ingestion state; distributed locks to prevent concurrent job overlap |
| Ownership | owned |
| Migrations path | > Not applicable |

#### Key Entities

> Redis key schema not confirmed from inventory. The following are inferred from usage patterns:

| Key Pattern | Purpose | Key Fields |
|-------------|---------|-----------|
| `lock:ingest:{partnerId}` | Distributed lock preventing concurrent feed extraction for the same partner | partnerId, TTL |
| `cache:partner:{partnerId}` | Cached partner configuration to reduce PostgreSQL load during runs | partnerId, partnerConfig |
| `cache:availability:{offerId}` | Cached availability state for delta comparison | offerId, availabilitySnapshot |

#### Access Patterns

- **Read**: Lock checks before job start; cache lookups for partner config and availability state
- **Write**: Lock acquisition (SET NX with TTL) at job start; lock release on job completion; cache write-through on partner config and availability data
- **Indexes**: Not applicable — Redis key-based access

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumIngestionJtierRedis` | redis | Ingestion state cache and distributed job locks | TTL set per key; lock TTL not confirmed from inventory |

## Data Flows

- Partner configuration is read from PostgreSQL at job start and cached in Redis for the duration of the run.
- Raw offer data extracted from external partners is persisted to PostgreSQL (`offers` table) as part of each ingestion pipeline execution.
- Availability records are written to PostgreSQL after each sync run; Redis cache is updated in parallel to keep in-memory state current.
- Deletion queue entries in PostgreSQL are consumed and marked processed by the deal deletion processor job.
- No CDC, ETL, or cross-store replication patterns are evident from the inventory.
