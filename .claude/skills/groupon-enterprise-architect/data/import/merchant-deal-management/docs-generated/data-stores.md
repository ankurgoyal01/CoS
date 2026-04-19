---
service: "merchant-deal-management"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumDealManagementApiMySql"
    type: "mysql"
    purpose: "Primary relational datastore for write requests, write events, and history"
  - id: "continuumDealManagementApiRedis"
    type: "redis"
    purpose: "Resque queue backing, rate limiting, and transient coordination state"
---

# Data Stores

## Overview

The Merchant Deal Management service owns two data stores: a MySQL database used as the primary relational store for write requests and history records, and a Redis cluster that backs Resque job queues, enforces rate limits on inbound API calls, and holds transient coordination state. Both stores are shared between `continuumDealManagementApi` and `continuumDealManagementApiWorker`.

## Stores

### Deal Management API MySQL (`continuumDealManagementApiMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumDealManagementApiMySql` |
| Purpose | Primary relational datastore for write requests, write events, and history |
| Ownership | owned |
| Migrations path | Not resolvable from available inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Write requests | Stores inbound deal write request records for processing and auditing | Not resolvable from available inventory |
| History events | Records history of deal write operations for audit trail | Not resolvable from available inventory |
| Write events | Tracks event state for in-progress write flows | Not resolvable from available inventory |

#### Access Patterns

- **Read**: `continuumDealManagementApi` reads request and event data via ActiveRecord; `continuumDealManagementApiWorker` reads queued write request records for processing
- **Write**: `continuumDealManagementApi` creates write request records; `continuumDealManagementApiWorker` persists completed write requests and appends history event records via `dmapiHistoryAndPersistence`
- **Indexes**: Not resolvable from available inventory

### Deal Management API Redis (`continuumDealManagementApiRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumDealManagementApiRedis` |
| Purpose | Redis backing Resque queues, rate limiting, and transient coordination state |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

> Redis does not use relational entities. Key namespaces are not resolvable from available inventory.

#### Access Patterns

- **Read**: `continuumDealManagementApiWorker` dequeues Resque jobs and reads coordination state; `continuumDealManagementApi` reads queue depth and rate-limit counters
- **Write**: `continuumDealManagementApi` enqueues Resque jobs via `dmapiAsyncDispatch` and writes rate-limit state; `continuumDealManagementApiWorker` updates job status
- **Indexes**: Not applicable (Redis key-value store)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumDealManagementApiRedis` | redis | Rate limiting and transient coordination state for deal write operations | Not specified |

## Data Flows

- Inbound HTTP requests are persisted as write request records in MySQL by `continuumDealManagementApi`.
- `continuumDealManagementApi` enqueues asynchronous jobs in Redis via Resque (`dmapiAsyncDispatch`).
- `continuumDealManagementApiWorker` dequeues those jobs from Redis, executes the write flow, and persists the result and history records back to MySQL (`dmapiHistoryAndPersistence`).
- No CDC, ETL, or cross-store replication is evidenced in the architecture model.
