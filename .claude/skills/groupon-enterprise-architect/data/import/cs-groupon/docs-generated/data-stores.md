---
service: "cs-groupon"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumCsAppDb"
    type: "mysql"
    purpose: "Primary relational data store for CS application data"
  - id: "continuumCsRedisCache"
    type: "redis"
    purpose: "Cache, session store, job queue backing store, and feature toggles"
---

# Data Stores

## Overview

cyclops uses a two-tier storage strategy: MySQL as the primary relational store for durable CS application data, and Redis as a multi-purpose cache, session store, and job queue (Resque). Memcached and Elasticsearch are also used — Memcached for fragment/object caching and Elasticsearch for fuzzy full-text search over CS records.

## Stores

### CS App Database (`continuumCsAppDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumCsAppDb` |
| Purpose | Primary relational data store for CS application data (orders history, issue records, user CS notes, etc.) |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| CS Issues / Tickets | Tracks customer service cases and resolutions | issue_id, user_id, order_id, status, created_at |
| User CS Records | Stores CS-specific annotations and history for users | user_id, cs_note, last_contact_at |
| Order CS Records | CS-side view and annotations on orders | order_id, refund_status, cs_agent_id |
| Audit / Consent Log | Records CS agent actions for compliance | agent_id, action, target_id, logged_at |

#### Access Patterns

- **Read**: CS agents query by user_id, order_id, or issue_id; Elasticsearch backs fuzzy search; direct MySQL queries for record lookup
- **Write**: Issue creation and state transitions; GDPR erasure overwrites PII fields; CS agent notes appended on resolution
- **Indexes**: Indexes on user_id, order_id, and status fields expected for query performance (specific indexes not enumerable from DSL inventory)

### CS Redis Cache (`continuumCsRedisCache`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumCsRedisCache` |
| Purpose | Cache, session store, Resque job queue backing store, and feature toggles |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| CS Agent Sessions | Warden session data for logged-in CS agents | session_id, agent_id, expires_at |
| Resque Job Queues | Backing store for all Resque background job queues | queue name, job payload |
| Object / Fragment Cache | Cached responses from downstream services (orders, users, deals) | cache_key, value, TTL |
| Feature Toggles | Runtime feature flag state | flag_name, enabled |

#### Access Patterns

- **Read**: Session lookup on each request; job dequeue by Resque workers; cache hit checks before downstream calls
- **Write**: Session write on login; job enqueue on task creation; cache population after downstream service responses
- **Indexes**: Redis key-space design; no relational indexes

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumCsRedisCache` | redis | Session storage, job queue, application object cache, feature toggles | Session: configurable; Object cache: short-lived (TTL not specified in inventory) |
| Memcached | memcached | Fragment/object caching for CS UI page rendering | TTL not specified in inventory |
| Elasticsearch index | elasticsearch | Fuzzy search index over CS records (users, orders, issues) | Not applicable (persistent index) |

## Data Flows

- CS agent actions in `continuumCsWebApp` and `continuumCsApi` write directly to `continuumCsAppDb` via ActiveRecord.
- `continuumCsBackgroundJobs` reads from and writes to `continuumCsAppDb` for batch exports and GDPR erasure operations.
- Session data is written to `continuumCsRedisCache` by Warden on agent login and read on every authenticated request.
- Resque job payloads are enqueued to `continuumCsRedisCache` by the Web App, API, and cron tasks; workers in `continuumCsBackgroundJobs` dequeue and process them.
- Elasticsearch is populated from `continuumCsAppDb` data to support fuzzy search; the indexing pipeline details are managed operationally.
