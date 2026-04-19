---
service: "cas-data-pipeline-dags"
title: "NA Email Data Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "na-email-data-pipeline"
flow_type: batch
trigger: "Manual trigger or external orchestration via Cloud Composer; schedule_interval=None"
participants:
  - "continuumCasDataPipelineDags"
  - "continuumCasSparkBatchJobs"
  - "gcpDataprocCluster"
  - "hiveWarehouse"
architecture_ref: "dynamic-continuum-cas-data-pipeline-dags"
---

# NA Email Data Pipeline

## Summary

The NA Email Data Pipeline DAG (`cas-arbitration-machine-learning-connection-jobs`, defined in `orchestrator/arbitration_machine_learning_jobs.py` using config `arbitration_machine_learning_connection.json`) processes North America email channel engagement data. It creates an ephemeral Dataproc cluster, sequentially runs six Spark jobs to compute BG-CG mapping, sends, opens, clicks, unsubscribes, and orders data, writes results to Hive, and then deletes the cluster. This pipeline feeds the downstream NA email ML feature pipeline.

## Trigger

- **Type**: manual / external orchestration
- **Source**: Cloud Composer Airflow scheduler (DAG ID `cas-arbitration-machine-learning-connection-jobs`); all DAGs have `schedule_interval=None` and `is_paused_upon_creation=True`
- **Frequency**: On-demand; triggered externally as part of the daily ML pipeline cadence

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Composer (Airflow) | Schedules and triggers DAG execution | `gcpCloudComposer` |
| CAS Data Pipeline DAGs | Orchestrates cluster lifecycle and Spark job submission | `continuumCasDataPipelineDags` |
| GCP Dataproc cluster `na-email-data-pipeline-cluster` | Executes Spark jobs | `gcpDataprocCluster` |
| CAS Spark Batch Jobs assembly JAR | Runs all six Spark job main classes | `continuumCasSparkBatchJobs` |
| Hive Warehouse | Stores raw engagement data and intermediate results | `hiveWarehouse` |

## Steps

1. **Start**: Dummy operator marks DAG start.
   - From: `continuumCasDataPipelineDags` (Airflow)
   - To: `start` dummy task
   - Protocol: Airflow task dependency

2. **Create Dataproc cluster**: `DataprocCreateClusterOperator` creates cluster `na-email-data-pipeline-cluster` with 1 master + N workers (n1-standard-8, 500 GB pd-standard, image `1.5-debian10`).
   - From: `continuumCasDataPipelineDags`
   - To: `gcpDataprocCluster`
   - Protocol: GCP Dataproc REST API

3. **NA Email BG-CG Mapping job**: `DataprocSubmitJobOperator` submits `com.groupon.arbitration.data.na.email.NaEmailBgCgMapping`; args: `--shufflePartitions 200 --startDate <ds-1>`; driver 8 GB, executor 15 GB × 2 cores × 200 instances.
   - From: `gcpDataprocCluster`
   - To: `hiveWarehouse`
   - Protocol: Spark / Hive

4. **NA Email Sends job**: Submits `com.groupon.arbitration.data.na.email.NaEmailSends`; reads raw send events and writes aggregated send data to Hive; same Spark resource config as step 3.
   - From: `gcpDataprocCluster`
   - To: `hiveWarehouse`
   - Protocol: Spark / Hive

5. **NA Email Opens job**: Submits `com.groupon.arbitration.data.na.email.NaEmailOpens`; writes email open event data to Hive.
   - From: `gcpDataprocCluster`
   - To: `hiveWarehouse`
   - Protocol: Spark / Hive

6. **NA Email Clicks job**: Submits `com.groupon.arbitration.data.na.email.NaEmailClicks`; writes email click event data to Hive.
   - From: `gcpDataprocCluster`
   - To: `hiveWarehouse`
   - Protocol: Spark / Hive

7. **NA Email Unsubscribe job**: Submits `com.groupon.arbitration.data.na.email.NaEmailUnsubscribe`; writes unsubscribe event data to Hive.
   - From: `gcpDataprocCluster`
   - To: `hiveWarehouse`
   - Protocol: Spark / Hive

8. **NA Email Orders job**: Submits `com.groupon.arbitration.data.na.email.NaEmailOrders`; writes order event data to Hive.
   - From: `gcpDataprocCluster`
   - To: `hiveWarehouse`
   - Protocol: Spark / Hive

9. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` tears down `na-email-data-pipeline-cluster`.
   - From: `continuumCasDataPipelineDags`
   - To: `gcpDataprocCluster`
   - Protocol: GCP Dataproc REST API

10. **End**: Dummy operator marks DAG completion.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Spark job fails (OOM, Hive error) | `retries=0`; Airflow marks task `FAILED`; DAG run stops | Cluster may remain running; manual cleanup required |
| Cluster creation fails | `DataprocCreateClusterOperator` raises exception; DAG fails before any Spark jobs run | No data written; safe to re-trigger |
| Downstream step fails | Earlier Hive writes are preserved; partial pipeline state in Hive | Re-clear failed task from that step onwards in Airflow UI |

## Sequence Diagram

```
CloudComposer -> CasDataPipelineDAGs: Trigger DAG run
CasDataPipelineDAGs -> GCPDataproc: DataprocCreateClusterOperator (na-email-data-pipeline-cluster)
CasDataPipelineDAGs -> GCPDataproc: Submit NaEmailBgCgMapping (spark_job)
GCPDataproc -> HiveWarehouse: Write BG-CG mapping table
CasDataPipelineDAGs -> GCPDataproc: Submit NaEmailSends
GCPDataproc -> HiveWarehouse: Write NA email sends
CasDataPipelineDAGs -> GCPDataproc: Submit NaEmailOpens
GCPDataproc -> HiveWarehouse: Write NA email opens
CasDataPipelineDAGs -> GCPDataproc: Submit NaEmailClicks
GCPDataproc -> HiveWarehouse: Write NA email clicks
CasDataPipelineDAGs -> GCPDataproc: Submit NaEmailUnsubscribe
GCPDataproc -> HiveWarehouse: Write NA email unsubscribes
CasDataPipelineDAGs -> GCPDataproc: Submit NaEmailOrders
GCPDataproc -> HiveWarehouse: Write NA email orders
CasDataPipelineDAGs -> GCPDataproc: DataprocDeleteClusterOperator
```

## Related

- Architecture dynamic view: `dynamic-continuum-cas-data-pipeline-dags`
- Related flows: [NA Email ML Feature Pipeline](na-email-ml-feature-pipeline.md), [NA Email Arbitration Ranking](na-email-arbitration-ranking.md)
