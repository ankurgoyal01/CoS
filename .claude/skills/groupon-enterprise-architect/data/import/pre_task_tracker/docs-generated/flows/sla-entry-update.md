---
service: "pre_task_tracker"
title: "SLA Entry Update"
generated: "2026-03-03"
type: flow
flow_name: "sla-entry-update"
flow_type: scheduled
trigger: "Cron schedule */3 * * * * on PRE-CKOD-EDW-SLA-UPDATER / PRE-CKOD-RM-SLA-UPDATER DAGs"
participants:
  - "continuumPreTaskTracker"
  - "continuumPreTaskTrackerAirflowDb"
  - "continuumPreTaskTrackerMysqlDb"
architecture_ref: "dynamic-pre-task-tracker-sla-update-flow"
---

# SLA Entry Update

## Summary

The `PRE-CKOD-EDW-SLA-UPDATER` and `PRE-CKOD-RM-SLA-UPDATER` DAGs run every 3 minutes and maintain real-time SLA tracking records in the CKOD MySQL database. They read SLA definitions from the database, correlate them with actual Airflow DAG run outcomes from the Airflow metadata PostgreSQL database, and write computed SLA status (on-time, late, missed, running) and delay times back to the `EDW_SLA_JOB_DETAIL` or `RM_SLA_JOB_DETAIL` tables. These records power the EDW/RM SLA dashboards.

## Trigger

- **Type**: schedule
- **Source**: Airflow cron `*/3 * * * *` on `PRE-CKOD-EDW-SLA-UPDATER` (PIPELINES Composer) and `PRE-CKOD-RM-SLA-UPDATER` (CONSUMER Composer)
- **Frequency**: Every 3 minutes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SLA Updater DAG (DAG Definitions + SLA Updater component) | Orchestrates SLA entry creation and status refresh | `continuumPreTaskTracker` |
| Airflow Metadata Database (PostgreSQL) | Source of `dag_run` state and timing for monitored jobs | `continuumPreTaskTrackerAirflowDb` |
| CKOD MySQL Database (`ckod_conn_rw`) | Read SLA definitions; write job detail entries and status | `continuumPreTaskTrackerMysqlDb` |

## Steps

### Run Initiator (first active run of the day)

1. **Create daily SLA entries**: On the first active run for today (detected when `dag_run.execution_date == dag.get_active_runs()[0]`), calls `create_edw_sla_entries()`:
   - Fetches all `SLA_DEFINITION` records from CKOD database
   - For each definition with `SLA_UTC` schedules, generates `EDW_SLA_JOB_DETAIL` placeholder rows for the day with `status=NOT_STARTED`
   - Skips definitions that already have entries for the run date
   - From: `continuumPreTaskTracker` (slaUpdater)
   - To: `continuumPreTaskTrackerMysqlDb` (CKOD MySQL, `EDW_SLA_DEFINITION`, `EDW_SLA_JOB_DETAIL`)
   - Protocol: MySQL

### Dashboard Refresh (every 3 minutes)

2. **Fetch incomplete SLA entries**: Calls `fetch_all_qualified_incomplete_edw_sla_entries()` with today's date to retrieve all `EDW_SLA_JOB_DETAIL` rows not yet in a terminal state for the current day
   - From: `continuumPreTaskTracker` (slaUpdater / integrationHooks)
   - To: `continuumPreTaskTrackerMysqlDb` (CKOD MySQL)
   - Protocol: MySQL

3. **Query DAG run history for each job**: For each incomplete SLA entry, queries Airflow PostgreSQL `dag_run` for all runs of that DAG (`JOB_NAME`) within today's run window (`start_date >= run_datetime AND start_date <= end_datetime`), ordered by `end_date` ascending
   - From: `continuumPreTaskTracker` (slaUpdater)
   - To: `continuumPreTaskTrackerAirflowDb` (PostgreSQL, `dag_run`)
   - Protocol: PostgreSQL / SQLAlchemy

4. **Evaluate SLA status**: Calls `eval_sla(actual_time, sla_utc, state)`:
   - **No DAG runs found**: If current time is past SLA and delay > 1 hour, updates entry with `MISSING` status and delay
   - **DAG run in `success` or final `failed` state**: Computes `sla_status` and `delay_time` from actual end time vs. `SLA_UTC`; updates entry with terminal status
   - **DAG run currently `running`**: Computes current delay against `SLA_UTC`; updates entry with `running` status
   - **Earlier failed run with later retry**: Skips non-last failed runs; waits for the final run outcome
   - From: `continuumPreTaskTracker` (slaUpdater)

5. **Write SLA status back to CKOD**: Calls the appropriate CKOD update method based on state:
   - `update_edw_sla_entries_missing_status()` — no runs, delayed
   - `update_edw_sla_entries_running_status()` — DAG currently running
   - `update_edw_sla_entries_end_status()` — DAG completed (success or failed)
   - From: `continuumPreTaskTracker` (slaUpdater / integrationHooks)
   - To: `continuumPreTaskTrackerMysqlDb` (CKOD MySQL, `EDW_SLA_JOB_DETAIL`)
   - Protocol: MySQL

### Manual Backfill Mode

The DAG supports manual backfill via `dag_run_conf`:
- `RUN_RANGE=true` with `SLA_BOARD_ENTRY_UPDATE_RUN_DATETIME` and `SLA_BOARD_ENTRY_UPDATE_END_DATETIME`: iterates day by day and creates/refreshes entries across the range
- `SPECIFIC_JOBS=["JOB_1", "JOB_2"]`: restricts processing to named jobs
- `RUN_INITIATOR=true`: forces re-creation of SLA entries before the refresh

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `ckod_conn_rw` MySQL connection failure | Exception raised; DAG on-failure callback fires `trigger_event` to JSM | SLA entries not updated; alert fires to PRE team |
| DAG has no runs for today | `Missing` status computed if current time exceeds SLA by > 1 hour | Entry marked `MISSING` in dashboard |
| Multiple failed runs with final retry running | Iterates runs in order; skips non-last failed; processes running or final run | Correct final state is captured |
| `SLA_UTC` is a pipe-delimited schedule list | `get_run_schedules()` splits and generates one entry per schedule | Multiple SLA windows are handled correctly |

## Sequence Diagram

```
Scheduler -> PRE-CKOD-EDW-SLA-UPDATER: Trigger (*/3 * * * *)
PRE-CKOD-EDW-SLA-UPDATER -> CKOD MySQL: SELECT EDW_SLA_DEFINITION (run_initiator, once/day)
CKOD MySQL --> PRE-CKOD-EDW-SLA-UPDATER: SLA definitions
PRE-CKOD-EDW-SLA-UPDATER -> CKOD MySQL: INSERT EDW_SLA_JOB_DETAIL (placeholder rows)
PRE-CKOD-EDW-SLA-UPDATER -> CKOD MySQL: SELECT incomplete EDW_SLA_JOB_DETAIL (today)
CKOD MySQL --> PRE-CKOD-EDW-SLA-UPDATER: incomplete entries
PRE-CKOD-EDW-SLA-UPDATER -> Airflow PostgreSQL: SELECT dag_run (by JOB_NAME, today)
Airflow PostgreSQL --> PRE-CKOD-EDW-SLA-UPDATER: dag run records
PRE-CKOD-EDW-SLA-UPDATER -> PRE-CKOD-EDW-SLA-UPDATER: eval_sla(end_date, SLA_UTC, state)
PRE-CKOD-EDW-SLA-UPDATER -> CKOD MySQL: UPDATE EDW_SLA_JOB_DETAIL (status, delay_time)
```

## Related

- Architecture dynamic view: `dynamic-pre-task-tracker-sla-update-flow`
- Related flows: [Airflow Task Failure Detection and Alerting](airflow-task-failure-alerting.md)
- SLA Updater files: `orchestrator/sla_updater/pre-ckod-edw-sla-entries-updater.py`, `orchestrator/sla_updater/sla_entry_helper.py`
