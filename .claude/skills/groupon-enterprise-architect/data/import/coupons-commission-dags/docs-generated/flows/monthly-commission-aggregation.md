---
service: "coupons-commission-dags"
title: "Monthly Commission Aggregation"
generated: "2026-03-03"
type: flow
flow_name: "monthly-commission-aggregation"
flow_type: scheduled
trigger: "Cron schedule: 0 6 1 * * (1st of month, 06:00 UTC, production only)"
participants:
  - "continuumCouponsCommissionDags"
  - "aggregationDag"
  - "gcpDataprocCluster"
  - "grouponArtifactory"
  - "gcpDataprocMetastore"
architecture_ref: "CouponsCommissionDagsComponents"
---

# Monthly Commission Aggregation

## Summary

The monthly commission aggregation flow reads the normalized commission records produced by the transform stage and produces rolled-up summary commission reports for each affiliate network. It runs on the 1st of each month at 06:00 UTC — two hours after the transform stage — to allow transformation to complete first. The flow provisions an ephemeral Dataproc cluster, submits the `DataAggregationJob` Spark JAR, and deletes the cluster on completion. This is the final stage in the monthly commission reporting pipeline.

## Trigger

- **Type**: schedule
- **Source**: Airflow scheduler (cron `0 6 1 * *` in production; `None` / paused in dev and stable)
- **Frequency**: Monthly (1st of each month)
- **Manual trigger**: Supported via Airflow UI with configurable `processing_end_date` and `reports_to_run` parameters

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Scheduler (Cloud Composer) | Triggers DAG run on schedule | external |
| Coupons Commission Aggregation DAG | Orchestrates cluster lifecycle and Spark job submission | `aggregationDag` |
| Groupon Artifactory | Serves the aggregation Spark JAR assembly | `grouponArtifactory` |
| GCP Dataproc Cluster | Executes the Spark aggregation job | `gcpDataprocCluster` |
| GCP Dataproc Metastore | Provides Hive metadata during Spark execution | `gcpDataprocMetastore` |

## Steps

1. **Start marker**: Airflow `DummyOperator` (`start`) marks DAG run initiation.
   - From: `Airflow Scheduler`
   - To: `aggregationDag`
   - Protocol: Airflow internal

2. **Log debug info**: Python `log_debug_info` task logs the cluster name, labels, and Spark JAR version.
   - From: `aggregationDag`
   - To: Airflow logs / Stackdriver
   - Protocol: Python function call

3. **Create Dataproc cluster**: `DataprocCreateClusterOperator` provisions the ephemeral cluster `cpns-comm-rpt-agg-prod-cluster` in `us-central1-f` with 1 master + 2 workers (`n1-standard-8`, 500 GB pd-standard each).
   - From: `aggregationDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP SDK

4. **Submit Spark aggregation job**: `DataprocSubmitJobOperator` submits the `DataAggregationJob` Spark job. The JAR is fetched from Artifactory at `coupons-commission-aggregation_2-4-8_2.12-0.33-assembly.jar`. Arguments passed: `--processing_end_date` (default: last day of previous month), `--reports_to_run` (default: `IR_NA,IR_INTL,AWIN_NA,AWIN_INTL,Partnerize_NA,Ebay_NA,Skimlinks_NA,CommissionFactory_INTL,BrandReward_INTL,Partnerize_INTL,Webgains_INTL,TradeDoubler_INTL,Pepperjam_NA`).
   - From: `aggregationDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP Dataproc API (Spark submit, deploy mode: cluster)

5. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` tears down the ephemeral cluster.
   - From: `aggregationDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP SDK

6. **End marker**: Airflow `DummyOperator` (`end`) marks DAG run completion.
   - From: `aggregationDag`
   - To: Airflow scheduler
   - Protocol: Airflow internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Transform stage not completed | Independent DAG — relies on 2-hour schedule offset; no explicit dependency | Aggregation may process incomplete data if transform overruns |
| Cluster creation fails | No retry; task marked FAILED | DAG run fails; commission reports not produced |
| Spark job fails | No retry; task marked FAILED | DAG run fails; cluster still deleted; previous month's aggregate may be last valid report |
| Cluster deletion fails | No retry; task marked FAILED | Orphaned cluster accrues GCP cost; manual cleanup required |

## Sequence Diagram

```
AirflowScheduler -> aggregationDag: Trigger DAG run (cron 0 6 1 * *)
aggregationDag -> AirflowLogs: log_debug_info (cluster name, JAR version)
aggregationDag -> gcpDataprocCluster: DataprocCreateClusterOperator (cpns-comm-rpt-agg-prod-cluster)
gcpDataprocCluster -> gcpDataprocMetastore: Connect for Hive metadata
aggregationDag -> gcpDataprocCluster: DataprocSubmitJobOperator (DataAggregationJob JAR, --processing_end_date, --reports_to_run)
gcpDataprocCluster --> aggregationDag: Job SUCCEEDED / FAILED
aggregationDag -> gcpDataprocCluster: DataprocDeleteClusterOperator
gcpDataprocCluster --> aggregationDag: Cluster deleted
aggregationDag --> AirflowScheduler: DAG run complete
```

## Related

- Architecture dynamic view: No dynamic view captured for this flow
- Related flows: [Monthly Commission Sourcing](monthly-commission-sourcing.md), [Monthly Commission Transform](monthly-commission-transform.md)
