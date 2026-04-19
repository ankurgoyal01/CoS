---
service: "coupons-commission-dags"
title: "Daily Awin Transform"
generated: "2026-03-03"
type: flow
flow_name: "daily-awin-transform"
flow_type: scheduled
trigger: "Cron schedule: 0 4 * * * (daily, 04:00 UTC)"
participants:
  - "continuumCouponsCommissionDags"
  - "dailyAwinTransformDag"
  - "gcpDataprocCluster"
  - "grouponArtifactory"
  - "gcpDataprocMetastore"
architecture_ref: "CouponsCommissionDagsComponents"
---

# Daily Awin Transform

## Summary

The daily Awin transform flow reads the raw Awin commission data sourced two hours earlier and applies transformation logic to produce normalized daily Awin commission records. It runs every day at 04:00 UTC, two hours after the daily Awin sourcing DAG, to allow sourcing to complete. The flow covers two report groups: `DailyAwin_NA` and `DailyAwin_INTL`. It provisions an ephemeral Dataproc cluster, submits the `DataTransformationJob` Spark JAR with a 20-day lookback date, and deletes the cluster on completion.

## Trigger

- **Type**: schedule
- **Source**: Airflow scheduler (cron `0 4 * * *` — active; DAG start date 2026-01-01)
- **Frequency**: Daily
- **Manual trigger**: Supported via Airflow UI with configurable `reports_to_run`; date arg resolved from Airflow `ds` macro

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Scheduler (Cloud Composer) | Triggers DAG run daily | external |
| Daily Awin Transform DAG | Orchestrates cluster lifecycle and Spark job submission | `dailyAwinTransformDag` |
| Groupon Artifactory | Serves the transformation Spark JAR assembly | `grouponArtifactory` |
| GCP Dataproc Cluster | Executes the Spark transformation job for Awin | `gcpDataprocCluster` |
| GCP Dataproc Metastore | Provides Hive metadata during Spark execution | `gcpDataprocMetastore` |

## Steps

1. **Start marker**: Airflow `DummyOperator` (`start`) marks DAG run initiation.
   - From: `Airflow Scheduler`
   - To: `dailyAwinTransformDag`
   - Protocol: Airflow internal

2. **Log debug info**: Python `log_debug_info` task logs cluster name, labels, and Spark JAR version.
   - From: `dailyAwinTransformDag`
   - To: Airflow logs / Stackdriver
   - Protocol: Python function call

3. **Create Dataproc cluster**: `DataprocCreateClusterOperator` provisions the ephemeral cluster `cpns-comm-rpt-daily-awin-transform-prod-cluster` in `us-central1-f` with 1 master + 2 workers (`n1-standard-8`, 500 GB pd-standard each). Optional components Zeppelin, Anaconda, and Jupyter are enabled.
   - From: `dailyAwinTransformDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP SDK

4. **Submit Spark Awin transformation job**: `DataprocSubmitJobOperator` submits the `DataTransformationJob` Spark job (`coupons-commission-transformation_2-4-8_2.12-0.49-assembly.jar`). Arguments: `--processing_end_date` = `macros.ds_add(ds, -20)`, `--reports_to_run` = `DailyAwin_NA,DailyAwin_INTL`.
   - From: `dailyAwinTransformDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP Dataproc API (Spark submit, deploy mode: cluster)

5. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` tears down the ephemeral cluster.
   - From: `dailyAwinTransformDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP SDK

6. **End marker**: Airflow `DummyOperator` (`end`) marks DAG run completion.
   - From: `dailyAwinTransformDag`
   - To: Airflow scheduler
   - Protocol: Airflow internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Daily sourcing not completed | Independent DAG — relies on 2-hour schedule offset; no explicit dependency | Transform may fail or produce partial results if sourcing overruns |
| Cluster creation fails | No retry; task marked FAILED | That day's Awin transformation is skipped |
| Spark job fails | No retry; task marked FAILED | Cluster still deleted; normalized data not produced for that day |

## Sequence Diagram

```
AirflowScheduler -> dailyAwinTransformDag: Trigger DAG run (cron 0 4 * * *)
dailyAwinTransformDag -> AirflowLogs: log_debug_info (cluster name, JAR version)
dailyAwinTransformDag -> gcpDataprocCluster: DataprocCreateClusterOperator (cpns-comm-rpt-daily-awin-transform-prod-cluster)
gcpDataprocCluster -> gcpDataprocMetastore: Connect for Hive metadata
dailyAwinTransformDag -> gcpDataprocCluster: DataprocSubmitJobOperator (DataTransformationJob JAR, --processing_end_date=ds-20, --reports_to_run=DailyAwin_NA,DailyAwin_INTL)
gcpDataprocCluster --> dailyAwinTransformDag: Job SUCCEEDED / FAILED
dailyAwinTransformDag -> gcpDataprocCluster: DataprocDeleteClusterOperator
gcpDataprocCluster --> dailyAwinTransformDag: Cluster deleted
dailyAwinTransformDag --> AirflowScheduler: DAG run complete
```

## Related

- Architecture dynamic view: No dynamic view captured for this flow
- Related flows: [Daily Awin Sourcing](daily-awin-sourcing.md), [Daily Awin Aggregation](daily-awin-aggregation.md), [Monthly Commission Transform](monthly-commission-transform.md)
