---
service: "n8n"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumN8nPostgres"
    type: "postgresql"
    purpose: "Workflow definitions, credentials metadata, execution state"
  - id: "redis-memorystore"
    type: "redis"
    purpose: "Job queue (Bull) for queue execution mode"
---

# Data Stores

## Overview

n8n uses two primary data stores per deployed instance: a PostgreSQL 16 database as the system of record for all persistent state, and a Redis Memorystore instance as the job queue backend for distributed execution. Each domain-scoped instance (default, finance, merchant, llm-traffic, business, playground) operates with its own isolated Redis Memorystore. The PostgreSQL instance is shared across the n8n Service and queue-worker pods.

## Stores

### n8n PostgreSQL (`continuumN8nPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumN8nPostgres` |
| Purpose | Primary system-of-record for workflow definitions, credentials metadata, execution history, and queue metadata |
| Ownership | owned |
| Migrations path | Managed by n8n core on startup (built-in migration runner) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `workflow_entity` | Stores workflow definitions including nodes, connections, and settings | id, name, active, nodes, connections, settings, createdAt, updatedAt |
| `execution_entity` | Records workflow execution history and results | id, workflowId, status, startedAt, stoppedAt, data |
| `credentials_entity` | Stores encrypted credential configurations for workflow integrations | id, name, type, data (encrypted), createdAt, updatedAt |
| `tag_entity` | Tags for organizing workflows | id, name |
| `user` | n8n user accounts with roles | id, email, role |

#### Access Patterns

- **Read**: Workflow engine reads workflow definitions and credentials on each execution trigger; queue-workers read job context from the execution table
- **Write**: Execution records written after each workflow run (success or failure); workflow definitions written when users save/publish via editor
- **Indexes**: Managed by n8n core migrations; notable index on `execution_entity.workflowId` and `execution_entity.status` for execution history queries

### n8n PostgreSQL — Connection Pool

| Property | Value |
|----------|-------|
| Pool size | 100 (`DB_POSTGRESDB_POOL_SIZE=100` on queue-worker pods) |
| Applies to | All queue-worker instances |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| n8n-default-memorystore | redis (GCP Memorystore) | Bull job queue for default instance queue workers | Job-based (lock duration: 60,000 ms) |
| n8n-finance-memorystore | redis (GCP Memorystore) | Bull job queue for finance instance queue workers | Job-based (lock duration: 60,000 ms) |
| n8n-merchant-memorystore | redis (GCP Memorystore) | Bull job queue for merchant instance queue workers | Job-based (lock duration: 60,000 ms) |
| n8n-llm-traffic-memorystore | redis (GCP Memorystore) | Bull job queue for llm-traffic instance queue workers | Job-based (lock duration: 60,000 ms) |
| n8n-business-topic-memorystore | redis (GCP Memorystore) | Bull job queue for business instance queue workers | Job-based (lock duration: 60,000 ms) |
| n8n-playground-memorystore | redis (GCP Memorystore) | Bull job queue for playground instance queue workers | Job-based (lock duration: 60,000 ms) |

All Memorystore instances are hosted on `us-central1.caches.prod.gcp.groupondev.com` (production) or `us-central1.caches.stable.gcp.groupondev.com` (staging), port 6379.

## Data Flows

- Workflow triggers (webhook, schedule) cause the n8n Service (workflow engine) to create a job in the Redis queue and write an initial execution record to PostgreSQL.
- Queue-worker pods consume jobs from Redis, execute the workflow, and update the execution record in PostgreSQL with the result.
- External task runners (JavaScript, Python) receive task payloads via the HTTP broker endpoint; they do not write directly to PostgreSQL — the queue-worker persists their results.
- Persistent volumes (`/home/node/.n8n`, 10G–100G per instance) back the n8n data directory for installed community packages and local file state.
