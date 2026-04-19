---
service: "ckod-ui"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumCkodPrimaryMysql"
    type: "mysql"
    purpose: "Primary CKOD data store — SLO definitions, deployment records, incidents, teams, projects, cost alerts"
  - id: "continuumCkodAirflowMysql"
    type: "mysql"
    purpose: "Airflow-related CKOD data — Airflow SLA monitoring definitions and pipeline run data"
---

# Data Stores

## Overview

ckod-ui owns two MySQL databases accessed via Prisma ORM. The **CKOD Primary MySQL** database is the main operational store holding SLO/SLA definitions and job details for all tracked platforms (Keboola, EDW, SEM, RM, OP, CDP, MDS Feeds), deployment tracker records, JIRA incident data, team membership, Keboola project metadata, and cost alert data. The **CKOD Airflow MySQL** database holds Airflow-specific SLA monitoring definitions. Both stores are accessed via dual Prisma clients — `prismaRO` (read-only, default) and `prismaRW` (read-write, used sparingly). There are no caches.

## Stores

### CKOD Primary MySQL (`continuumCkodPrimaryMysql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumCkodPrimaryMysql` |
| Purpose | Primary relational store for all DataOps operational data |
| Ownership | owned |
| Migrations path | `prisma/schema.prisma` (Prisma-managed schema; Flyway versioning visible in `schema_version` table) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `CKOD_TEAMS` | Team definitions for access control | `team_name`, `display_name`, `description` |
| `CKOD_TEAM_MEMBERS` | Team membership for authorization | `team_id`, `user_email`, `role` |
| `ACTIVE_USER` | Directory of active users | `full_name`, `email` |
| `DND_CRITICAL_INCIDENTS` | JIRA critical incident records | `jira_key`, `title`, `status`, `severity`, `service_name` |
| `KEBOOLA_SLA_DEFINITION` | SLO threshold definitions for Keboola flows | `JOB_NAME`, `JOB_PROJECT`, `SLA_UTC`, `SOFT_DELETE` |
| `KEBOOLA_SLA_JOB_DETAIL` | Per-run SLO compliance records for Keboola | `JOB_NAME`, `SLA_STATUS`, `DELAYED_BY`, `ETL_DATE` |
| `EDW_SLA_DEFINITION` | SLO definitions for EDW jobs | `JOB_NAME`, `SLA_UTC`, `SUBJECT_AREA` |
| `EDW_SLA_JOB_DETAIL` | Per-run SLO compliance records for EDW | `JOB_NAME`, `SLA_STATUS`, `DELAYED_BY` |
| `SEM_SLA_DEFINITION` | SLO definitions for SEM jobs | `JOB_NAME`, `SLA_UTC`, `SUBJECT_AREA` |
| `SEM_SLA_JOB_DETAIL` | Per-run SLO compliance records for SEM | `JOB_NAME`, `SLA_STATUS`, `DELAYED_BY` |
| `RM_SLA_DEFINITION` | SLO definitions for RM jobs | `JOB_NAME`, `SLA_UTC`, `SUBJECT_AREA` |
| `RM_SLA_JOB_DETAIL` | Per-run SLO compliance records for RM | `JOB_NAME`, `SLA_STATUS`, `DELAYED_BY` |
| `OP_SLA_DEFINITION` | SLO definitions for OP jobs | `JOB_NAME`, `SLA_UTC`, `GROUPS_ID`, `JOB_ID` |
| `OP_SLA_JOB_DETAIL` | Per-run SLO compliance records for OP | `JOB_NAME`, `SLA_STATUS`, `PRIORITY`, `DELAYED_BY` |
| `CDP_SLO_DEFINITION` | SLO definitions for CDP jobs | `JOB_NAME`, `SLA_UTC`, `SUBJECT_AREA` |
| `CDP_SLO_JOB_DETAIL` | Per-run SLO compliance records for CDP | `JOB_NAME`, `SLA_STATUS`, `DELAYED_BY`, `UNQUALIFIED_SLA_RUN` |
| `MDS_FEED_SLO_DEFINITION` | SLO definitions for MDS Feed jobs | `JOB_NAME`, `FEED_UUID`, `SLA_UTC` |
| `MDS_FEED_SLO_JOB_DETAIL` | Per-run SLO compliance records for MDS Feeds | `JOB_NAME`, `SLA_STATUS`, `DELAYED_BY` |
| `ckod_deployment_tracker` | Keboola deployment ticket records | `ticket_id`, `project_name`, `status`, `requested_by` |
| `KEBOOLA_DEPLOYMENT_CONFIG` | Individual component changes within a Keboola deployment | `tracker_id`, `component_id`, `change_type`, `version_identifier` |
| `pipeline_deployment` | Airflow pipeline deployment records | `deployment_ticket_id`, `dag_id`, `environment`, `status`, `is_sox` |
| `keboola_project` | Keboola project metadata | `id`, `name`, `token`, `is_sox`, `poc_email`, `team_email` |
| `keboola_pipeline` | Keboola pipeline configuration registry | `component`, `config`, `project_id`, `is_critical` |
| `keboola_pipeline_run` | Historical Keboola pipeline run records | `run_id`, `project_id`, `status`, `run_start_time`, `run_end_time` |
| `KEBOOLA_ALERT_TRACKER` | Alert tracking for failed Keboola flows | `PROJECT_ID`, `FLOW_NAME`, `STATUS`, `JIRA_ID`, `RESOLVED` |
| `dnd_cost_alert` | Cost anomaly alert records | `service_name`, `cost`, `previous_avg`, `date` |
| `cost_alert_config` | Cost alert configuration thresholds | `alert_name`, `check_lookback`, `baseline_lookback`, `threshold` |
| `kbc_project_cost` | Per-project Keboola cost data | `kbc_project_id`, `date`, `cost` |
| `SLO_AUDIT_LOG` | Audit log of SLO definition changes | `TABLE_NAME`, `ACTION`, `USER_EMAIL`, `PAYLOAD` |
| `keboola_runbook_flow_mapping` | Maps flows to runbook URLs and action plans | `project_id`, `flow_id`, `runbook_url`, `action_plan` |
| `service_parent_ticket_mapping` | Maps services to JIRA parent tickets for deployments | `service`, `parent_ticket`, `is_active` |

#### Access Patterns

- **Read**: Majority of reads use `prismaRO` (read-only connection via `CKOD_DB_RO`). SLO job details are queried with ETL date filters; deployment records use status and date range filters.
- **Write**: `prismaRW` (via `CKOD_DB_RW`) is used for deployment record creation, SLO definition management (create/update/soft-delete), audit logging, and Keboola project updates.
- **Indexes**: Notable indexes include `idx_user_email` on `CKOD_TEAM_MEMBERS`, `idx_etl_date_status` on `CDP_SLO_JOB_DETAIL`, and composite primary keys on `keboola_pipeline` and `keboola_pipeline_run`.

### CKOD Airflow MySQL (`continuumCkodAirflowMysql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumCkodAirflowMysql` |
| Purpose | Airflow-specific SLA monitoring — definitions and pipeline run telemetry |
| Ownership | owned |
| Migrations path | `prisma/schema.prisma` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `pre_af_sla_monitoring` | Airflow SLO monitoring definitions (task-level) | `task_id`, `group_id`, `dag_id`, `sla_time`, `is_critical` |

#### Access Patterns

- **Read**: Airflow SLA definitions and pipeline run data are read via `prismaRO` for SLO dashboard rendering.
- **Write**: SLO threshold updates for Airflow tasks are written via `prismaRW` through the SLO management interface.

## Caches

> No evidence found in codebase. ckod-ui does not use any external cache (no Redis, Memcached, etc.). RTK Query provides in-memory client-side caching with a default TTL of 10 minutes.

## Data Flows

SLO job detail data is populated externally by Keboola, Airflow, and EDW pipeline processes — ckod-ui reads this data in a read-only fashion for dashboards. Deployment records and SLO definitions are the primary writable entities managed by ckod-ui itself. Cost alert data is also populated by an external process (BigQuery telemetry pipeline) and read by ckod-ui.
