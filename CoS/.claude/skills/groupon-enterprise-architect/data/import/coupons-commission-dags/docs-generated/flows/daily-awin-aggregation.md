---
service: "coupons-commission-dags"
title: "Daily Awin Aggregation"
generated: "2026-03-03"
type: flow
flow_name: "daily-awin-aggregation"
flow_type: scheduled
trigger: "Cron schedule: 0 6 * * * (daily, 06:00 UTC)"
participants:
  - "continuumCouponsCommissionDags"
  - "dailyAwinAggregationDag"
  - "gcpDataprocCluster"
  - "grouponArtifactory"
  - "gcpDataprocMetastore"
architecture_ref: "CouponsCommissionDagsComponents"
---

# Daily Awin Aggregation

## Summary

The daily Awin aggregation flow reads the normalized Awin commission records produced by the daily transform stage and aggregates them into summary reports for `DailyAwin_NA` and `DailyAwin_INTL`. It runs every day at 06:00 UTC — two hours after the daily transform DAG — and processes data for the day 20 calendar days prior to the execution date. This is the final stage in the daily Awin commission reporting pipeline. The flow provisions an ephemeral Dataproc cluster, submits the `DataAggregationJob` Spark JAR, and deletes the cluster on completion.

## Trigger

- **Type**: schedule
- **Source**: Airflow scheduler (cron `0 6 * * *` — active; DAG start date 2026-01-01)
- **Frequency**: Daily
- **Manual trigger**: Supported via Airflow UI with configurable `reports_to_run`; date arg resolved from Airflow `ds` macro

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Scheduler (Cloud Composer) | Triggers DAG run daily | external |
| Daily Awin Aggregation DAG | Orchestrates cluster lifecycle and Spark job submission | `dailyAwinAggregationDag` |
| Groupon Artifactory | Serves the aggregation Spark JAR assembly | `grouponArtifactory` |
| GCP Dataproc Cluster | Executes the Spark aggregation job for Awin | `gcpDataprocCluster` |
| GCP Dataproc Metastore | Provides Hive metadata during Spark execution | `gcpDataprocMetastore` |

## Steps

1. **Start marker**: Airflow `DummyOperator` (`start`) marks DAG run initiation.
   - From: `Airflow Scheduler`
   - To: `dailyAwinAggregationDag`
   - Protocol: Airflow internal

2. **Log debug info**: Python `log_debug_info` task logs cluster name, labels, and Spark JAR version.
   - From: `dailyAwinAggregationDag`
   - To: Airflow logs / Stackdriver
   - Protocol: Python function call

3. **Create Dataproc cluster**: `DataprocCreateClusterOperator` provisions the ephemeral cluster `cpns-comm-rpt-daily-awin-agg-prod-cluster` in `us-central1-f` with 1 master + 2 workers (`n1-standard-8`, 500 GB pd-standard each).
   - From: `dailyAwinAggregationDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP SDK

4. **Submit Spark Awin aggregation job**: `DataprocSubmitJobOperator` submits the `DataAggregationJob` Spark job (`coupons-commission-aggregation_2-4-8_2.12-0.33-assembly.jar`). Arguments: `--processing_end_date` = `macros.ds_add(ds, -20)`, `--reports_to_run` = `DailyAwin_NA,DailyAwin_INTL`.
   - From: `dailyAwinAggregationDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP Dataproc API (Spark submit, deploy mode: cluster)

5. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` tears down the ephemeral cluster.
   - From: `dailyAwinAggregationDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP SDK

6. **End marker**: Airflow `DummyOperator` (`end`) marks DAG run completion.
   - From: `dailyAwinAggregationDag`
   - To: Airflow scheduler
   - Protocol: Airflow internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Daily transform not completed | Independent DAG — relies on 2-hour schedule offset; no explicit dependency | Aggregation may fail or produce incomplete results if transform overruns |
| Cluster creation fails | No retry; task marked FAILED | Daily Awin aggregate report not produced for that day |
| Spark job fails | No retry; task marked FAILED | Cluster still deleted; that day's aggregated reports are not generated |
| Cluster deletion fails | No retry; task marked FAILED | Orphaned cluster accrues cost; manual cleanup via GCP Console |

## Sequence Diagram

```
AirflowScheduler -> dailyAwinAggregationDag: Trigger DAG run (cron 0 6 * * *)
dailyAwinAggregationDag -> AirflowLogs: log_debug_info (cluster name, JAR version)
dailyAwinAggregationDag -> gcpDataprocCluster: DataprocCreateClusterOperator (cpns-comm-rpt-daily-awin-agg-prod-cluster)
gcpDataprocCluster -> gcpDataprocMetastore: Connect for Hive metadata
dailyAwinAggregationDag -> gcpDataprocCluster: DataprocSubmitJobOperator (DataAggregationJob JAR, --processing_end_date=ds-20, --reports_to_run=DailyAwin_NA,DailyAwin_INTL)
gcpDataprocCluster --> dailyAwinAggregationDag: Job SUCCEEDED / FAILED
dailyAwinAggregationDag -> gcpDataprocCluster: DataprocDeleteClusterOperator
gcpDataprocCluster --> dailyAwinAggregationDag: Cluster deleted
dailyAwinAggregationDag --> AirflowScheduler: DAG run complete
```

## Related

- Architecture dynamic view: No dynamic view captured for this flow
- Related flows: [Daily Awin Sourcing](daily-awin-sourcing.md), [Daily Awin Transform](daily-awin-transform.md), [Monthly Commission Aggregation](monthly-commission-aggregation.md)
