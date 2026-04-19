---
service: "coupons-commission-dags"
title: "Daily Awin Sourcing"
generated: "2026-03-03"
type: flow
flow_name: "daily-awin-sourcing"
flow_type: scheduled
trigger: "Cron schedule: 0 2 * * * (daily, 02:00 UTC)"
participants:
  - "continuumCouponsCommissionDags"
  - "dailyAwinSourcingDag"
  - "gcpDataprocCluster"
  - "grouponArtifactory"
  - "gcpDataprocMetastore"
architecture_ref: "CouponsCommissionDagsComponents"
---

# Daily Awin Sourcing

## Summary

The daily Awin sourcing flow ingests raw Awin affiliate commission transaction data for a single day — specifically the day 20 calendar days before the current execution date. The 20-day lookback accounts for Awin's typical reporting lag. Unlike the monthly sourcing DAG, this flow is active (`is_paused_upon_creation=False`) and runs every day at 02:00 UTC. It provisions an ephemeral Dataproc cluster, submits the same `SourcingMainJob` Spark JAR as the monthly pipeline but restricted to Awin accounts only, then deletes the cluster.

## Trigger

- **Type**: schedule
- **Source**: Airflow scheduler (cron `0 2 * * *` — active in all environments; DAG start date 2026-01-01)
- **Frequency**: Daily
- **Manual trigger**: Supported via Airflow UI with configurable `accounts_to_run`; date args are resolved from Airflow `ds` macro

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Scheduler (Cloud Composer) | Triggers DAG run daily | external |
| Daily Awin Sourcing DAG | Orchestrates cluster lifecycle and Spark job submission | `dailyAwinSourcingDag` |
| Groupon Artifactory | Serves the sourcing Spark JAR assembly | `grouponArtifactory` |
| GCP Dataproc Cluster | Executes the Spark sourcing job for Awin accounts | `gcpDataprocCluster` |
| GCP Dataproc Metastore | Provides Hive metadata during Spark execution | `gcpDataprocMetastore` |

## Steps

1. **Start marker**: Airflow `DummyOperator` (`start`) marks DAG run initiation.
   - From: `Airflow Scheduler`
   - To: `dailyAwinSourcingDag`
   - Protocol: Airflow internal

2. **Log debug info**: Python `log_debug_info` task logs cluster name, labels, and Spark JAR version.
   - From: `dailyAwinSourcingDag`
   - To: Airflow logs / Stackdriver
   - Protocol: Python function call

3. **Create Dataproc cluster**: `DataprocCreateClusterOperator` provisions the ephemeral cluster `cpns-comm-rpt-daily-awin-sourcing-prod-cluster` in `us-central1-f` with 1 master + 2 workers (`n1-standard-8`, 500 GB pd-standard each).
   - From: `dailyAwinSourcingDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP SDK

4. **Submit Spark Awin sourcing job**: `DataprocSubmitJobOperator` submits the `SourcingMainJob` Spark job (same JAR as monthly: `coupons-commission-sourcing_2-4-8_2.12-0.51-assembly.jar`). Arguments: `--sourcing_start_date` = `macros.ds_add(ds, -20)`, `--sourcing_end_date` = `macros.ds_add(ds, -20)` (single day, 20 days ago), `--accounts_to_run` = 25 DailyAwin accounts (NA, UK, AU, NL, FR, PL, ES, IT, DE, IE, US, AE, BR).
   - From: `dailyAwinSourcingDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP Dataproc API (Spark submit, deploy mode: cluster)

5. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` tears down the ephemeral cluster.
   - From: `dailyAwinSourcingDag`
   - To: `gcpDataprocCluster`
   - Protocol: GCP SDK

6. **End marker**: Airflow `DummyOperator` (`end`) marks DAG run completion.
   - From: `dailyAwinSourcingDag`
   - To: Airflow scheduler
   - Protocol: Airflow internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cluster creation fails | No retry; task marked FAILED | That day's Awin data is not sourced; gap in daily data |
| Spark job fails | No retry; task marked FAILED | Cluster still deleted; that day's 20-day-lookback data is missing |
| Cluster deletion fails | No retry; task marked FAILED | Orphaned cluster accrues cost; manual cleanup needed |

## Sequence Diagram

```
AirflowScheduler -> dailyAwinSourcingDag: Trigger DAG run (cron 0 2 * * *)
dailyAwinSourcingDag -> AirflowLogs: log_debug_info (cluster name, JAR version)
dailyAwinSourcingDag -> gcpDataprocCluster: DataprocCreateClusterOperator (cpns-comm-rpt-daily-awin-sourcing-prod-cluster)
gcpDataprocCluster -> gcpDataprocMetastore: Connect for Hive metadata
dailyAwinSourcingDag -> gcpDataprocCluster: DataprocSubmitJobOperator (SourcingMainJob JAR, --sourcing_start_date=ds-20, --sourcing_end_date=ds-20, --accounts_to_run=DailyAwin_*)
gcpDataprocCluster --> dailyAwinSourcingDag: Job SUCCEEDED / FAILED
dailyAwinSourcingDag -> gcpDataprocCluster: DataprocDeleteClusterOperator
gcpDataprocCluster --> dailyAwinSourcingDag: Cluster deleted
dailyAwinSourcingDag --> AirflowScheduler: DAG run complete
```

## Related

- Architecture dynamic view: No dynamic view captured for this flow
- Related flows: [Daily Awin Transform](daily-awin-transform.md), [Daily Awin Aggregation](daily-awin-aggregation.md), [Monthly Commission Sourcing](monthly-commission-sourcing.md)
