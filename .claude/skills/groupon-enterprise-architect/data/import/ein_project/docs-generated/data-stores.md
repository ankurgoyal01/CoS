---
service: "ein_project"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumProdcatPostgres"
    type: "postgresql"
    purpose: "Primary store for deployment records, approval state, and configuration"
  - id: "continuumProdcatRedis"
    type: "redis"
    purpose: "Session storage, validation result cache, and RQ job queue"
---

# Data Stores

## Overview

ProdCat uses two managed data stores on Google Cloud: a Cloud SQL PostgreSQL instance as the authoritative record store for all deployment and configuration data, and a Memorystore Redis instance that serves three purposes simultaneously — HTTP session persistence, validation result caching, and the RQ background job queue. Both stores are owned exclusively by ProdCat.

## Stores

### ProdCat Cloud SQL PostgreSQL (`continuumProdcatPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumProdcatPostgres` |
| Purpose | Primary store for deployment change records, approval state, region configuration, approver lists, change windows, holiday policies, scheduled locks, and client registrations |
| Ownership | owned |
| Migrations path | `> No evidence found — managed via Django migrations` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Change requests | Records each deployment change request and its approval outcome | service, region, ticket reference, approval status, timestamps |
| Change log | Auditable history of all change request decisions | change_id, decision, actor, timestamp |
| Regions | Configured deployment regions that policies are scoped to | region name, lock state |
| Change windows | Permitted and frozen deployment time windows | start, end, recurrence, policy reference |
| Holiday policies | Date-based deployment freeze rules | date, region, policy type |
| Scheduled locks | Time-boxed manual region locks | region, start, end, reason |
| Approvers | Users authorized to approve change requests | user identity, region scope |
| Clients | Registered deployment systems allowed to submit change requests | client name, credentials |
| Settings | Runtime configuration values for policy engine | key, value, scope |

#### Access Patterns

- **Read**: Web App reads policy data, region locks, change windows, and approver lists on every change request validation. Worker reads pending jobs and deployment records during scheduled runs.
- **Write**: Web App writes new change request records and updates approval state. Worker writes ticket closure outcomes and updates deployment records after background job execution.
- **Indexes**: Managed via Django ORM migrations; specific index definitions not visible in the architecture model.

---

### ProdCat Memorystore Redis (`continuumProdcatRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumProdcatRedis` |
| Purpose | Session storage, validation result cache, and RQ job queue |
| Ownership | owned |
| Migrations path | Not applicable (schema-less) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Session data | Stores authenticated user sessions for the web UI | session key, user identity, expiry |
| Validation cache | Caches the result of expensive validation checks to reduce downstream API calls | change request hash, validation result, TTL |
| RQ job queues | Holds serialized background job payloads consumed by the Worker | queue name, job id, payload |

#### Access Patterns

- **Read**: Web App reads cached validation results before invoking external APIs; reads session data on each authenticated request. Worker reads (pops) job payloads from RQ queues.
- **Write**: Web App writes validation results to cache after external API calls; writes session data on login. Web App enqueues jobs via `asyncTaskDispatcher`. Worker acknowledges and removes jobs after processing.
- **Indexes**: Key-value access by session key and cache key; RQ manages its own queue key namespace.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Validation result cache | redis (`continuumProdcatRedis`) | Avoids redundant JIRA/JSM/Service Portal calls for the same change request within a window | Not documented — configured in application |
| Session cache | redis (`continuumProdcatRedis`) | Persists authenticated user sessions across Gunicorn workers | Not documented — Django session expiry setting |

## Data Flows

On an inbound change request: the Web App first checks Redis for a cached validation result. On a cache miss it queries PostgreSQL for policy and deployment data, calls external APIs (JIRA, JSM, Service Portal), writes the result back to Redis, persists the final change record to PostgreSQL, and enqueues any async follow-up jobs to Redis. The Worker consumes those jobs from Redis, performs JIRA ticket updates, and writes outcomes back to PostgreSQL.
