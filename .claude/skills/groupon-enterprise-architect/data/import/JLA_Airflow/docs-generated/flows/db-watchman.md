---
service: "JLA_Airflow"
title: "DB Watchman — Database Monitoring"
generated: "2026-03-03"
type: flow
flow_name: "db-watchman"
flow_type: scheduled
trigger: "Daily cron at 01:15 UTC (`15 1 * * *`)"
participants:
  - "continuumJlaAirflowOrchestrator"
  - "continuumJlaAirflowMetadataDb"
  - "teradata-dwh_fsa_prd"
  - "googleChat"
architecture_ref: "dynamic-continuumJlaAirflow"
---

# DB Watchman — Database Monitoring

## Summary

The DB Watchman DAG (`db-watchman`) runs nightly to monitor FSA's Teradata database objects, roles, metadata, and statistics. It harvests database object metadata using SCD (Slowly Changing Dimension) type-1 and type-2 patterns to maintain a historicized inventory of objects, their DDL (via SHOW statements), index definitions, optimizer statistics, and usage history. Role and access right assignments are also tracked with SCD-2 logic. After harvesting, the DAG evaluates a configurable list of alert queries and sends Google Chat notifications for any checks that fire.

## Trigger

- **Type**: schedule
- **Source**: Airflow cron `"15 1 * * *"` (01:15 UTC daily)
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Execution Engine | Schedules and runs the Watchman DAG | `continuumJlaAirflowOrchestrator` |
| Data Warehouse Connector | Executes all metadata queries against Teradata | `continuumJlaAirflowOrchestrator` |
| Airflow Metadata Store | Stores process UUID | `continuumJlaAirflowMetadataDb` |
| Teradata (`dwh_fsa_prd`, `dwh_fsa_prd_view`) | Source database and target for all Watchman metadata tables | `unknown_teradata_platform` (stub) |
| Google Chat | Receives configurable Watchman alerts | `googleChat` |

## Steps

1. **Start DAG**: Marks DAG start with `dag_start` empty operator.
   - From: Airflow scheduler (01:15 UTC)

2. **Generate process UUID**: Creates a UUID `process_id` and pushes to XCom.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `continuumJlaAirflowMetadataDb` (XCom)
   - Protocol: Airflow XCom

3. **Create process log**: Inserts run record via `ProcessLog.create()` into `acct_jla_run_process`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

4. **Retrieve object metadata**: Queries `DBC.Tables` and related system views to enumerate all objects in the monitored databases (`watchman_object_database_list`). Applies SCD-1/2 logic: new and changed objects are inserted into `meta_db_watchman_object`; changed objects receive an SCD-2 update (closing the previous valid record). Statistics are collected after insert.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL + pandas DataFrame insert

5. **Retrieve object DDL (SHOW)**: For all objects that changed since the last run, executes `SHOW {object_kind} {db}.{name}` statements and stores the output in chunks (max 3000 bytes per row) in `meta_db_watchman_object_show`. SCD-2 logic closes previous DDL records.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL + pandas DataFrame insert

6. **Retrieve object indexes**: Queries index metadata for monitored objects. Applies SCD-1/2 logic and stores results in `meta_db_watchman_object_index`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL + pandas DataFrame insert

7. **Retrieve object stats**: Queries optimizer statistics metadata. Applies SCD-1/2 logic and stores results in `meta_db_watchman_object_stats`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL + pandas DataFrame insert

8. **Retrieve object usage**: Fetches the last N days (controlled by `object_usage_days_to_fetch` parameter, default `3`) of object access history and fills gaps in `meta_db_watchman_object_usage`. This table is always one day behind.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

9. **Retrieve roles**: Queries database role and access right assignments for all users. Applies SCD-1/2 logic and stores results in `meta_db_watchman_roles`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL + pandas DataFrame insert

10. **Alerting**: Iterates over `watchman_alert_list` (defined in `db_watchman_alerts.py`). For each alert query returning `alert_flag = 1`, sends a WARNING card to the `ENGINEERING_ALERTS` Google Chat space and inserts the alert record into `meta_db_watchman_alerts`.
    - From: `continuumJlaAirflowOrchestrator`
    - To: `teradata-dwh_fsa_prd` (read + write), `googleChat` (webhook)
    - Protocol: JDBC/SQL, HTTPS Webhook

11. **Update process log**: Marks process as successful via `ProcessLog.success()`.
    - From: `continuumJlaAirflowOrchestrator`
    - To: `teradata-dwh_fsa_prd`
    - Protocol: JDBC/SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No objects changed (impossible state) | Raises `AirflowFailException` in production; prints warning in dev/uat | Alerts on impossible DB state |
| Any task exception | `AirflowFailException` raised with error details | `on_failure_callback` sends Google Chat `ENGINEERING_ALERTS` alert |
| Alert query fires (`alert_flag = 1`) | Sends WARNING alert to Google Chat; inserts to `meta_db_watchman_alerts` | DAG continues; not a DAG failure |

## Sequence Diagram

```
Scheduler -> db-watchman: trigger (15 1 * * * daily)
db-watchman -> teradata (dwh_fsa_prd): query DBC objects -> meta_db_watchman_object (SCD)
db-watchman -> teradata (dwh_fsa_prd): SHOW statements -> meta_db_watchman_object_show (SCD)
db-watchman -> teradata (dwh_fsa_prd): index metadata -> meta_db_watchman_object_index (SCD)
db-watchman -> teradata (dwh_fsa_prd): stats metadata -> meta_db_watchman_object_stats (SCD)
db-watchman -> teradata (dwh_fsa_prd): usage history -> meta_db_watchman_object_usage
db-watchman -> teradata (dwh_fsa_prd): role metadata -> meta_db_watchman_roles (SCD)
db-watchman -> teradata (dwh_fsa_prd): alerting queries
db-watchman -> googleChat (ENGINEERING_ALERTS): alert cards (if alert_flag = 1)
```

## Related

- Architecture dynamic view: `dynamic-continuumJlaAirflow`
- Related flows: [DB Gatekeeper — Governed SQL Execution](db-gatekeeper.md)
- Jira: FINS-737
