---
service: "pre_task_tracker"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for pre_task_tracker.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Airflow Task Failure Detection and Alerting](airflow-task-failure-alerting.md) | scheduled | `@continuous` (PRE_TASK_TRACKER3 DAG) | Detects failed, long-running, queued, and skip-sequence Airflow tasks and fires JSM alerts |
| [Megatron EOD Delay Detection](megatron-eod-delay.md) | scheduled | Cron `*/15 2-8 * * *` | Checks Megatron table loads against end-of-day SLA deadlines and creates JSM alerts |
| [Megatron Lag Monitoring](megatron-lag-monitoring.md) | scheduled | Cron `*/15 8-23 * * *` | Monitors intra-day data lag across Megatron tables and manages JSM alert lifecycle |
| [Dataproc Cluster Monitoring](dataproc-cluster-monitoring.md) | scheduled | `@continuous` (PRE_CLUSTER_TRACKER DAG) | Detects long-running and idle Dataproc clusters and manages their JSM alerts |
| [SLA Entry Update](sla-entry-update.md) | scheduled | Cron `*/3 * * * *` (PRE-CKOD-EDW/RM-SLA-UPDATER DAG) | Reads Airflow DAG run outcomes and writes updated SLA status records to the CKOD dashboard database |
| [MBUS Backlog Monitoring and DAG Trigger](mbus-backlog-monitoring.md) | scheduled | Cron `0 * * * *` (mbus_backlog_monitor DAG, prod only) | Polls MBUS queue backlog counts via Grafana/Prometheus and triggers catch-up pipeline DAGs when thresholds are exceeded |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 6 |

## Cross-Service Flows

- The **SLA Entry Update** flow spans `continuumPreTaskTracker` and the CKOD database; the canonical dynamic diagram is `dynamic-pre-task-tracker-sla-update-flow`
- The **Airflow Task Failure Detection** flow reads from `continuumPreTaskTrackerAirflowDb` (PostgreSQL) and writes alerts to `continuumJiraService` (Atlassian JSM)
- The **MBUS Backlog Monitoring** flow queries `cloudPlatform` (Grafana/Prometheus) and triggers DAGs in the same Composer environment
