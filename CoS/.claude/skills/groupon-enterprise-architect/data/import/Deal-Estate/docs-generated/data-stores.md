---
service: "Deal-Estate"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumDealEstateMysql"
    type: "mysql"
    purpose: "Primary relational store for deal records and audit history"
  - id: "continuumDealEstateRedis"
    type: "redis"
    purpose: "Resque job queue backend, application cache, distributed locks, feature flags"
  - id: "continuumDealEstateMemcached"
    type: "memcached"
    purpose: "Application-level cache for page and data fragments"
---

# Data Stores

## Overview

Deal-Estate uses three data stores: a MySQL relational database as the system of record for all deal data, Redis as the dual-purpose job queue backend and application cache/lock store, and Memcached for short-lived application cache fragments. Both `continuumDealEstateWeb` and `continuumDealEstateWorker` read and write MySQL and Memcached; `continuumDealEstateScheduler` writes only to Redis.

## Stores

### Deal Estate MySQL (`continuumDealEstateMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumDealEstateMysql` |
| Purpose | Primary relational store for deal records, state machine history, distribution windows, and audit trail |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deals` | Core deal record | id, state, title, schedule dates, merchant reference |
| `options` | Deal options (sub-deals) | id, deal_id, state, pricing, inventory details |
| `distribution_windows` | Time-bounded distribution slots per deal | id, deal_id, start_at, end_at, region |
| `versions` (paper_trail) | Full audit history of deal and option changes | id, item_type, item_id, event, object, whodunnit, created_at |

#### Access Patterns

- **Read**: Web container queries deals by ID, state, and search filters; workers read deals for sync processing
- **Write**: Web container creates and updates deals via Rails controller actions; workers update deal state and sync fields from external events
- **Indexes**: Assumed indexes on `deals.state`, `deals.id`, `options.deal_id` based on access patterns; consult schema for full index list

---

### Deal Estate Redis (`continuumDealEstateRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumDealEstateRedis` |
| Purpose | Resque job queue backend, application cache, distributed locks, and feature flag storage (rollout gem) |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Resque queues | Job queues for background workers | queue name, job payload JSON |
| Resque failed | Failed job retention for manual retry | job payload, error, backtrace |
| rollout flags | Feature flags per user/group/percentage | flag name, rollout percentage, activated users |
| Application cache keys | Short-lived cached data fragments | arbitrary keys set by web/worker layers |

#### Access Patterns

- **Read**: Workers poll queues; web reads feature flags and cache entries
- **Write**: Web enqueues jobs and writes cache; scheduler enqueues delayed/recurring jobs; Resque Web reads queue metadata

---

### Deal Estate Memcached (`continuumDealEstateMemcached`)

| Property | Value |
|----------|-------|
| Type | memcached |
| Architecture ref | `continuumDealEstateMemcached` |
| Purpose | Application-level cache for page and data fragments to reduce MySQL and external service load |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Fragment cache entries | Cached Rails view or data fragments | cache key, serialized value, TTL |

#### Access Patterns

- **Read**: Web and worker layers read cached fragments before falling back to MySQL or external calls
- **Write**: Web and worker layers write fetched data to cache after retrieval

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumDealEstateRedis` | redis | Resque queue backend, feature flags, ad-hoc application cache | Varies by key |
| `continuumDealEstateMemcached` | memcached | Page and data fragment cache (dalli client) | Varies by fragment |

## Data Flows

- Deal state changes originate in MySQL via web/worker writes and are reflected in events published to the message bus.
- Redis acts as the intermediary for all async work: the web layer enqueues jobs, the scheduler enqueues timed jobs, and workers dequeue and process them.
- Memcached caches are written after read-through from MySQL or external services and expire by TTL; no explicit cache invalidation pipeline is modelled.
- paper_trail writes a version record to MySQL on every tracked model change, providing a full audit log.
