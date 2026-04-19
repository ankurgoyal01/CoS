---
service: "pre_task_tracker"
title: "Megatron EOD Delay Detection"
generated: "2026-03-03"
type: flow
flow_name: "megatron-eod-delay"
flow_type: scheduled
trigger: "Cron schedule */15 2-8 * * * on pre_check_megatron_eod and pre_resolve_megatron_eod DAGs"
participants:
  - "continuumPreTaskTracker"
  - "edw"
  - "continuumJiraService"
architecture_ref: "dynamic-pre-task-tracker-sla-update-flow"
---

# Megatron EOD Delay Detection

## Summary

Two paired Airflow DAGs — `pre_check_megatron_eod` and `pre_resolve_megatron_eod` — monitor Megatron data pipeline tables for end-of-day (EOD) SLA breaches. Every 15 minutes between 02:00 and 08:00 UTC, the check DAG evaluates whether each monitored table has been loaded (by querying `consistent_before_hard` from the `dwh_manage.table_limits` MySQL database). Tables that missed their configured `eod_time` deadline receive a P3 JSM alert. The resolve DAG runs on the same schedule and automatically closes alerts for tables that have since caught up.

## Trigger

- **Type**: schedule
- **Source**: Airflow cron schedule `*/15 2-8 * * *` on DAGs `pre_check_megatron_eod` and `pre_resolve_megatron_eod`
- **Frequency**: Every 15 minutes between 02:00–08:00 UTC daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| pre_check_megatron_eod DAG | Evaluates EOD breach conditions and fires JSM alerts | `continuumPreTaskTracker` |
| pre_resolve_megatron_eod DAG | Closes JSM alerts for tables that have recovered | `continuumPreTaskTracker` |
| DWH Manage MySQL (`dwh_manage` conn) | Provides `consistent_before_hard` data freshness timestamps | `edw` |
| Atlassian JSM | Receives P3 alert create and close HTTP calls | `continuumJiraService` |

## Steps

### Check flow (pre_check_megatron_eod)

1. **Validate project ID**: Checks `GCP_PROJECT` env var against allowed PIPELINES project IDs (`prj-grp-pipelines-dev-7536`, `prj-grp-pipelines-stable-19fd`, `prj-grp-pipelines-prod-bb85`); returns `None` if not a pipelines project (causes downstream tasks to skip)
   - From: `continuumPreTaskTracker` (dagDefinitions)
   - To: Cloud Composer environment
   - Protocol: direct

2. **Load YAML config**: Opens `orchestrator/config.yml` and parses all content groups, table names, load types, and monitoring parameters into a dictionary
   - From: `continuumPreTaskTracker` (dagDefinitions)
   - To: local filesystem (GCS-mounted DAG folder)
   - Protocol: direct

3. **Evaluate EOD delays**: For each entry in the config, constructs a `MegatronTableLoad` object and calls `eod_breach()`:
   - If current UTC time is past `eod_time` AND `consistent_before_hard` (from MySQL) is before midnight today → EOD breach detected; table added to `delayed_tables` list
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `edw` (`dwh_manage.table_limits` via `MySqlHook(mysql_conn_id="dwh_manage")`)
   - Protocol: MySQL

4. **Trigger delay events**: For each breached table, constructs JSM payload with `message`, `alias` (deduplicated by summary string `"Megatron EOD: {service} - {table} - {load_type}"`), `priority=P3`, `extraProperties` including `tl_check_query`, `last_updated`, and Megatron graph URL; POSTs to JSM
   - From: `continuumPreTaskTracker` (integrationHooks)
   - To: `continuumJiraService` (JSM API)
   - Protocol: HTTPS REST (via `megatron_helper.create_jsm_alert()`)

### Resolve flow (pre_resolve_megatron_eod)

5. **List open EOD incidents**: Authenticates with JSM and fetches all open alerts with alias matching `"Megatron EOD:"` prefix
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `continuumJiraService` (JSM API)
   - Protocol: HTTPS REST

6. **Re-evaluate breach status**: For each open incident, parses `service_name`, `table_name`, `load_type` from the alias; loads the matching config entry; calls `eod_breach()` again
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `edw` (MySQL `dwh_manage`)
   - Protocol: MySQL

7. **Close resolved alerts**: If `eod_breach()` returns `False`, calls `megatron_helper.close_jsm_alert()` to resolve the JSM alert
   - From: `continuumPreTaskTracker` (integrationHooks)
   - To: `continuumJiraService` (JSM API)
   - Protocol: HTTPS REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Non-pipelines GCP project (shared Composer) | `check_project_id` returns `None`; downstream tasks return early | No alerts fired; safe skip |
| MySQL `dwh_manage` connection failure | Exception raised from `MySqlHook`; task fails | Task marked failed; Airflow callbacks may fire |
| `consistent_before_hard` is `None` (table never loaded) | `check_delay()` logs the missing data query; comparison proceeds | May result in false delay flag; logged for investigation |
| JSM API returns error | Exception raised by HTTP call | Alert is not created; next cycle retries |
| Incident alias does not start with `"Megatron EOD:"` | `continue` in resolve loop | Non-EOD incidents are safely skipped |

## Sequence Diagram

```
Scheduler -> pre_check_megatron_eod: Trigger (*/15 2-8 * * *)
pre_check_megatron_eod -> GCPEnv: Check GCP_PROJECT
pre_check_megatron_eod -> config.yml: Load monitoring config
pre_check_megatron_eod -> dwh_manage MySQL: SELECT consistent_before_hard (per table)
dwh_manage MySQL --> pre_check_megatron_eod: freshness timestamp
pre_check_megatron_eod -> pre_check_megatron_eod: eod_breach() check
pre_check_megatron_eod -> JSM API: POST /alerts (P3, alias=Megatron EOD:...)
Scheduler -> pre_resolve_megatron_eod: Trigger (*/15 2-8 * * *)
pre_resolve_megatron_eod -> JSM API: GET open alerts (Megatron EOD prefix)
JSM API --> pre_resolve_megatron_eod: open incident list
pre_resolve_megatron_eod -> dwh_manage MySQL: Re-check consistent_before_hard
pre_resolve_megatron_eod -> JSM API: POST /alerts/{id}/close (if not breached)
```

## Related

- Architecture dynamic view: `dynamic-pre-task-tracker-sla-update-flow`
- Related flows: [Megatron Lag Monitoring](megatron-lag-monitoring.md), [Airflow Task Failure Detection and Alerting](airflow-task-failure-alerting.md)
- Config: `orchestrator/config.yml` defines all monitored tables, `eod_time`, and `delay_threshold` values
