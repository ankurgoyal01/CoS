---
service: "fraud-arbiter"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumFraudArbiterMysql"
    type: "mysql"
    purpose: "Fraud decisions, events, and audit records"
  - id: "continuumFraudArbiterConfigRedis"
    type: "redis"
    purpose: "Runtime configuration cache"
  - id: "continuumFraudArbiterCacheRedis"
    type: "redis"
    purpose: "Application-level cache"
  - id: "continuumFraudArbiterQueueRedis"
    type: "redis"
    purpose: "Sidekiq job queue backing store"
---

# Data Stores

## Overview

Fraud Arbiter owns four data stores: a MySQL relational database for durable storage of fraud decisions, audit events, and review records; and three Redis instances serving distinct roles — runtime config caching, application data caching, and Sidekiq background job queue persistence.

## Stores

### Fraud Arbiter MySQL (`continuumFraudArbiterMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumFraudArbiterMysql` |
| Purpose | Persistent storage of fraud decisions, review state, and audit event log |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `fraud_reviews` | Tracks the fraud review lifecycle for each order | `order_id`, `provider`, `status`, `decision`, `submitted_at`, `decided_at` |
| `fraud_events` | Immutable audit log of all events received from fraud providers | `order_id`, `event_type`, `provider`, `payload`, `received_at` |
| `fraud_decisions` | Stores the current and historical fraud decision records | `order_id`, `decision`, `reason_codes`, `score`, `provider`, `created_at` |

#### Access Patterns

- **Read**: Lookup fraud review status by `order_id`; read audit events for a given order
- **Write**: Insert new fraud review records on order creation; update decision and status on webhook receipt; append audit events on every provider interaction
- **Indexes**: `order_id` indexed on all key tables for fast lookup

### Config Redis (`continuumFraudArbiterConfigRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumFraudArbiterConfigRedis` |
| Purpose | Stores runtime configuration values (e.g., provider routing rules, feature flags) |
| Ownership | owned |
| Migrations path | > Not applicable |

#### Access Patterns

- **Read**: Service reads configuration keys on startup and periodically during operation
- **Write**: Configuration values written by deployment or admin tooling
- **Indexes**: Key-value access by config key name

### App Cache Redis (`continuumFraudArbiterCacheRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumFraudArbiterCacheRedis` |
| Purpose | Caches frequently accessed application data to reduce load on MySQL and downstream services |
| Ownership | owned |
| Migrations path | > Not applicable |

#### Access Patterns

- **Read**: Cache-aside reads for order context data, user profiles, and deal information
- **Write**: Cache populated on cache miss from authoritative sources
- **Indexes**: Key-value access by entity type and ID

### Job Queue Redis (`continuumFraudArbiterQueueRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumFraudArbiterQueueRedis` |
| Purpose | Sidekiq background job queue; stores pending and scheduled fraud processing jobs |
| Ownership | owned |
| Migrations path | > Not applicable |

#### Access Patterns

- **Read**: Sidekiq workers pop jobs from queue for processing
- **Write**: Application enqueues jobs in response to webhooks, message bus events, and API calls
- **Indexes**: Queue-based LPUSH/BRPOP access pattern managed by Sidekiq

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumFraudArbiterConfigRedis` | redis | Runtime configuration values | > No evidence found in codebase |
| `continuumFraudArbiterCacheRedis` | redis | Application data cache (order context, user data) | > No evidence found in codebase |

## Data Flows

Fraud decisions are written to MySQL by the Fraud Decision Processor component after receiving and validating a provider webhook. The job queue Redis receives job entries when webhooks arrive or message bus events are consumed; Sidekiq workers drain the queue asynchronously. Config and app cache Redis instances are read-through caches populated from MySQL and downstream services respectively. No CDC or ETL pipelines are described in the inventory.
