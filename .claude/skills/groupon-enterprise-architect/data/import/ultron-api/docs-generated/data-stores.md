---
service: "ultron-api"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumUltronDatabase"
    type: "relational"
    purpose: "Primary metadata store for jobs, instances, resources, groups, permissions, and watchdog data"
  - id: "continuumQuartzSchedulerDb"
    type: "relational"
    purpose: "Persists Quartz scheduler triggers and state"
---

# Data Stores

## Overview

ultron-api owns two relational databases accessed exclusively via the Slick repository layer. The primary database (`continuumUltronDatabase`) is the source of truth for all job orchestration metadata. The secondary database (`continuumQuartzSchedulerDb`) is dedicated to Quartz scheduler state persistence, enabling reliable trigger recovery after restarts.

## Stores

### Ultron Database (`continuumUltronDatabase`)

| Property | Value |
|----------|-------|
| Type | Relational (MySQL or PostgreSQL — specific engine not specified in architecture model) |
| Architecture ref | `continuumUltronDatabase` |
| Purpose | Primary metadata store for jobs, instances, resources, groups, permissions, and watchdog metadata |
| Ownership | owned |
| Migrations path | Managed via Play Evolutions (accessed via `appController` evolution endpoints) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `jobs` | Job definitions and scheduling metadata | job_id, name, schedule, owner_group, status |
| `job_instances` | Individual job execution records | instance_id, job_id, start_time, end_time, state |
| `resources` | Registered data resources tracked by Ultron | resource_id, name, type_id, location_id |
| `resource_types` | Taxonomy of resource types | type_id, name, description |
| `resource_locations` | Physical or logical locations for resources | location_id, name, connection_info |
| `groups` | Permission groups for job ownership | group_id, name |
| `users` | Users registered in Ultron | user_id, name, email |
| `memberships` | User-to-group assignments | user_id, group_id, role |
| `teams` | Team definitions | team_id, name |
| `watchdog_metadata` | Watchdog check thresholds and alert state | job_id, expected_interval, last_seen, alert_sent |

> Entity names are inferred from the component responsibilities in the architecture model. Verify against the Slick table mapping files in the service source repository.

#### Access Patterns

- **Read**: All controller components read via `repositoryLayer` using Slick queries; lineage graph reads load resource and dependency data via `resourceLineage`
- **Write**: Job, instance, resource, group, user, and team controllers write metadata via `repositoryLayer`; `scheduler` writes watchdog state updates
- **Indexes**: Not specified in architecture model; verify against schema migrations

### Quartz Scheduler DB (`continuumQuartzSchedulerDb`)

| Property | Value |
|----------|-------|
| Type | Relational (MySQL or PostgreSQL — specific engine not specified in architecture model) |
| Architecture ref | `continuumQuartzSchedulerDb` |
| Purpose | Persists Quartz scheduler triggers and execution state for reliable restart recovery |
| Ownership | owned |
| Migrations path | Managed by Quartz framework DDL scripts |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `QRTZ_TRIGGERS` | Quartz trigger definitions | trigger_name, trigger_group, job_name, next_fire_time |
| `QRTZ_JOB_DETAILS` | Quartz job detail records | job_name, job_group, job_class |
| `QRTZ_FIRED_TRIGGERS` | In-flight trigger execution records | entry_id, trigger_name, fired_time, state |

> Quartz table names follow the standard Quartz 2.x schema. Verify prefix (`QRTZ_`) in the service's Quartz configuration.

#### Access Patterns

- **Read**: Quartz reads trigger state on scheduler startup and during execution cycles
- **Write**: Quartz writes trigger state, fired trigger records, and completion status
- **Indexes**: Standard Quartz schema indexes on trigger names and next fire times

## Caches

> No evidence found in codebase. ultron-api does not use an external cache layer. All reads go directly to the relational databases via the Slick repository layer.

## Data Flows

Job metadata flows:
1. Job runner clients POST job instance registrations to `continuumUltronApi`
2. `repositoryLayer` writes instance records to `continuumUltronDatabase`
3. Controllers read metadata back from `continuumUltronDatabase` on API queries and UI page renders

Scheduler state flow:
1. `scheduler` component in `continuumUltronApi` initializes Quartz with JDBC job store pointing to `continuumQuartzSchedulerDb`
2. On each watchdog cycle, Quartz fires the scheduled trigger; `scheduler` queries `continuumUltronDatabase` for overdue job instances
3. If watchdog threshold is exceeded, `scheduler` invokes `emailManager` which dispatches an alert via `smtpEmailService_2d1e`
