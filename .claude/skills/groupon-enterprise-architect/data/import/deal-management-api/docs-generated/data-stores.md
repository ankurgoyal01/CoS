---
service: "deal-management-api"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumDealManagementMysql"
    type: "mysql"
    purpose: "Primary relational store for all deal domain data"
  - id: "continuumDealManagementRedis"
    type: "redis"
    purpose: "Resque job queue and application cache"
---

# Data Stores

## Overview

DMAPI owns two dedicated data stores: a MySQL 5.6 database as the primary source of truth for deal and associated domain data, and a Redis instance that serves a dual purpose as the Resque background job queue and an application-level cache. Both stores are accessed by both the API container and the Worker container.

## Stores

### Deal Management MySQL (`continuumDealManagementMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumDealManagementMysql` |
| Purpose | Primary relational database for deals and related domain data |
| Ownership | owned |
| Migrations path | `db/migrate/` (conventional Rails path) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deals` | Core deal records — the primary domain entity | id, title, state, merchant_id, created_at, updated_at |
| `deal_options` | Individual purchase options within a deal | id, deal_id, price, value, quantity |
| `merchants` | Merchant records associated with deals | id, name, salesforce_id, status |
| `places` | Physical location records linked to merchants and deals | id, merchant_id, address, geo coordinates |
| `inventory_products` | Inventory product configurations per deal | id, deal_id, product_type, sku, pricing attributes |
| `contract_parties` | Parties associated with deal contracts | id, contract_id, party_type, external_id |
| `write_requests` | Audit log of tracked write operations | id, resource_type, resource_id, operation, actor, timestamp |
| `history` | Change history records for deal entities | id, entity_type, entity_id, diff, changed_by, changed_at |
| `clients` | Registered API clients and their rate limit configurations | id, name, api_key, rate_limit, rate_window |

#### Access Patterns

- **Read**: Deal retrieval by ID, filtered list queries by state/merchant/date; merchant and place lookups; history and audit log queries
- **Write**: Deal create and update; state machine transitions (publish, unpublish, pause, approve); inventory product upserts; write_request audit entries; contract party management
- **Indexes**: Primary key indexes on all tables; index on `deals.state`, `deals.merchant_id`, `write_requests.resource_id`, `history.entity_id` (inferred from access patterns; verify against schema)

### Deal Management Redis (`continuumDealManagementRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumDealManagementRedis` |
| Purpose | Resque job queue and application cache |
| Ownership | owned |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Resque queues | Named job queues consumed by Worker | queue name, serialized job payload |
| Resque failed set | Failed job store for inspection and retry | job payload, error, backtrace |
| Application cache entries | Cached responses for expensive lookups | cache key, serialized value, TTL |

#### Access Patterns

- **Read**: Worker dequeues jobs; API reads cached values to avoid redundant downstream calls
- **Write**: API enqueues background jobs; application writes cache entries on cache miss
- **Indexes**: > Not applicable (Redis key-space)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumDealManagementRedis` | redis | Application-level cache for external service responses and computed values | Configured per cache key (not specified in inventory) |

## Data Flows

- The API writes deal state to MySQL synchronously on each request, then enqueues a Resque job in Redis for async downstream propagation.
- The Worker reads job payloads from Redis queues, performs business logic (reading from MySQL if needed), and calls Salesforce or Deal Catalog Service.
- No CDC, ETL pipelines, or cross-database replication were identified in the inventory for this service.
