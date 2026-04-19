---
service: "JLA_Airflow"
title: "EBA Rules Execution"
generated: "2026-03-03"
type: flow
flow_name: "eba-rules-execution"
flow_type: scheduled
trigger: "Airflow cron schedule controlled by `eba_schedule` Airflow Variable"
participants:
  - "continuumJlaAirflowOrchestrator"
  - "continuumJlaAirflowMetadataDb"
  - "teradata-dwh_fsa_prd"
  - "jla-eba-service"
  - "googleChat"
architecture_ref: "dynamic-continuumJlaAirflow"
---

# EBA Rules Execution

## Summary

The EBA Rules Execution DAG (`jla-eba-rules-exec`) triggers the JLA Event Based Accounting (EBA) service on a scheduled cadence to process all active accounting rules. The EBA service aggregates transaction data within the JLA data mart and stages journal entries for integration into NetSuite ERP. The DAG applies a configurable date offset (via `eba_offset_start` / `eba_offset_end` Airflow Variables) to compute the processing date range, optionally activates rulesets, calls the EBA service REST endpoint, then validates rule completeness and sends a summary to the JLA Google Chat space.

## Trigger

- **Type**: schedule
- **Source**: Airflow cron expression stored in `eba_schedule` Airflow Variable (required; no default)
- **Frequency**: Scheduled (frequency defined by `eba_schedule` Variable)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Execution Engine | Schedules and executes the EBA DAG | `continuumJlaAirflowOrchestrator` |
| Data Warehouse Connector | Executes offset, activation, and summary SQL against Teradata | `continuumJlaAirflowOrchestrator` |
| Airflow Metadata Store | Stores process UUID and XCom values | `continuumJlaAirflowMetadataDb` |
| Teradata (`dwh_fsa_prd`) | Reads `acct_jla_eba_rulesets`, `acct_jla_eba_options`; receives staged journal entries | `unknown_teradata_platform` (stub) |
| JLA EBA Service | Processes active rules, aggregates data, stages journal entries | Internal (connection: `http_jla_services_root`) |
| Google Chat | Receives EBA summary and missing-ruleset alerts | `googleChat` |

## Steps

1. **Start DAG**: Marks DAG start with `eba_rules_start` empty operator.
   - From: Airflow scheduler

2. **Generate process UUID**: Creates a UUID `process_id` and pushes to XCom along with `process_status` and `jdbc_conn_id`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `continuumJlaAirflowMetadataDb` (XCom)
   - Protocol: Airflow XCom

3. **Get load offset**: Computes `start_date` and `end_date` for EBA processing. If `dag_run.conf.start_date` is provided, uses the override; otherwise computes from `eba_offset_start`/`eba_offset_end` Airflow Variables relative to current UTC date. Pushes dates and `process_log_args` to XCom.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `continuumJlaAirflowMetadataDb` (XCom)
   - Protocol: Airflow XCom

4. **Create process log**: Inserts run record via `ProcessLog.create()` into `acct_jla_run_process`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

5. **Activate rulesets** (when `activate_rulesets = True`): Executes `activate_rulesets.sql` to enable all applicable EBA rulesets in `acct_jla_eba_rulesets` for the current run.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

6. **Call EBA service — Process Rules**: HTTP GET to the JLA EBA service endpoint:
   `Groupon.JLA.Services.EventBasedAccounting/EventBasedAccountingService.svc/ProcessRules/airflow/{start_date}/{end_date}/{process_id}`
   The EBA service executes all active rules, aggregates JLA mart data, and stages journal entries for NetSuite.
   - From: `continuumJlaAirflowOrchestrator`
   - To: JLA EBA service (`http_jla_services_root`)
   - Protocol: HTTP GET

7. **Status alert**: Executes summary queries (`get_summary.sql`, `active_ruleset_count.sql`, `get_missing_rules.sql`) against Teradata. If missing rulesets are detected, sends an error alert to `ENGINEERING_ALERTS`. On success, sends an EBA summary card to `JLA_ALERTS` Google Chat space including total journal entry value, rule count, and journal entry count.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd` (read), `googleChat` (webhook)
   - Protocol: JDBC/SQL, HTTPS Webhook

8. **End DAG**: Marks DAG completion with `eba_rules_end` empty operator.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| EBA service HTTP failure | `on_failure_callback` fires | Google Chat `ENGINEERING_ALERTS` alert; journal entries not staged |
| Missing rulesets detected | `status_alert` task sends ERROR template to `ENGINEERING_ALERTS` | Warning raised; DAG does not automatically fail from this check alone |
| Any other task failure | `on_failure_callback` fires | Google Chat `ENGINEERING_ALERTS` alert |
| Date override provided | Uses `dag_run.conf.start_date`/`end_date` | Override dates used instead of offset computation |

## Sequence Diagram

```
Scheduler -> jla-eba-rules-exec: trigger (eba_schedule cron)
jla-eba-rules-exec -> teradata (dwh_fsa_prd): get_offset.sql (determine date range)
jla-eba-rules-exec -> teradata (dwh_fsa_prd): activate_rulesets.sql (enable rulesets)
jla-eba-rules-exec -> JLA EBA Service: HTTP GET ProcessRules/{start_date}/{end_date}/{process_id}
JLA EBA Service -> teradata (dwh_fsa_prd): aggregate JLA data, stage journal entries
JLA EBA Service --> jla-eba-rules-exec: HTTP 200 (completion)
jla-eba-rules-exec -> teradata (dwh_fsa_prd): get_summary.sql, get_missing_rules.sql
jla-eba-rules-exec -> googleChat (JLA_ALERTS): EBA summary (on success)
jla-eba-rules-exec -> googleChat (ENGINEERING_ALERTS): missing rulesets alert (if applicable)
```

## Related

- Architecture dynamic view: `dynamic-continuumJlaAirflow`
- Related flows: [JLA ETL Pipeline](jla-etl-pipeline.md)
- Confluence: https://confluence.groupondev.com/x/F7bXE
