---
service: "cas-data-pipeline-dags"
title: "NA Mobile Data Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "na-mobile-data-pipeline"
flow_type: batch
trigger: "Manual trigger or external orchestration via Cloud Composer; schedule_interval=None"
participants:
  - "continuumCasDataPipelineDags"
  - "continuumCasSparkBatchJobs"
  - "gcpDataprocCluster"
  - "hiveWarehouse"
architecture_ref: "dynamic-continuum-cas-data-pipeline-dags"
---

# NA Mobile Data Pipeline

## Summary

The NA Mobile Data Pipeline DAG (`orchestrator/na_mobile_data_pipeline_job.py`, config `na_mobile_data_pipeline.json`, DAG ID `na-mobile-data-job`) processes North America mobile push channel engagement data. It creates a Dataproc cluster (`na-mobile-data-pipeline-cluster`), sequentially submits five Spark jobs (BG-CG mapping, sends, clicks, orders, aggregation), writes all outputs to Hive, and deletes the cluster. The resulting Hive tables feed the NA mobile upload and STO pipelines that write scores to `arbitrationPostgres`.

## Trigger

- **Type**: manual / external orchestration
- **Source**: Cloud Composer Airflow scheduler (DAG ID `na-mobile-data-job`); `schedule_interval=None`
- **Frequency**: Daily as part of the CAS mobile ML pipeline cadence

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Composer (Airflow) | Schedules and triggers DAG execution | `gcpCloudComposer` |
| CAS Data Pipeline DAGs | Orchestrates cluster lifecycle and Spark job submission | `continuumCasDataPipelineDags` |
| GCP Dataproc cluster `na-mobile-data-pipeline-cluster` | Executes mobile data Spark jobs | `gcpDataprocCluster` |
| CAS Spark Batch Jobs assembly JAR | Runs all five mobile data Spark jobs | `continuumCasSparkBatchJobs` |
| Hive Warehouse | Source of raw mobile engagement data; target for processed tables | `hiveWarehouse` |

## Steps

1. **Start**: Dummy operator marks DAG start.
   - From: `continuumCasDataPipelineDags` / To: `start` dummy task / Protocol: Airflow task dependency

2. **Create Dataproc cluster**: `DataprocCreateClusterOperator` creates `na-mobile-data-pipeline-cluster`; n1-standard-8 master + N workers, image `1.5-debian10`.
   - From: `continuumCasDataPipelineDags` / To: `gcpDataprocCluster` / Protocol: GCP Dataproc REST API

3. **NA Mobile BG-CG Mapping job**: Submits `com.groupon.arbitration.data.na.mobile.NaMobileBgCgMapping`; args: `--shufflePartitions 200 --startDate=20230122`; driver 8 GB, executor 20 GB × 4 cores × 200 instances; writes BG-CG mapping to Hive.
   - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

4. **NA Mobile Sends job**: Submits `com.groupon.arbitration.data.na.mobile.NaMobileSends`; writes aggregated mobile send events to Hive.
   - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

5. **NA Mobile Clicks job**: Submits `com.groupon.arbitration.data.na.mobile.NaMobileClicks`; writes mobile click events to Hive.
   - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

6. **NA Mobile Orders job**: Submits `com.groupon.arbitration.data.na.mobile.NaMobileOrders`; writes mobile order events to Hive.
   - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

7. **NA Mobile Aggregation job**: Submits `com.groupon.arbitration.data.na.mobile.NaMobileAggregation`; aggregates all mobile engagement signals into summary feature tables in Hive.
   - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

8. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` tears down `na-mobile-data-pipeline-cluster`.
   - From: `continuumCasDataPipelineDags` / To: `gcpDataprocCluster` / Protocol: GCP Dataproc REST API

9. **End**: Dummy operator marks DAG completion.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Spark job fails (OOM or Hive error) | `retries=0`; Airflow marks task `FAILED`; subsequent steps do not run | Partial Hive writes; downstream upload/STO DAGs should not be triggered until re-run completes |
| Cluster creation fails | DAG fails at create step; no Spark jobs submitted | Safe to re-trigger full DAG run |

## Sequence Diagram

```
CloudComposer -> CasDataPipelineDAGs: Trigger na-mobile-data-job DAG
CasDataPipelineDAGs -> GCPDataproc: Create cluster na-mobile-data-pipeline-cluster
GCPDataproc -> HiveWarehouse: NaMobileBgCgMapping job
GCPDataproc -> HiveWarehouse: NaMobileSends job
GCPDataproc -> HiveWarehouse: NaMobileClicks job
GCPDataproc -> HiveWarehouse: NaMobileOrders job
GCPDataproc -> HiveWarehouse: NaMobileAggregation job
CasDataPipelineDAGs -> GCPDataproc: Delete cluster
```

## Related

- Architecture dynamic view: `dynamic-continuum-cas-data-pipeline-dags`
- Related flows: [Arbitration Reporting Pipeline](arbitration-reporting-pipeline.md)
