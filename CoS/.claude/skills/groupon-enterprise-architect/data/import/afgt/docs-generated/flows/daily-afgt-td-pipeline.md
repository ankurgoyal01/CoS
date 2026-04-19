---
service: "afgt"
title: "Daily AFGT TD Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "daily-afgt-td-pipeline"
flow_type: scheduled
trigger: "Daily Airflow cron schedule at 30 6 * * * UTC"
participants:
  - "continuumAfgtAirflowDag"
  - "continuumAfgtDataprocBatch"
  - "continuumAfgtHiveDataset"
  - "edw"
  - "optimusPrime"
  - "googleChat"
architecture_ref: "dynamic-afgt_td_to_hive_load"
---

# Daily AFGT TD Pipeline

## Summary

The daily AFGT TD pipeline (`afgt_sb_td`) is the primary orchestration flow that runs every day at 06:30 UTC via Apache Airflow (Cloud Composer). It validates upstream data readiness, provisions an ephemeral Dataproc cluster, executes a sequential series of Teradata BTEQ staging jobs to enrich global financial transaction data, then extracts the result via Sqoop into the IMA Hive data lake, and finally triggers downstream pipelines and sends completion notifications.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow scheduler; DAG ID `afgt_sb_td`; cron expression `30 6 * * *` UTC
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AFGT TD Airflow DAG | Orchestrator — controls task sequence, prechecks, cluster lifecycle, notifications | `continuumAfgtAirflowDag` |
| AFGT Dataproc Batch Jobs | Compute — executes all Shell/Pig/Hive/Sqoop jobs on ephemeral cluster | `continuumAfgtDataprocBatch` |
| AFGT Hive Dataset | Destination — stores staging and final analytics tables | `continuumAfgtHiveDataset` |
| Teradata EDW | Source — provides all transaction, dimension, and enrichment data | `edw` |
| Optimus Prime | Validation — triggered after staging stages complete | `optimusPrime` |
| Google Chat | Notification — receives completion and failure alerts | `googleChat` |

## Steps

1. **DAG run starts**: Airflow scheduler triggers `afgt_sb_td` at 06:30 UTC.
   - From: `continuumAfgtAirflowDag` (scheduler)
   - To: `continuumAfgtAirflowDag` (task graph)
   - Protocol: Airflow internal

2. **Upstream precheck**: `start` task runs `CheckRunsLegacy.calculate_varPartitionId`; in parallel, `ogp_check` and `go_segment_check` PythonSensor tasks poll until `DLY_OGP_FINANCIAL_varRUNDATE_0003` and `go_segmentation` DAGs have completed for the current date.
   - From: `continuumAfgtAirflowDag`
   - To: Airflow internal state / upstream DAG status
   - Protocol: PythonSensor polling

3. **Precheck confirmation email**: `ogp_check_email` EmailOperator sends confirmation to `rev_mgmt_analytics@groupon.com` that prechecks passed.
   - From: `continuumAfgtAirflowDag`
   - To: email recipients
   - Protocol: SMTP

4. **Provision Dataproc cluster**: `create_cluster` task creates ephemeral cluster `afgt-sb-td` in `us-central1` with the per-environment config. Initialization scripts `load-artifacts.sh` and `email-config.sh` download the pipeline artifact ZIP.
   - From: `continuumAfgtAirflowDag`
   - To: `continuumAfgtDataprocBatch`
   - Protocol: GCP Dataproc API

5. **Copy secrets**: `secret_copy_task` copies `ub_ma_emea_password_file` from Google Secret Manager into the cluster filesystem.
   - From: `continuumAfgtAirflowDag`
   - To: `continuumAfgtDataprocBatch`
   - Protocol: GCP Secret Manager API / SSH

6. **Initialize environment variables**: `setup_env_var_job` executes `setup_var.sh` as a Pig shell job; sets `USER_TD`, `USER_TD_PASS`, `TD_DSN_NAME`, `DEFAULT_DB`, `ODBCINI`, `ZOMBIERC` environment variables on cluster nodes.
   - From: `continuumAfgtDataprocBatch` (`afgtStageShellJobRunner`)
   - To: cluster environment
   - Protocol: Dataproc Pig shell job

7. **Activation/deactivation staging** (`act_deact`): Runs `sb_act_deact.sh` via BTEQ to populate activation/deactivation flags for the date window in Teradata staging.
   - From: `continuumAfgtDataprocBatch`
   - To: `edw` (`sb_rmaprod` staging tables)
   - Protocol: BTEQ / JDBC

8. **Deal dimension staging** (`deals`): Runs `sb_deals.sh` via BTEQ to populate `sb_rmaprod.afgt_deal` with deal dimension data.
   - From: `continuumAfgtDataprocBatch`
   - To: `edw` (`sb_rmaprod.afgt_deal`)
   - Protocol: BTEQ

9. **Stage 1 transaction enrichment** (`afgt_stg1`): Runs `sb_afgt_stg1.sh` via BTEQ. Queries `user_edwprod.fact_gbl_transactions` and joins with `sb_rmaprod.afgt_deal`, ILS discount data, and WOW subsidy data; inserts into `sb_rmaprod.afgt_stg1`. Date window: `start_date` to `end_date` (default: T-14 to T-1).
   - From: `continuumAfgtDataprocBatch`
   - To: `edw` (`sb_rmaprod.afgt_stg1`)
   - Protocol: BTEQ

10. **Payment type staging** (`pay_type`): Runs `sb_pay_type.sh` via BTEQ to compute payment type classification for the date window.
    - From: `continuumAfgtDataprocBatch`
    - To: `edw` (Teradata staging)
    - Protocol: BTEQ

11. **Stage 2 enrichment** (`afgt_stg2`): Runs `sb_afgt_stg2.sh` via BTEQ; further enriches data from stage 1.
    - From: `continuumAfgtDataprocBatch`
    - To: `edw` (`sb_rmaprod.afgt_stg2`)
    - Protocol: BTEQ

12. **Stage 3 enrichment** (`afgt_stg3`): Runs `sb_afgt_stg3.sh` via BTEQ; further enriches with attribution and segment data.
    - From: `continuumAfgtDataprocBatch`
    - To: `edw` (`sb_rmaprod.afgt_stg3`)
    - Protocol: BTEQ

13. **Stage 4 international enrichment** (`afgt_intl_stg4`): Runs `sb_afgt_intl_stg4.sh` via BTEQ for international (non-NA) markets.
    - From: `continuumAfgtDataprocBatch`
    - To: `edw` (`sb_rmaprod.afgt_stg4` — INTL partition)
    - Protocol: BTEQ

14. **Stage 4 North America enrichment** (`afgt_na_stg4`): Runs `sb_afgt_na_stg4.sh` via BTEQ for North American markets.
    - From: `continuumAfgtDataprocBatch`
    - To: `edw` (`sb_rmaprod.afgt_stg4` — NA partition)
    - Protocol: BTEQ

15. **Final Teradata table load** (`final_table`): Runs `sb_final_table.sh` via BTEQ. Deletes existing date-window rows from `sb_rmaprod.analytics_fgt` and inserts enriched rows from `sb_rmaprod.afgt_stg4`, joining with OGP, ILS, VFM, incentive, GO segmentation, and calendar dimension data.
    - From: `continuumAfgtDataprocBatch`
    - To: `edw` (`sb_rmaprod.analytics_fgt`)
    - Protocol: BTEQ

16. **Deactivation update** (`update_deact`): Runs `update_deact.sh` via BTEQ to apply deactivation flag updates to the date window.
    - From: `continuumAfgtDataprocBatch`
    - To: `edw` (`sb_rmaprod.analytics_fgt`)
    - Protocol: BTEQ

17. **RMA deals staging** (`rma_deals`): Runs `sb_rma_deals.sh` via BTEQ for RMA-specific deal staging.
    - From: `continuumAfgtDataprocBatch`
    - To: `edw` (RMA staging tables)
    - Protocol: BTEQ

18. **RMA promos staging** (`rma_promos`): Runs `sb_rma_promos.sh` via BTEQ for RMA-specific promotions staging.
    - From: `continuumAfgtDataprocBatch`
    - To: `edw` (RMA staging tables)
    - Protocol: BTEQ

19. **Parallel branch — Teradata extraction, Optimus validation, and TD alert** (after `rma_promos`):
    - `afgt_td_tmp`: Runs `afgt_td_extract.sh` via BTEQ to populate `sb_rmaprod.analytics_fgt_transfer_gcp` with a date-windowed snapshot plus 386-day deactivation backfill. See [Teradata to Hive Transfer](teradata-to-hive-transfer.md).
    - `trigger_optimus_validation`: HTTP POST to `api/v2/users/rpadala/jobs/6497/runs` on Optimus Prime to trigger validation job.
    - `gspace_alert_td`: BashOperator posts "AFGT TD Pipeline completed" message to Google Chat RMA space.
    - From: `continuumAfgtAirflowDag` (fan-out)
    - To: `edw`, `optimusPrime`, `googleChat`
    - Protocol: BTEQ / HTTP POST / HTTPS webhook

20. **Sqoop import** (`afgt_sqoop_tmp`): After `afgt_td_tmp` completes, runs `td_to_hive.sh` to import `sb_rmaprod.analytics_fgt_transfer_gcp` from Teradata into `ima.analytics_fgt_tmp_zo` on GCS via Sqoop (20 mappers, split by `transaction_date`).
    - From: `continuumAfgtDataprocBatch` (`afgtSqoopImportRunner`)
    - To: `continuumAfgtHiveDataset` (`ima.analytics_fgt_tmp_zo`)
    - Protocol: Sqoop / JDBC / GCS

21. **Hive final load** (`hive_load`): Runs `hive_load_final.hql` as a Hive job. Reads `ima.analytics_fgt_tmp_zo`, joins with `ima.user_rfm_segment_act_react` for RFM segment data, and writes `INSERT OVERWRITE ... PARTITION(transaction_date, country_id)` into `ima.analytics_fgt`.
    - From: `continuumAfgtDataprocBatch` (`afgtHiveLoadRunner`)
    - To: `continuumAfgtHiveDataset` (`ima.analytics_fgt`)
    - Protocol: Hive (Tez)

22. **Parallel completion — downstream trigger and Hive alert** (after `hive_load`):
    - `trigger_gmp_hive`: `TriggerDagRunOperator` triggers `rma-gmp-wbr-load` DAG.
    - `gspace_alert_hive`: BashOperator posts "GCP AFGT Hive Pipeline completed" to Google Chat.
    - From: `continuumAfgtAirflowDag`
    - To: Airflow (downstream DAG), `googleChat`
    - Protocol: Airflow API / HTTPS webhook

23. **Delete cluster** (`delete_cluster`): `DataprocDeleteClusterOperator` tears down the ephemeral `afgt-sb-td` cluster.
    - From: `continuumAfgtAirflowDag`
    - To: `continuumAfgtDataprocBatch`
    - Protocol: GCP Dataproc API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Any task failure | `on_failure_callback` fires `trigger_event`; Google Chat `@here` alert posted | Task retried once after 1800s; if still failing, DAG run marked failed |
| Precheck sensor timeout | `PythonSensor` with `retries=0`; waits indefinitely until upstream completes | Pipeline paused until upstream resolves; no automatic timeout |
| Cluster creation failure | Airflow `DataprocCreateClusterOperator` raises exception | All downstream tasks blocked; `delete_cluster` must be run manually or via idle TTL |
| BTEQ exit non-zero | Pig shell job returns non-zero exit code | Airflow marks task as failed; retry once; failure callback fires |
| Sqoop mapper failure | Sqoop returns non-zero exit | `afgt_sqoop_tmp` task fails; `hive_load` blocked; retry once; manual cleanup of partial GCS data required |
| Optimus Prime failure | HTTP POST fails | Non-blocking — runs in parallel with `afgt_td_tmp`; does not block `afgt_sqoop_tmp` |

## Sequence Diagram

```
Airflow Scheduler  -> afgt_sb_td DAG       : Trigger at 06:30 UTC
afgt_sb_td DAG     -> PythonSensor          : Poll OGP and GO segmentation upstream DAGs
PythonSensor       -> afgt_sb_td DAG        : Upstream ready
afgt_sb_td DAG     -> Dataproc API          : Create cluster afgt-sb-td
afgt_sb_td DAG     -> Secret Manager        : Copy ub_ma_emea_password_file
afgt_sb_td DAG     -> Dataproc cluster      : Submit setup_var.sh (Pig job)
afgt_sb_td DAG     -> Teradata EDW          : BTEQ act_deact, deals, stg1-4, final_table, update_deact, rma_deals, rma_promos
Teradata EDW       -> afgt_sb_td DAG        : Staging tables populated
afgt_sb_td DAG     -> Teradata EDW          : BTEQ afgt_td_extract.sh -> analytics_fgt_transfer_gcp
afgt_sb_td DAG     -> Optimus Prime         : POST api/v2/users/rpadala/jobs/6497/runs
afgt_sb_td DAG     -> Google Chat           : POST AFGT TD completion alert
Dataproc cluster   -> Teradata EDW / GCS    : Sqoop import analytics_fgt_transfer_gcp -> ima.analytics_fgt_tmp_zo
Dataproc cluster   -> Hive/GCS (IMA)        : hive_load_final.hql -> ima.analytics_fgt
afgt_sb_td DAG     -> rma-gmp-wbr-load DAG : TriggerDagRunOperator
afgt_sb_td DAG     -> Google Chat           : POST AFGT Hive completion alert
afgt_sb_td DAG     -> Dataproc API          : Delete cluster afgt-sb-td
```

## Related

- Architecture dynamic view: `dynamic-afgt_td_to_hive_load` (currently disabled in federation)
- Related flows: [Teradata to Hive Transfer](teradata-to-hive-transfer.md), [Precheck and Cluster Bootstrap](precheck-and-cluster-bootstrap.md)
- See [Data Stores](../data-stores.md) for full table descriptions
- See [Integrations](../integrations.md) for dependency health details
