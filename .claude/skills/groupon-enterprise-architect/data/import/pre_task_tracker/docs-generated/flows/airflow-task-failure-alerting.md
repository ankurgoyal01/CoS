---
service: "pre_task_tracker"
title: "Airflow Task Failure Detection and Alerting"
generated: "2026-03-03"
type: flow
flow_name: "airflow-task-failure-alerting"
flow_type: scheduled
trigger: "Airflow @continuous schedule on PRE_TASK_TRACKER3 DAG"
participants:
  - "continuumPreTaskTracker"
  - "continuumPreTaskTrackerAirflowDb"
  - "continuumPreTaskTrackerMysqlDb"
  - "continuumJiraService"
architecture_ref: "dynamic-pre-task-tracker-sla-update-flow"
---

# Airflow Task Failure Detection and Alerting

## Summary

The `PRE_TASK_TRACKER3` DAG runs continuously (`@continuous`, `max_active_runs=1`) and acts as the primary operational safety net for Groupon's data engineering pipelines. It scans the Airflow metadata PostgreSQL database for tasks and DAGs in anomalous states across three monitored organizations and fires Jira Service Management (JSM) alerts for failures, long-running tasks, queued stalls, and skip sequences. It then resolves alerts when the underlying conditions clear.

## Trigger

- **Type**: schedule
- **Source**: Airflow scheduler via `@continuous` interval on DAG `PRE_TASK_TRACKER3`
- **Frequency**: Continuous (runs a new cycle immediately after the previous completes)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| PRE_TASK_TRACKER3 DAG (DAG Definitions + Monitoring Logic) | Orchestrates and executes all monitoring checks | `continuumPreTaskTracker` |
| Airflow Metadata Database | Source of task instance states, DAG run states, and DAG file locations | `continuumPreTaskTrackerAirflowDb` |
| PRE Monitoring Database (`vw_conn_id`) | Referenced for task processing (connection verification) | `continuumPreTaskTrackerMysqlDb` |
| Atlassian JSM | Receives alert create/resolve HTTP calls | `continuumJiraService` |
| Jira (`GPROD` project) | Queried for open `Logbook` issues to resolve non-critical and skip-sequence tickets | `continuumJiraService` |

## Steps

1. **Check failed tasks**: Queries `task_instance` joined to `dag_run` and `dag` for tasks in `failed` state where `dag.fileloc` matches one of the monitored org patterns (`dnd-gcp-migration-data-eng`, `dnd-bia-data-engg`, `consumer-data-engineering`)
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `continuumPreTaskTrackerAirflowDb`
   - Protocol: PostgreSQL

2. **Fire failed task alerts**: For each failed task whose DAG run is not already `success`, calls `trigger_event()` with `issue_type=FAILED`; this posts an HTTP request to JSM creating or deduplicating the alert
   - From: `continuumPreTaskTracker` (integrationHooks)
   - To: `continuumJiraService` (JSM API)
   - Protocol: HTTPS REST

3. **Check running tasks (long-running detection)**: Queries `task_instance` in `running` state per org; re-validates current state; computes `run_time` vs. `sla_time` from `get_sla_info()` (or `CLUSTER_MODIFY_SLA` for cluster tasks)
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `continuumPreTaskTrackerAirflowDb`
   - Protocol: PostgreSQL

4. **Fire long-running task alerts**: For tasks exceeding SLA, calls `trigger_event()` with `issue_type=LONGRUNNING`
   - From: `continuumPreTaskTracker` (integrationHooks)
   - To: `continuumJiraService` (JSM API)
   - Protocol: HTTPS REST

5. **Check skipped tasks (skip sequence detection)**: Executes a windowed SQL query using `LAG()` over the last 5 DAG runs per DAG per org; identifies DAGs where all five consecutive runs had all-but-two tasks skipped
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `continuumPreTaskTrackerAirflowDb`
   - Protocol: PostgreSQL

6. **Fire skip sequence alerts**: For each skip-sequence DAG, calls `trigger_event()` with `issue_type=SKIP_SEQUENCE` and full context object
   - From: `continuumPreTaskTracker` (integrationHooks)
   - To: `continuumJiraService` (JSM API)
   - Protocol: HTTPS REST

7. **Check queued DAGs**: Queries `DagRun` records in `QUEUED` state with `start_date = None` and `queued_at` older than `queue_threshold` minutes (Airflow Variable, default 3)
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `continuumPreTaskTrackerAirflowDb`
   - Protocol: SQLAlchemy session

8. **Check queued tasks**: Queries `TaskInstance` records in `QUEUED` state with `queued_dttm` older than `queue_threshold` minutes
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `continuumPreTaskTrackerAirflowDb`
   - Protocol: SQLAlchemy session

9. **Fire queued alerts**: Calls `trigger_event()` with `issue_type=QUEUED` for each stalled DAG or task
   - From: `continuumPreTaskTracker` (integrationHooks)
   - To: `continuumJiraService` (JSM API)
   - Protocol: HTTPS REST

10. **Resolve critical events**: Fetches all open JSM alerts from `preutils.jsm_handler`; for each alert, re-checks task and DAG run state; resolves alerts where the task is now `success` or `skipped` or the DAG run reached `success`
    - From: `continuumPreTaskTracker` (monitoringLogic)
    - To: `continuumPreTaskTrackerAirflowDb` (re-check) and `continuumJiraService` (resolve)
    - Protocol: PostgreSQL + HTTPS REST

11. **Resolve non-critical events**: Fetches open `Logbook` Jira tickets in `GPROD` (look-back 7 days); for each ticket, parses `DAG ID`, `TASK ID`, `RUN ID` from description; resolves tickets where DAG run succeeded or task reached terminal state
    - From: `continuumPreTaskTracker` (monitoringLogic)
    - To: `continuumJiraService` (Jira SDK + JSM resolve)
    - Protocol: HTTPS REST (JIRA SDK)

12. **Resolve skip sequences**: Fetches open skip-sequence Jira tickets (look-back 70 days); rebuilds the current set of skip-sequence DAGs; resolves tickets for DAGs no longer in a skip sequence
    - From: `continuumPreTaskTracker` (monitoringLogic)
    - To: `continuumPreTaskTrackerAirflowDb` + `continuumJiraService`
    - Protocol: PostgreSQL + HTTPS REST

13. **Send heartbeat**: POSTs to `https://api.atlassian.com/jsm/ops/api/{cloudId}/v1/teams/{teamId}/heartbeats/ping` with integration name; confirms monitoring system liveness
    - From: `continuumPreTaskTracker` (integrationHooks)
    - To: `continuumJiraService` (JSM Heartbeat API)
    - Protocol: HTTPS REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Task no longer in `running` state at time of long-running check | Re-validates state before firing alert; skips if changed | No false alert |
| DAG run already in `success` before failed-task alert fires | Checks `dag_run_status` before calling `trigger_event`; logs warning and skips | No duplicate alert |
| JSM description has unexpected field count | Logs warning and skips that alert in resolution cycle | Alert remains open until next cycle with valid data |
| Task details not found in DB (record deleted/archived) | `continue` on empty result | Alert is not resolved; remains open |
| `send_heartbeat` exception | Exception raised and logged; task fails | JSM heartbeat integration fires "missing" notification |

## Sequence Diagram

```
Scheduler -> PRE_TASK_TRACKER3: Trigger new DAG run (@continuous)
PRE_TASK_TRACKER3 -> AirflowDB: SELECT failed tasks (by org)
AirflowDB --> PRE_TASK_TRACKER3: failed task list
PRE_TASK_TRACKER3 -> JSM API: POST /alerts (trigger FAILED alert)
JSM API --> PRE_TASK_TRACKER3: 200 OK
PRE_TASK_TRACKER3 -> AirflowDB: SELECT running tasks (by org)
AirflowDB --> PRE_TASK_TRACKER3: running task list
PRE_TASK_TRACKER3 -> AirflowDB: Re-check task state
PRE_TASK_TRACKER3 -> JSM API: POST /alerts (trigger LONGRUNNING if SLA breached)
PRE_TASK_TRACKER3 -> AirflowDB: SELECT skip-sequence DAGs (windowed query)
PRE_TASK_TRACKER3 -> JSM API: POST /alerts (trigger SKIP_SEQUENCE)
PRE_TASK_TRACKER3 -> AirflowDB: SELECT queued DAGs/tasks
PRE_TASK_TRACKER3 -> JSM API: POST /alerts (trigger QUEUED)
PRE_TASK_TRACKER3 -> JSM API: GET open alerts (critical)
JSM API --> PRE_TASK_TRACKER3: open alert list
PRE_TASK_TRACKER3 -> AirflowDB: Re-check task/run state
PRE_TASK_TRACKER3 -> JSM API: POST /alerts/{id}/resolve
PRE_TASK_TRACKER3 -> Jira SDK: Search open Logbook tickets
Jira SDK --> PRE_TASK_TRACKER3: open ticket list
PRE_TASK_TRACKER3 -> AirflowDB: Re-check task state
PRE_TASK_TRACKER3 -> JSM API: POST resolve non-critical
PRE_TASK_TRACKER3 -> JSM API: POST /heartbeats/ping
```

## Related

- Architecture dynamic view: `dynamic-pre-task-tracker-sla-update-flow`
- Related flows: [SLA Entry Update](sla-entry-update.md), [Megatron EOD Delay Detection](megatron-eod-delay.md)
