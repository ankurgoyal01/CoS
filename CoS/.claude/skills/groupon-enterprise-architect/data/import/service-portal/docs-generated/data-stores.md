---
service: "service-portal"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumServicePortalDb"
    type: "mysql"
    purpose: "Primary relational store for service catalog, check results, ORR, and cost data"
  - id: "continuumServicePortalRedis"
    type: "redis"
    purpose: "Sidekiq job queue and application-level caching"
---

# Data Stores

## Overview

Service Portal uses two data stores: a MySQL database as the primary relational store for all persistent service catalog data, and a Redis instance serving as the Sidekiq job queue and an application-level cache. Both stores are owned exclusively by Service Portal and are not shared with other services.

## Stores

### MySQL Database (`continuumServicePortalDb`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumServicePortalDb` |
| Purpose | Primary persistent store for service records, metadata, check results, ORR workflows, dependency graphs, and cost data |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `services` | Core service catalog record | id, name, tier, status, team, repository_url, created_at |
| `service_metadata` | Extended metadata for a service | service_id, owner, tech_stack, links, updated_at |
| `check_results` | Outcomes of governance checks per service | service_id, check_id, status, message, evaluated_at |
| `checks` | Definitions of governance checks | id, name, description, category |
| `dependencies` | Declared dependencies between services | source_service_id, target_service_id, dependency_type |
| `costs` | Cost records per service | service_id, amount, currency, period, recorded_at |
| `service_attributes` | Legacy attribute store (v1 API) | service_id, key, value, updated_at |
| `orr_reviews` | Operational Readiness Review workflow state | service_id, status, reviewer_id, completed_at |

#### Access Patterns

- **Read**: API requests query service records by ID or list with filters; check results queried per service; dependency graph traversal by service ID
- **Write**: Service registration and metadata updates via API; check results bulk-written by scheduled workers after each check run; cost records written by cost tracking workers
- **Indexes**: Expected indexes on `services.name`, `check_results.service_id`, `check_results.evaluated_at`, `dependencies.source_service_id`, `costs.service_id` — exact index definitions are in migration files

---

### Redis (`continuumServicePortalRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumServicePortalRedis` |
| Purpose | Sidekiq job queue (all background worker queues) and application-level caching |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Sidekiq queues | Holds enqueued, processing, scheduled, and dead background jobs | queue name, job class, args, enqueued_at |
| Sidekiq cron schedules | Stores sidekiq-cron job schedules and last-run state | cron name, cron expression, next_time |
| Application cache | Caches frequently accessed read data (e.g., service lists, check definitions) | cache key, TTL-based expiry |

#### Access Patterns

- **Read**: Sidekiq workers dequeue jobs; application reads cached API responses
- **Write**: Rails web process enqueues Sidekiq jobs after webhook receipt; workers write job completion state; application writes cache entries

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumServicePortalRedis` | Redis | Application-level API response cache and Sidekiq job/schedule state | TTL varies by cache key; Sidekiq job data retained per Sidekiq defaults |

## Data Flows

1. Inbound API requests write service and metadata records to `continuumServicePortalDb` synchronously via Rails ActiveRecord.
2. Incoming GitHub webhook events trigger Sidekiq jobs enqueued into `continuumServicePortalRedis`.
3. Sidekiq workers dequeue jobs from `continuumServicePortalRedis`, fetch data from GitHub Enterprise, and write sync results to `continuumServicePortalDb`.
4. Scheduled workers (sidekiq-cron, scheduled state in `continuumServicePortalRedis`) run check, cost, and inactivity evaluations and write results to `continuumServicePortalDb`.
5. No CDC, ETL pipeline, or cross-store replication is in evidence.
