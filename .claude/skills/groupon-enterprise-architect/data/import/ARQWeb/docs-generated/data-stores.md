---
service: "ARQWeb"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumArqPostgres"
    type: "postgresql"
    purpose: "Primary relational store for access requests, job queue, audit trails, and configuration data"
---

# Data Stores

## Overview

ARQWeb uses a single owned PostgreSQL database as its primary data store. All access request state, approval records, job queue entries, audit logs, and application configuration are persisted in this database. Both the web application (`continuumArqWebApp`) and the background worker (`continuumArqWorker`) read from and write to this database. There are no caches or secondary stores identified in the architecture model.

## Stores

### ARQ PostgreSQL (`continuumArqPostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumArqPostgres` |
| Purpose | Stores ARQ requests, background jobs, audit trails, and configuration data |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Access Requests | Stores submitted access requests and their current state | request_id, requester, target_system, status, created_at |
| Approval Records | Tracks approval/rejection decisions per request | request_id, approver, decision, decided_at |
| Job Queue | Stores queued and cron-scheduled jobs for the ARQ Worker | job_id, job_type, status, scheduled_at, attempts, last_error |
| Audit Trail | Immutable log of all access decisions and system actions | event_id, event_type, actor, target, timestamp |
| Tokens | Authentication/authorization tokens for request workflows | token_id, token_value, expires_at, request_id |
| Configuration | Application and workflow configuration data | key, value, updated_at |

> Entity names are inferred from the architecture model description. Actual table names should be confirmed from the application source or migration files.

#### Access Patterns

- **Read (Web App)**: Fetches pending requests for UI display; queries requests by requester, approver, and status; validates tokens; reads configuration
- **Read (Worker)**: Polls job queue for due/runnable jobs; reads job parameters for execution
- **Write (Web App)**: Inserts new access requests; records approval/rejection decisions; creates job queue entries; writes audit records; manages tokens
- **Write (Worker)**: Updates job execution status, retry counts, and last_error; appends audit records for completed external operations; marks jobs as complete or failed
- **Indexes**: > No evidence found in codebase. Indexes on status + scheduled_at (job queue polling) and request_id (lookup) are expected.

## Caches

> No evidence found in codebase. No caching layer (Redis, Memcached, in-memory) was identified in the architecture model.

## Data Flows

All persistent state flows through PostgreSQL:
- The web application writes new access requests and enqueues background jobs synchronously during HTTP request handling.
- The ARQ Worker polls the job table, executes the required external calls (LDAP, GitHub, Jira, Workday, Cyclops, SMTP, webhooks), and updates job status and audit records after each execution.
- No CDC, ETL, or replication patterns are identified for this database.
