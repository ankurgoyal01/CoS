---
service: "backbeat"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumBackbeatPostgres"
    type: "postgresql"
    purpose: "Primary workflow state store"
  - id: "continuumBackbeatRedis"
    type: "redis"
    purpose: "Sidekiq job queue and transient runtime state"
---

# Data Stores

## Overview

Backbeat uses two data stores: a PostgreSQL relational database as the primary durable state store for all workflow, node, and user data; and a Redis instance used exclusively as the Sidekiq job queue backend and transient cache for queue telemetry. Both stores are owned and dedicated to the Backbeat service.

## Stores

### Backbeat Postgres (`continuumBackbeatPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumBackbeatPostgres` |
| Purpose | Primary relational datastore for workflows, nodes, users, and status changes |
| Ownership | owned |
| Migrations path | `db/migrate/` (inferred from ActiveRecord convention — confirm in source) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `workflows` | Stores workflow graph definitions and lifecycle state | `id`, `name`, `subject`, `status`, `created_at`, `updated_at` |
| `nodes` | Represents individual activity or decision steps within a workflow | `id`, `workflow_id`, `name`, `status`, `fires_at`, `parent_id` |
| `users` | Tracks workflow client registrations and callback configurations | `id`, `name`, `decision_endpoint`, `activity_endpoint` |
| `status_changes` | Audit log of all state transitions for workflows and nodes | `id`, `node_id`, `from_status`, `to_status`, `created_at` |

> Table names are inferred from the `bbPersistenceModels` component description ("ActiveRecord models and query helpers for workflows, nodes, and users"). Confirm against migration files in the service source.

#### Access Patterns

- **Read**: `continuumBackbeatApiRuntime` queries current workflow and node state to serve API responses; `continuumBackbeatWorkerRuntime` loads workflow/node records before executing events
- **Write**: `continuumBackbeatApiRuntime` creates workflow and node records on workflow submission; `continuumBackbeatWorkerRuntime` updates node and workflow status after event execution
- **Indexes**: Not visible from architecture inventory — confirm against ActiveRecord schema

### Backbeat Redis (`continuumBackbeatRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumBackbeatRedis` |
| Purpose | Queueing and cache backend for Sidekiq jobs and transient runtime state |
| Ownership | owned |
| Migrations path | Not applicable |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumBackbeatRedis` | redis | Sidekiq job queue storage; Sidekiq queue telemetry read by API health/stats endpoints | Sidekiq default (job-lifecycle-bound) |

## Data Flows

- `continuumBackbeatApiRuntime` writes new workflow and node records to `continuumBackbeatPostgres`, then enqueues a job reference into `continuumBackbeatRedis`.
- `continuumBackbeatWorkerRuntime` dequeues the job from `continuumBackbeatRedis`, reads the full workflow/node state from `continuumBackbeatPostgres`, executes the event, and writes the resulting status updates back to `continuumBackbeatPostgres`.
- No CDC, ETL, or cross-store replication pipelines are evidenced in the architecture inventory.
