---
service: "command-center"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumCommandCenterMysql"
    type: "mysql"
    purpose: "Primary relational store for users, jobs, tool metadata, report artifacts, and delayed job queue records"
---

# Data Stores

## Overview

Command Center owns a single MySQL database (`continuumCommandCenterMysql`) as its primary data store. Both the web container (`continuumCommandCenterWeb`) and the worker container (`continuumCommandCenterWorker`) access this database — the web container for reading and writing tool, user, and job state, and the worker container for dequeuing, updating, and finalizing delayed job records. The database also stores the Delayed Job queue table, making it the coordination point between the web and worker processes.

## Stores

### Command Center MySQL (`continuumCommandCenterMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumCommandCenterMysql` |
| Purpose | Primary relational store for users, jobs, tool metadata, report artifacts, and delayed job queue records |
| Ownership | owned |
| Migrations path | > No evidence found in the architecture inventory. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `users` | Stores internal user accounts and access controls for Command Center staff | User identity, role, access permissions |
| `tools` | Tool metadata — registered operational tools and their configurations | Tool name, type, configuration |
| `delayed_jobs` | Delayed Job queue table — queued, in-progress, and completed background job records | Handler (serialized job), run_at, locked_at, failed_at, attempts |
| `logs` | Audit log of tool executions and workflow state transitions | Tool, user, timestamp, outcome |
| `report_artifacts` | References to CSV and report artifacts stored in object storage (S3) | Artifact reference, job ID, creation timestamp |

> Specific table names are inferred from the `cmdCenter_schema` component description: "Tables for users, tools, logs, report artifacts, and delayed job queue state." Actual schema is defined in the command-center application repository.

#### Access Patterns

- **Read**: `continuumCommandCenterWeb` reads tool metadata, user state, and job status to render dashboards and validate tool requests. `continuumCommandCenterWorker` reads queued delayed_job records to determine next work units.
- **Write**: `continuumCommandCenterWeb` writes new job records, audit log entries, and report artifact references. `continuumCommandCenterWorker` updates delayed_job lock state, execution progress, and final outcomes.
- **Indexes**: > No evidence found in the architecture inventory. Standard indexes on `delayed_jobs.run_at`, `delayed_jobs.locked_at`, and `delayed_jobs.queue` are expected per delayed_job conventions.

## Caches

> Not applicable. No caching layer is evidenced in the architecture inventory.

## Data Flows

- `continuumCommandCenterWeb` (via `cmdCenter_webPersistence`) writes job requests and enqueues delayed_job records to `continuumCommandCenterMysql`.
- `continuumCommandCenterWorker` (via `cmdCenter_workerRunner`) polls `continuumCommandCenterMysql` for ready delayed_job records, locks them, executes the work, and writes results back.
- Report artifacts produced by job execution are referenced in `continuumCommandCenterMysql` but the artifact payloads (CSV files) are stored in `cloudPlatform` (S3).
