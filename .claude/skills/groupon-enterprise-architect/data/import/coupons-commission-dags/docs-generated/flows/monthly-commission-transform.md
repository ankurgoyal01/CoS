---
service: "coupons-commission-dags"
title: "Monthly Commission Transform"
generated: "2026-03-03"
type: flow
flow_name: "monthly-commission-transform"
flow_type: scheduled
trigger: "Cron schedule: 0 4 1 * * (1st of month, 04:00 UTC, production only)"
participants:
  - "continuumCouponsCommissionDags"
  - "transformDag"
  - "gcpDataprocCluster"
  - "grouponArtifactory"
  - "gcpDataprocMetastore"
architecture_ref: "CouponsCommissionDagsComponents"
---

# Monthly Commission Transform

## Summary

The monthly commission transform flow reads raw sourced commission data from the prior sourcing stage and applies network-specific transformation logic to produce normalized commission records. It runs on the 1st of each month at 04:00 UTC in production — two hours after the sourcing stage — to allow sourcing to complete first. The flow provisions an ephemeral Dataproc cluster, submits the `DataTransformationJob` Spark JAR, and deletes the cluster on completion.

## Trigger

- **Type**: schedule
- **Source**: Airflow scheduler (cron `0 4 1 * *` in production; `None` / paused in dev and stable)
- **Frequency**: Monthly (1st of each month)
- **Manual trigger**: Supported via Airflow UI with configurable `processing_end_date` and `reports_to_run` parameters

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Scheduler (Cloud Composer) | Triggers DAG run on schedule | external |
| Coupons Commission Transform DAG | Orchestrates cluster lifecycle and Spark job submission | `transformDag` |
| Groupon Artifactory | Serves the transformation Spark JAR assembly | `grouponArtifactory` |
| GCP Dataproc Cluster | Executes the Spark transformation job | `gcpDataprocCluster` |
| GCP Dataproc Metastore | Provides Hive metadata during Spark execution | `gcpDataprocMetastore` |

## Steps

1. **Start marker**: Airflow `DummyOperator` (`start`) marks DAG run initiation.
   - From: `Airflow Scheduler`
   - To: `transformDag`
   - Protocol: Airflow internal

2. **Log debug info**: Python `log_debug_info` task logs the cluster name, labels, and Spark JAR version.
   - From: `transformDag`
   - To: Airflow logs / Stackdriver
   - Protocol: Python function call

3. **Create Dataproc cluster**: `DataprocCreateClusterOperator` provisions the ephemeral cluster `cpns-comm-rpt-transform-prod-cluster` in `us-central1-f` with 1 master + 2 workers (`n1-standard-8`, 500 GB pd-standard each). Optional components Zeppelin, Anaconda, and Jupyter are enabled on this cluster.
   - From: `transformDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP SDK

4. **Submit Spark transformation job**: `DataprocSubmitJobOperator` submits the `DataTransformationJob` Spark job. The JAR is fetched from Artifactory at `coupons-commission-transformation_2-4-8_2.12-0.49-assembly.jar`. Arguments passed: `--processing_end_date` (default: last day of previous month), `--reports_to_run` (default: `IR_NA,IR_INTL,AWIN_NA,AWIN_INTL,Partnerize_NA,Ebay_NA,Skimlinks_NA,CommissionFactory_INTL,BrandReward_INTL,Partnerize_INTL,Webgains_INTL,TradeDoubler_INTL,CJ_NA,CJ_INTL,Pepperjam_NA`).
   - From: `transformDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP Dataproc API (Spark submit, deploy mode: cluster)

5. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` tears down the ephemeral cluster.
   - From: `transformDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP SDK

6. **End marker**: Airflow `DummyOperator` (`end`) marks DAG run completion.
   - From: `transformDag`
   - To: Airflow scheduler
   - Protocol: Airflow internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Sourcing stage not completed | Independent DAG — no explicit dependency check; relies on 2-hour schedule offset | Transform may process incomplete data if sourcing overruns |
| Cluster creation fails | No retry; task marked FAILED | DAG run fails; no Spark job submitted |
| Spark job fails (JAR not found) | No retry; task marked FAILED | DAG run fails; cluster still deleted |
| Spark job fails (runtime error) | No retry; task marked FAILED | DAG run fails; cluster still deleted |

## Sequence Diagram

```
AirflowScheduler -> transformDag: Trigger DAG run (cron 0 4 1 * *)
transformDag -> AirflowLogs: log_debug_info (cluster name, JAR version)
transformDag -> gcpDataprocCluster: DataprocCreateClusterOperator (cpns-comm-rpt-transform-prod-cluster, with Zeppelin/Anaconda/Jupyter)
gcpDataprocCluster -> gcpDataprocMetastore: Connect for Hive metadata
transformDag -> gcpDataprocCluster: DataprocSubmitJobOperator (DataTransformationJob JAR, --processing_end_date, --reports_to_run)
gcpDataprocCluster --> transformDag: Job SUCCEEDED / FAILED
transformDag -> gcpDataprocCluster: DataprocDeleteClusterOperator
gcpDataprocCluster --> transformDag: Cluster deleted
transformDag --> AirflowScheduler: DAG run complete
```

## Related

- Architecture dynamic view: No dynamic view captured for this flow
- Related flows: [Monthly Commission Sourcing](monthly-commission-sourcing.md), [Monthly Commission Aggregation](monthly-commission-aggregation.md)
