---
service: "pre_task_tracker"
title: "Megatron Lag Monitoring"
generated: "2026-03-03"
type: flow
flow_name: "megatron-lag-monitoring"
flow_type: scheduled
trigger: "Cron schedule */15 8-23 * * * on pre_check_megatron_lag and pre_resolve_megatron_lag DAGs"
participants:
  - "continuumPreTaskTracker"
  - "edw"
  - "continuumJiraService"
architecture_ref: "dynamic-pre-task-tracker-sla-update-flow"
---

# Megatron Lag Monitoring

## Summary

Two paired Airflow DAGs — `pre_check_megatron_lag` and `pre_resolve_megatron_lag` — monitor intra-day data lag across Megatron pipeline tables. Every 15 minutes between 08:00 and 23:00 UTC, the check DAG computes the current lag in hours for each monitored table by comparing `consistent_before_hard` (data freshness timestamp) against the current UTC time. Tables exceeding their configured `delay_threshold` (in hours) receive a P3 JSM alert, unless a Megatron load process is actively running for that table. The resolve DAG closes alerts when tables come back within threshold.

## Trigger

- **Type**: schedule
- **Source**: Airflow cron schedule `*/15 8-23 * * *` on DAGs `pre_check_megatron_lag` and `pre_resolve_megatron_lag`
- **Frequency**: Every 15 minutes between 08:00–23:00 UTC daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| pre_check_megatron_lag DAG | Computes lag and fires JSM alerts for breached tables | `continuumPreTaskTracker` |
| pre_resolve_megatron_lag DAG | Closes JSM alerts when tables recover | `continuumPreTaskTracker` |
| DWH Manage MySQL (`dwh_manage` conn) | Provides `consistent_before_hard` data freshness timestamps | `edw` |
| Megatron MySQL (`megatron` conn) | Provides `etl_process_status` for running instance suppression | `edw` |
| Atlassian JSM | Receives P3 alert create and close calls | `continuumJiraService` |

## Steps

### Check flow (pre_check_megatron_lag)

1. **Validate project ID**: Checks `GCP_PROJECT` against allowed PIPELINES project IDs; skips if not applicable
   - From: `continuumPreTaskTracker` (dagDefinitions)
   - To: Cloud Composer environment variable

2. **Load YAML config**: Reads `orchestrator/config.yml` to get all monitored table entries
   - From: `continuumPreTaskTracker` (dagDefinitions)
   - To: local filesystem

3. **Compute lag for each table**: Calls `check_delay(includeRunningJobs=True)`:
   - Queries `SELECT consistent_before_hard FROM dwh_manage.table_limits WHERE content_group=... AND schema_name=... AND table_name=...`
   - Computes `lag = (utcnow - consistent_before_hard).total_seconds() / 3600`
   - If `lag < delay_threshold`: no breach
   - If `includeRunningJobs=True` and `check_running_instance()` returns `True` (active Megatron load): suppresses alert despite lag
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `edw` (MySQL `dwh_manage` + `megatron`)
   - Protocol: MySQL

4. **Trigger delay events**: For each breached table, constructs JSM alert payload with P3 priority, alias `"Megatron Lag: {service} - {table} - {load_type}"`, and `extraProperties` including `tl_check_query`, `last_updated`, and Grafana graph URL
   - From: `continuumPreTaskTracker` (integrationHooks)
   - To: `continuumJiraService` (JSM API)
   - Protocol: HTTPS REST

### Resolve flow (pre_resolve_megatron_lag)

5. **List open lag incidents**: Fetches open JSM alerts with alias containing `"Megatron Lag"` prefix
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `continuumJiraService` (JSM API)

6. **Re-evaluate lag (without running job suppression)**: Calls `check_delay(includeRunningJobs=False)` — if lag is now within threshold regardless of whether a job is running, closes the alert
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `edw` (MySQL `dwh_manage`)
   - Protocol: MySQL

7. **Close resolved alerts**: Calls `close_jsm_alert()` for tables now within `delay_threshold`
   - From: `continuumPreTaskTracker` (integrationHooks)
   - To: `continuumJiraService` (JSM API)
   - Protocol: HTTPS REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `consistent_before_hard` is `None` | Logs the TL check query; `NoneType` comparison may raise `TypeError` | Task fails; next 15-minute cycle retries |
| Megatron `etl_process_status` connection failure | `AirflowNotFoundException` caught; falls back to direct DB connection | Degraded suppression; lag alerts may fire while job is running |
| JSM API error on alert creation | Exception raised and propagated | Alert not created; retried next cycle |
| Non-pipelines GCP project | Project ID check returns `None`; tasks skip | No monitoring in shared Composer |

## Sequence Diagram

```
Scheduler -> pre_check_megatron_lag: Trigger (*/15 8-23 * * *)
pre_check_megatron_lag -> dwh_manage MySQL: SELECT consistent_before_hard
dwh_manage MySQL --> pre_check_megatron_lag: timestamp
pre_check_megatron_lag -> megatron MySQL: SELECT etl_process_status (if lag > threshold)
megatron MySQL --> pre_check_megatron_lag: running instance flag
pre_check_megatron_lag -> JSM API: POST /alerts (P3, alias=Megatron Lag:...)
Scheduler -> pre_resolve_megatron_lag: Trigger (*/15 8-23 * * *)
pre_resolve_megatron_lag -> JSM API: GET open Megatron Lag alerts
JSM API --> pre_resolve_megatron_lag: open incident list
pre_resolve_megatron_lag -> dwh_manage MySQL: Re-check lag (no running job suppression)
pre_resolve_megatron_lag -> JSM API: POST /alerts/{id}/close
```

## Related

- Related flows: [Megatron EOD Delay Detection](megatron-eod-delay.md)
- Config: `orchestrator/config.yml` — all `delay_threshold` and `eod_time` values
