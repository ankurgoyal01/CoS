---
service: "garvis"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumJarvisPostgres"
    type: "postgresql"
    purpose: "Primary relational database for all Garvis application state"
  - id: "continuumJarvisRedis"
    type: "redis"
    purpose: "Caching and RQ job queue backend"
---

# Data Stores

## Overview

Garvis owns two dedicated data stores: a PostgreSQL database for persistent application state and a Redis instance serving dual purpose as a cache and the RQ background job queue backend. Both stores are accessed by multiple containers — PostgreSQL by `continuumJarvisWebApp` and `continuumJarvisWorker`; Redis by all three application containers (`continuumJarvisWebApp`, `continuumJarvisBot`, and `continuumJarvisWorker`).

## Stores

### Jarvis Postgres (`continuumJarvisPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumJarvisPostgres` |
| Purpose | Primary relational database for all persistent Garvis state (change tickets, incidents, configuration, job results) |
| Ownership | owned |
| Migrations path | Django migrations (path managed within the garvis application repository) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Change records | Tracks change approval requests, status, and history | change ID, requester, status, approval chain, timestamps |
| Incident records | Stores incident metadata created or tracked by Garvis | incident ID, JIRA issue key, severity, status, timestamps |
| On-call assignments | Caches or stores on-call lookup results for audit and notification history | user, schedule, rotation period |
| Job results | Stores outcomes of completed background jobs for audit trail | job ID, job type, status, result payload, timestamps |

#### Access Patterns

- **Read**: Django ORM read queries from `continuumJarvisWebApp` for admin UI and webhook handlers; `continuumJarvisWorker` reads job context and related records during job execution
- **Write**: `continuumJarvisWebApp` writes change and incident records on webhook and admin actions; `continuumJarvisWorker` writes job results and status updates
- **Indexes**: Managed via Django migrations; specific index definitions are in the application repository

### Jarvis Redis (`continuumJarvisRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumJarvisRedis` |
| Purpose | Caching layer and RQ job queue backend; also used for Pub/Sub coordination in the bot container |
| Ownership | owned |
| Migrations path | Not applicable (schema-less) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| RQ job queues | Holds serialized background jobs pending execution | Queue name (e.g., `rq:queue:default`), job ID, payload |
| RQ failed queue | Stores jobs that exhausted retry attempts | Job ID, failure traceback, original queue |
| RQ scheduler entries | Tracks jobs scheduled for future or recurring execution | Job ID, scheduled timestamp, interval |
| Application cache | Django cache entries for frequently read data | Cache key, serialized value, TTL |

#### Access Patterns

- **Read**: `continuumJarvisWorker` dequeues jobs; `continuumJarvisWebApp` reads cache entries; `continuumJarvisBot` reads coordination state
- **Write**: `continuumJarvisWebApp` and `continuumJarvisBot` enqueue jobs; `continuumJarvisWorker` acknowledges and removes jobs; `workerScheduler` writes schedule entries
- **Indexes**: Not applicable (Redis key-based access)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumJarvisRedis` | redis | Application-level Django cache (session data, frequently read lookups) | Per-key TTL configured in Django cache settings |

## Data Flows

- `continuumJarvisBot` receives a Google Chat event via Pub/Sub, executes immediate logic, then enqueues a job to `continuumJarvisRedis` (RQ queue).
- `continuumJarvisWorker` dequeues the job from `continuumJarvisRedis`, executes it (calling JIRA, PagerDuty, GitHub, etc. as needed), and writes results to `continuumJarvisPostgres`.
- `continuumJarvisWebApp` reads state from `continuumJarvisPostgres` for the admin UI and reads/writes `continuumJarvisRedis` for cache and job enqueueing.
- No CDC, ETL pipelines, or cross-store replication are modeled for this service.
