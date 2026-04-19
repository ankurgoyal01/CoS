---
service: "ckod-backend-jtier"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumCkodMySql"
    type: "mysql"
    purpose: "Primary operational datastore for all CKOD domain data"
---

# Data Stores

## Overview

CKOD Backend JTier owns a single MySQL database (`continuumCkodMySql`) that serves as the sole persistent store for all domain data. The service establishes two separate connection pools at startup: a read-write pool (`MYSQL_RW_HOST`) and a read-only pool (`MYSQL_RO_HOST`), both targeting port 3306. Schema migrations are applied at startup via the JTier `MySQLMigrationBundle`. Connection details are stored in the secrets repository at `github.groupondev.com/PRE/ckod-api-secrets`. No caches or external data stores are used.

## Stores

### CKOD MySQL (`continuumCkodMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumCkodMySql` |
| Purpose | Primary operational datastore for deployment tracking, SLA entities, project metadata, cost alerts, dependencies, and active users |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migrations` (via `jtier-migrations` bundle) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `keboola_project` | Registered Keboola projects available for job tracking | `id`, `name`, `token`, `poc_name`, `poc_email`, `team_email`, `is_sox`, `soft_delete` |
| `ckod_deployment_tracker` | Records of each tracked deployment ticket | `ticket_id`, `project_name`, `summary`, `requested_by`, `context_ticket`, `status`, `deployed_by`, `completed_at`, `resolution_reason` |
| `keboola_deployment_config` | Per-component config snapshots associated with a deployment tracker record | FK to `ckod_deployment_tracker` |
| `keboola_pipeline` | Keboola pipeline (orchestration flow) records per project | FK to `keboola_project` |
| `keboola_project_documentation` | Documentation entries linked to a Keboola project | FK to `keboola_project` |
| `point_of_contact` | Per-project point-of-contact entries | FK to `keboola_project` |
| `dependency` | Directed dependency edges between Keboola projects | `project` FK, `dependency_project` FK |
| `project_team` | Team membership records per project | FK to `keboola_project` |
| `active_user` | Active user records | (from `ActiveUserEntity`) |
| `kbc_cost` / `kbc_telemetry` / `kbc_ws_cost` | Keboola BigQuery cost and telemetry data | date-partitioned cost figures |
| `cost_alert_config` | Alert threshold and lookback configuration | `alert_name`, `check_lookback`, `baseline_lookback`, `threshold` |
| `service_alert_config` | Mapping of services to alert configurations | `service_id`, `service_name`, `alert_id` |
| `dnd_critical_incident` | DnD critical incidents affecting data quality | `id`, `jira_key`, `title`, `severity`, `status`, `created_at` |
| `sla_job_detail` | Keboola SLA job run completion records | `JOB_DETAIL_KEY`, `SLA_DEFINITION_KEY`, `JOB_NAME`, `SLA_STATUS`, `ETL_DATE` |
| `edw_sla_job_detail` | EDW SLA job completion records | inherits `SlaJobDetailEntity` fields |
| `op_sla_job_detail` | Optimus Prime SLA job completion records | inherits `SlaJobDetailEntity` fields |
| `rm_sla_job_detail` | RM SLA job completion records | inherits `SlaJobDetailEntity` fields |
| `pipeline_deployment` | Generic pipeline deployment records | (from `PipelineDeploymentEntity`) |
| `authorization_group_membership` | Authorization group memberships per project | FK to `keboola_project` |

#### Access Patterns

- **Read**: Domain Services query via Hibernate `SessionFactory` or JPA `EntityManager` (read-only pool) using JPQL and Criteria queries. Most read endpoints accept date-range and status filter parameters that are translated into WHERE clauses.
- **Write**: Domain Services write through a separate Hibernate read-write `EntityManager` and a JDBI-backed `DataWriteDao`. Deployment tracker records are created when `/deployments/create/*` endpoints are invoked.
- **Indexes**: Not directly discoverable from entity definitions; migration scripts manage index definitions at the database level.

## Caches

> No evidence found in codebase. No cache layer is used; all reads go directly to MySQL.

## Data Flows

All data enters the store through two paths:
1. The worker's scheduled Keboola polling loop writes new and updated job run records.
2. API endpoint handlers (deployment creation, cost alert management) write transactionally when called by consumers.

Reads are served entirely from MySQL via the read-only connection pool. No ETL or replication to external analytics stores is performed by this service.
