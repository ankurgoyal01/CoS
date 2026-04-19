---
service: "coupons-commission-dags"
title: "Monthly Commission Sourcing"
generated: "2026-03-03"
type: flow
flow_name: "monthly-commission-sourcing"
flow_type: scheduled
trigger: "Cron schedule: 0 2 1 * * (1st of month, 02:00 UTC, production only)"
participants:
  - "continuumCouponsCommissionDags"
  - "sourcingDag"
  - "gcpDataprocCluster"
  - "grouponArtifactory"
  - "gcpDataprocMetastore"
architecture_ref: "CouponsCommissionDagsComponents"
---

# Monthly Commission Sourcing

## Summary

The monthly commission sourcing flow ingests raw commission transaction data for all configured affiliate networks and accounts for the preceding 12-month date window. The flow runs on the 1st of each month at 02:00 UTC in production, provisions an ephemeral Dataproc cluster, submits the `SourcingMainJob` Spark JAR, and tears down the cluster on completion. This is the first of three sequential monthly pipeline stages.

## Trigger

- **Type**: schedule
- **Source**: Airflow scheduler (cron `0 2 1 * *` in production; `None` / paused in dev and stable)
- **Frequency**: Monthly (1st of each month)
- **Manual trigger**: Supported via Airflow UI with configurable `sourcing_start_date`, `sourcing_end_date`, and `accounts_to_run` parameters

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Scheduler (Cloud Composer) | Triggers DAG run on schedule | external |
| Coupons Commission Sourcing DAG | Orchestrates cluster lifecycle and Spark job submission | `sourcingDag` |
| Groupon Artifactory | Serves the sourcing Spark JAR assembly | `grouponArtifactory` |
| GCP Dataproc Cluster | Executes the Spark sourcing job | `gcpDataprocCluster` |
| GCP Dataproc Metastore | Provides Hive metadata during Spark execution | `gcpDataprocMetastore` |

## Steps

1. **Start marker**: Airflow `DummyOperator` (`start`) marks DAG run initiation.
   - From: `Airflow Scheduler`
   - To: `sourcingDag`
   - Protocol: Airflow internal

2. **Log debug info**: Python `log_debug_info` task logs the cluster name, labels, and Spark JAR version to Airflow task logs.
   - From: `sourcingDag`
   - To: Airflow logs / Stackdriver
   - Protocol: Python function call

3. **Create Dataproc cluster**: `DataprocCreateClusterOperator` provisions the ephemeral cluster `cpns-comm-rpt-sourcing-prod-cluster` in `us-central1-f` with 1 master + 2 workers (`n1-standard-8`, 500 GB pd-standard each), connecting to the Dataproc Metastore.
   - From: `sourcingDag`
   - To: `gcpDataprocCluster` (GCP Dataproc API)
   - Protocol: GCP SDK

4. **Submit Spark sourcing job**: `DataprocSubmitJobOperator` submits the `SourcingMainJob` Spark job to the cluster. The JAR is fetched from Artifactory at `coupons-commission-sourcing_2-4-8_2.12-0.51-assembly.jar`. Arguments passed: `--sourcing_start_date` (default: 12 months prior), `--sourcing_end_date` (default: last day of previous month), `--accounts_to_run` (default: ~80 affiliate accounts across IR, AWIN, Partnerize, eBay, Skimlinks, CJ, Webgains, TradeDoubler, CommissionFactory, BrandReward, Pepperjam).
   - From: `sourcingDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP Dataproc API (Spark submit, deploy mode: cluster)

5. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` tears down the ephemeral cluster regardless of Spark job outcome (runs in sequence after the spark task).
   - From: `sourcingDag`
   - To: `gcpDataprocCluster` (GCP Dataproc API)
   - Protocol: GCP SDK

6. **End marker**: Airflow `DummyOperator` (`end`) marks DAG run completion.
   - From: `sourcingDag`
   - To: Airflow scheduler
   - Protocol: Airflow internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cluster creation fails | No retry (`retries=0`); task marked FAILED | DAG run fails; no Spark job submitted; cluster delete still attempted |
| Spark job fails (JAR not found) | No retry; task marked FAILED | DAG run fails; cluster is still deleted by next task |
| Spark job fails (runtime error) | No retry; task marked FAILED | DAG run fails; cluster is still deleted |
| Cluster deletion fails | No retry; task marked FAILED | Orphaned cluster may incur GCP costs; manual cleanup required |

## Sequence Diagram

```
AirflowScheduler -> sourcingDag: Trigger DAG run (cron 0 2 1 * *)
sourcingDag -> AirflowLogs: log_debug_info (cluster name, JAR version)
sourcingDag -> gcpDataprocCluster: DataprocCreateClusterOperator (cpns-comm-rpt-sourcing-prod-cluster)
gcpDataprocCluster -> gcpDataprocMetastore: Connect for Hive metadata
sourcingDag -> gcpDataprocCluster: DataprocSubmitJobOperator (SourcingMainJob JAR, --sourcing_start_date, --sourcing_end_date, --accounts_to_run)
gcpDataprocCluster --> sourcingDag: Job SUCCEEDED / FAILED
sourcingDag -> gcpDataprocCluster: DataprocDeleteClusterOperator
gcpDataprocCluster --> sourcingDag: Cluster deleted
sourcingDag --> AirflowScheduler: DAG run complete
```

## Related

- Architecture dynamic view: No dynamic view captured for this flow
- Related flows: [Monthly Commission Transform](monthly-commission-transform.md), [Monthly Commission Aggregation](monthly-commission-aggregation.md)
