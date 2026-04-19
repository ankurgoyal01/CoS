---
service: "JLA_Airflow"
title: "JLA ETL Pipeline (Daily Data Mart Load)"
generated: "2026-03-03"
type: flow
flow_name: "jla-etl-pipeline"
flow_type: scheduled
trigger: "Airflow cron schedule controlled by `etl_schedule` Variable (default: `30 9 * * *`)"
participants:
  - "continuumJlaAirflowOrchestrator"
  - "continuumJlaAirflowMetadataDb"
  - "teradata-dwh_fsa_prd"
  - "bigQueryWarehouse"
architecture_ref: "dynamic-continuumJlaAirflow"
---

# JLA ETL Pipeline (Daily Data Mart Load)

## Summary

The JLA ETL pipeline is an eight-step sequential DAG chain that performs the daily load of the JLA accounting data mart. Each step completes and then uses `TriggerDagRunOperator` to chain to the next step, passing a shared `process_id` UUID and run-type context flags through the `conf` payload. The pipeline begins at step 1 (startup) and ends at step 8.1, which publishes the final dataset to BigQuery if the run was scheduled (or forced via `manual-run-update-dataset`).

## Trigger

- **Type**: schedule
- **Source**: Airflow cron expression stored in `etl_schedule` Airflow Variable (default `"30 9 * * *"` — 9:30 UTC daily)
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Execution Engine | Schedules and chains all 8 ETL steps | `continuumJlaAirflowOrchestrator` |
| Data Warehouse Connector | Executes all SQL tasks against Teradata | `continuumJlaAirflowOrchestrator` |
| Airflow Metadata Store | Stores XCom values (process UUID, run context) and DAG run state | `continuumJlaAirflowMetadataDb` |
| Teradata (`dwh_fsa_prd`) | Source and target data warehouse | `unknown_teradata_platform` (stub) |
| BigQuery | Final analytics dataset destination | `bigQueryWarehouse` |

## Steps

1. **Step 1 — Startup (`jla-mart-etl-1-startup`)**: Generates a UUID `process_id`, stores it in `acct_jla_proc_id_parm_tmp`, and loads the run process record into `acct_jla_run_process`. Logs the run context (`origin_run_type`, manual flags).
   - From: `continuumJlaAirflowOrchestrator` (Airflow scheduler)
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

2. **Step 1 chains to Step 2** via `TriggerDagRunOperator`, propagating `process_id`, `origin_run_type`, `origin_dag_id`, `origin_run_id`, `manual-run-NO-update-dataset`, and `manual-run-update-dataset` in the `conf` payload.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `continuumJlaAirflowOrchestrator` (triggers `jla-mart-etl-2-lookups`)
   - Protocol: Airflow TriggerDagRunOperator

3. **Step 2 — Lookups (`jla-mart-etl-2-lookups`)**: Builds all lookup tables used throughout the pipeline — including audit, campaign details, CM, last-minute, market rate, opportunity, order discount, order item adjustment events, order item pricing, order shipping, payment terms, shipping, Switchfly, and tax lookups. Chains to step 3.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

4. **Step 3 — Extract Transactions (`jla-mart-etl-3-extract`)**: Extracts initial base transaction tables including order IDs, CTX records, OPT records, and orders. Creates initial base tables for the JLA data mart. Chains to step 4.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

5. **Steps 4–7**: Continue transforming and enriching transaction data (transform, attribute enrichment, financial calculations, reconciliation). Each step chains to the next via `TriggerDagRunOperator`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

6. **Step 8 — Final Transform (`jla-mart-etl-8-*`)**: Applies final transformations and prepares the JLA data mart for publication. Chains to step 8.1.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

7. **Step 8.1 — Dataset Publication (`jla-mart-etl-8.1-*`)**: Evaluates `origin_run_type`; if `scheduled` or `forced-scheduled`, publishes the JLA dataset to BigQuery. If `manual` (and `manual-run-NO-update-dataset` is set), skips publication.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `bigQueryWarehouse`
   - Protocol: SQL (BigQuery SQLAlchemy)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Any task failure | `on_failure_callback` fires `ErrorUtils.failure_callback` | Google Chat `ENGINEERING_ALERTS` alert sent; DAG chain stops |
| `process_id` UUID not generated | `BranchPythonOperator` routes to failure path; raises `AirflowFailException` | Step 1 DAG fails; chain does not proceed |
| Manual run without publish flag | `origin_run_type` set to `manual`; step 8.1 skips BigQuery publication | Data mart is updated; BigQuery dataset is not refreshed |
| Manual run with force-publish flag | `origin_run_type` overridden to `forced-scheduled` | Full pipeline runs including BigQuery publication |

## Sequence Diagram

```
Scheduler -> jla-mart-etl-1-startup: trigger (cron schedule)
jla-mart-etl-1-startup -> teradata (dwh_fsa_prd): generate UUID, insert acct_jla_run_process
jla-mart-etl-1-startup -> jla-mart-etl-2-lookups: TriggerDagRunOperator (with conf: process_id, origin_run_type, flags)
jla-mart-etl-2-lookups -> teradata (dwh_fsa_prd): build lookup tables
jla-mart-etl-2-lookups -> jla-mart-etl-3-extract: TriggerDagRunOperator
jla-mart-etl-3-extract -> teradata (dwh_fsa_prd): extract base transaction tables
jla-mart-etl-3-extract -> jla-mart-etl-4: TriggerDagRunOperator
... (steps 4–8 repeat the pattern)
jla-mart-etl-8 -> jla-mart-etl-8.1: TriggerDagRunOperator
jla-mart-etl-8.1 -> bigQueryWarehouse: publish dataset (if origin_run_type = scheduled)
```

## Related

- Architecture dynamic view: `dynamic-continuumJlaAirflow`
- Related flows: [Ads Billing and Invoicing Pipeline](ads-billing-invoicing.md), [EBA Rules Execution](eba-rules-execution.md)
