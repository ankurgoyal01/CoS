---
service: "afgt"
title: "Upstream Precheck and Cluster Bootstrap"
generated: "2026-03-03"
type: flow
flow_name: "precheck-and-cluster-bootstrap"
flow_type: scheduled
trigger: "Start of afgt_sb_td DAG run; triggered daily by Airflow cron at 30 6 * * * UTC"
participants:
  - "continuumAfgtAirflowDag"
  - "continuumAfgtDataprocBatch"
architecture_ref: "components-afgt-airflow"
---

# Upstream Precheck and Cluster Bootstrap

## Summary

This flow covers the initialization phase of the `afgt_sb_td` DAG before any compute work begins. It validates that two required upstream pipelines have completed for the current day, sends a confirmation email, provisions the ephemeral Dataproc cluster with the correct configuration and pipeline artifacts, copies the required Teradata credentials secret from Google Secret Manager into the cluster, and initializes the shell environment variables needed by BTEQ and Sqoop scripts.

## Trigger

- **Type**: schedule
- **Source**: Airflow cron at `30 6 * * *` UTC; the `start` task runs immediately and the precheck sensors begin polling
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AFGT TD Airflow DAG | Orchestrator — manages precheck sensor tasks and cluster lifecycle operators | `continuumAfgtAirflowDag` |
| AFGT Dataproc Batch Jobs | Compute target — cluster provisioned and bootstrapped during this phase | `continuumAfgtDataprocBatch` |

## Steps

1. **DAG run start** (`start` task): `PythonOperator` executes `CheckRunsLegacy.calculate_varPartitionId`; determines run partition ID. Trigger rule is `none_failed_or_skipped`.
   - From: `continuumAfgtAirflowDag` (`afgtDagOrchestrator`)
   - To: `continuumAfgtAirflowDag` (internal state)
   - Protocol: Airflow PythonOperator

2. **OGP precheck** (`ogp_check`): `PythonSensor` polls `CheckRuns.check_daily_completion` for DAG `DLY_OGP_FINANCIAL_varRUNDATE_0003`. Runs in parallel with `go_segment_check`. Polls with `retries=0`; waits until upstream DAG reports daily completion.
   - From: `continuumAfgtAirflowDag` (`afgtPrecheckSensors`)
   - To: Airflow internal state
   - Protocol: PythonSensor

3. **GO segmentation precheck** (`go_segment_check`): `PythonSensor` polls `CheckRunsLegacy.monitoring_task` for DAG `go_segmentation`, task `end`, status `['success']`, with `time_scope=0`.
   - From: `continuumAfgtAirflowDag` (`afgtPrecheckSensors`)
   - To: Airflow internal state
   - Protocol: PythonSensor

4. **Precheck confirmation email** (`ogp_check_email`): `EmailOperator` sends HTML email to `rev_mgmt_analytics@groupon.com` confirming "OGP Pre-check Completed Successfully. AFGT TD pipeline is in progress." Runs after both precheck sensors pass.
   - From: `continuumAfgtAirflowDag` (`afgtNotificationAndTriggerAdapters`)
   - To: email recipients
   - Protocol: SMTP

5. **Create Dataproc cluster** (`create_cluster`): `DataprocCreateClusterOperator` creates cluster named `afgt-sb-td` in `us-central1` using the per-environment `cluster_config` from `rm_afgt_connex_config.json`. Cluster initialization actions download the pipeline artifact ZIP (`afgt-{version}.zip`) from Artifactory GCS path and configure email. Cluster is labeled with `service=dnd-bia-data-engineering`, `owner=rev_mgmt_analytics`, `pipeline=afgt`.
   - From: `continuumAfgtAirflowDag` (`afgtDataprocClusterLifecycle`)
   - To: `continuumAfgtDataprocBatch`
   - Protocol: GCP Dataproc API

6. **Copy Teradata secret** (`secret_copy_task`): `CopySecretOperator` (internal operator) retrieves `ub_ma_emea_password_file` secret from Google Secret Manager and places it at `/home/app/artifacts/ub_ma_emea_password_file.txt` on the cluster nodes.
   - From: `continuumAfgtAirflowDag`
   - To: `continuumAfgtDataprocBatch` (cluster filesystem)
   - Protocol: GCP Secret Manager API

7. **Initialize environment variables** (`setup_env_var_job`): `DataprocSubmitJobOperator` submits a Pig shell job that executes `setup_var.sh`. This script:
   - Creates `/etc/profile.d/afgt_env.sh` with exported variables: `HOME`, `zr_job_folder_rev`, `ZOMBIERC`, `ODBCINI`, `DEFAULT_DB`, `USER_TD=ub_ma_emea`, `TD_DSN_NAME=teradata.groupondev.com`
   - Reads the Teradata password from the secret file and exports `USER_TD_PASS`
   - Injects the password into `afgt_zr/odbc.ini` via `sed` replacement
   - From: `continuumAfgtDataprocBatch` (`afgtStageShellJobRunner`)
   - To: cluster environment (`/etc/profile.d/afgt_env.sh`)
   - Protocol: Dataproc Pig shell job

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| OGP precheck sensor waits too long | No timeout configured (`retries=0`); DAG run remains in `running` state | Pipeline paused; operator must manually clear or wait for upstream |
| GO segmentation precheck stuck | Same as above; no automatic timeout | Pipeline paused; escalate to `go_segmentation` DAG owner |
| Cluster creation failure | `DataprocCreateClusterOperator` raises exception; Airflow retries once after 1800s | All downstream tasks blocked until cluster is available |
| Secret copy failure | `CopySecretOperator` raises exception; DAG retries once | BTEQ scripts will fail without credentials; must resolve Secret Manager access |
| `setup_var.sh` failure | Pig job returns non-zero exit; Airflow retries once | All BTEQ tasks will fail without environment variables; check cluster initialization logs |

## Sequence Diagram

```
Airflow Scheduler   -> afgt_sb_td DAG       : Trigger at 06:30 UTC
afgt_sb_td DAG      -> Airflow state         : start task (calculate_varPartitionId)
afgt_sb_td DAG      -> Airflow state         : ogp_check PythonSensor (poll DLY_OGP_FINANCIAL)
afgt_sb_td DAG      -> Airflow state         : go_segment_check PythonSensor (poll go_segmentation)
Airflow state      --> afgt_sb_td DAG        : Both sensors pass
afgt_sb_td DAG      -> Email recipients      : ogp_check_email (precheck confirmation)
afgt_sb_td DAG      -> GCP Dataproc API      : Create cluster afgt-sb-td
GCP Dataproc API    -> GCS / Artifactory     : Initialization scripts download afgt-{version}.zip
GCP Dataproc API   --> afgt_sb_td DAG        : Cluster ready
afgt_sb_td DAG      -> Secret Manager        : CopySecretOperator retrieves ub_ma_emea_password_file
Secret Manager     --> Cluster filesystem    : Password file at /home/app/artifacts/
afgt_sb_td DAG      -> Cluster (Pig job)     : Submit setup_var.sh
Cluster            --> /etc/profile.d/       : afgt_env.sh written with all env vars
afgt_sb_td DAG      -> afgt_sb_td DAG        : Proceed to act_deact (main staging phase)
```

## Related

- Parent flow: [Daily AFGT TD Pipeline](daily-afgt-td-pipeline.md)
- Related flows: [Teradata to Hive Transfer](teradata-to-hive-transfer.md)
- See [Configuration](../configuration.md) for full environment variable documentation
- See [Deployment](../deployment.md) for cluster size and environment details
- Architecture component view: `components-afgt-airflow`
