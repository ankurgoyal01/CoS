---
service: "ckod-worker"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumCkodMySql"
    type: "mysql"
    purpose: "Primary relational data store for SLA definitions, job runs, and operational state"
  - id: "servicePortal"
    type: "mysql"
    purpose: "External read-only source for users, groups, and memberships (authorization sync)"
  - id: "optimusPrime"
    type: "postgresql"
    purpose: "External read-only source for Optimus Prime job runs used in SLA calculations"
---

# Data Stores

## Overview

CKOD Worker owns one MySQL database (`continuumCkodMySql`) as its primary operational store. It also reads from two external shared databases: the Service Portal MySQL database (for user/group authorization data) and the Optimus Prime PostgreSQL database (for job run data used in SLA calculations). All write operations are confined to the owned CKOD database; the external databases are read-only sources.

## Stores

### CKOD Database (`continuumCkodMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumCkodMySql` |
| Purpose | Primary relational data store for SLA definitions, job runs, and operational state |
| Ownership | owned |
| Migrations path | > No evidence found in codebase |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| sla_definitions | Stores SLA configuration for monitored pipeline flows | flow_type, threshold, enabled |
| job_runs | Tracks individual pipeline job run records and their SLA status | run_id, flow_type, status, started_at, completed_at |
| deployment_tracking | Stores deployment approval and completion state | deployment_id, status, approved_by, completed_at |
| worker_execution_log | Tracks scheduler job execution history and outcomes | job_name, executed_at, status, error_detail |

> Specific table names and fields above are inferred from component responsibilities in the architecture model. Exact schema must be verified against database migrations.

#### Access Patterns

- **Read**: `cwSlaOrchestration` reads SLA definitions and run states. `cwMonitoring` reads run records to evaluate failures and warnings. `cwDeploymentOps` reads deployment tracking data.
- **Write**: `cwSlaOrchestration` writes SLA entries and updates run states. `cwMonitoring` writes monitoring status. `cwDataSync` persists synchronized pipeline and cost data from Keboola.
- **Indexes**: > No evidence found in codebase for specific index definitions.

### Service Portal Database (`servicePortal`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `servicePortal` |
| Purpose | Source-of-truth for groups, memberships, and users used in authorization sync |
| Ownership | external / shared |
| Migrations path | > Not applicable — external database |

#### Access Patterns

- **Read**: `cwDataSync` reads user, group, and membership data to rebuild authorization tables in the CKOD database.
- **Write**: Read-only from CKOD Worker's perspective.
- **Indexes**: > No evidence found in codebase.

### Optimus Prime Database (`optimusPrime`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `optimusPrime` |
| Purpose | Operational job-run source for Optimus Prime SLA tracking |
| Ownership | external / shared |
| Migrations path | > Not applicable — external database |

#### Access Patterns

- **Read**: `cwSlaOrchestration` reads Optimus Prime job run records to compute SLA compliance for OP-managed flows.
- **Write**: Read-only from CKOD Worker's perspective.
- **Indexes**: > No evidence found in codebase.

## Caches

> No evidence found in codebase for cache usage. No Redis, Memcached, or in-memory cache is referenced in the architecture model.

## Data Flows

- Pipeline run data is read from `keboola` (HTTPS) and `optimusPrime` (PostgreSQL) by `cwSlaOrchestration` and `cwDataSync`, then written to `continuumCkodMySql`.
- User/group data is read from `servicePortal` (MySQL) by `cwDataSync` and used to rebuild authorization structures in `continuumCkodMySql`.
- Incident and deployment state is written to `continuumCkodMySql` by `cwDeploymentOps` after successful Jira/JSM ticket transitions.
- Telemetry is emitted to Telegraf/InfluxDB (infrastructure-level, stub: `unknownTelegrafInfluxdb2f7bbc64`); this data flow is not owned by CKOD Worker.
