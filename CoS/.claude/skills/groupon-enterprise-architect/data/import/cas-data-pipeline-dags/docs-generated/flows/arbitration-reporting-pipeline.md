---
service: "cas-data-pipeline-dags"
title: "Arbitration Reporting Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "arbitration-reporting-pipeline"
flow_type: batch
trigger: "Manual trigger or external orchestration via Cloud Composer; schedule_interval=None"
participants:
  - "continuumCasDataPipelineDags"
  - "continuumCasSparkBatchJobs"
  - "gcpDataprocCluster"
  - "hiveWarehouse"
architecture_ref: "dynamic-continuum-cas-data-pipeline-dags"
---

# Arbitration Reporting Pipeline

## Summary

The Arbitration Reporting Pipeline runs the `com.groupon.datatransformation.MainLogToCerebro` Spark job to transform arbitration log data into reporting-ready outputs for both NA and EMEA regions. Two DAG files manage this: `orchestrator/na_arbitration_reporting_pipeline.py` (config `na_bestfor_reporting_pipeline.json`, DAG ID `arbitration-na-reporting-pipeline-jobs`) and `orchestrator/emea_arbitration_reporting_pipeline.py` (config `emea_bestfor_reporting_pipeline.json`). Each creates a cluster, runs a single reporting Spark job, writes outputs to Hive, and deletes the cluster. The reporting jobs use fewer resources (50 executor instances) compared to ML pipelines.

## Trigger

- **Type**: manual / external orchestration
- **Source**: Cloud Composer Airflow scheduler (DAG IDs `arbitration-na-reporting-pipeline-jobs` and EMEA equivalent); `schedule_interval=None`
- **Frequency**: Daily as part of the CAS reporting cadence

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Composer (Airflow) | Schedules and triggers DAG execution | `gcpCloudComposer` |
| CAS Data Pipeline DAGs | Orchestrates cluster lifecycle and reporting job submission | `continuumCasDataPipelineDags` |
| GCP Dataproc cluster `arbitration-reporting-pipeline` | Executes MainLogToCerebro Spark job | `gcpDataprocCluster` |
| CAS Spark Batch Jobs — `MainLogToCerebro` | Transforms arbitration log data into reporting schemas | `continuumCasSparkBatchJobs` |
| Hive Warehouse | Source of arbitration log data; target for reporting output | `hiveWarehouse` |

## Steps

1. **Start**: Dummy operator marks DAG start.
   - From: `continuumCasDataPipelineDags` / To: `start` dummy task / Protocol: Airflow task dependency

2. **Create Dataproc cluster**: `DataprocCreateClusterOperator` creates cluster `arbitration-reporting-pipeline`; n1-standard-8 master + N workers, image `1.5-debian10`.
   - From: `continuumCasDataPipelineDags` / To: `gcpDataprocCluster` / Protocol: GCP Dataproc REST API

3. **Reporting job** (`na_reporting_job` or `emea_reporting_job`): Submits `com.groupon.datatransformation.MainLogToCerebro`; args: `--shufflePartitions 200 --region=na` (or `--region=emea`); driver 1 GB, executor 20 GB × 4 cores × 50 instances. Reads arbitration log data from Hive and writes reporting-ready output back to Hive.
   - From: `gcpDataprocCluster`
   - To: `hiveWarehouse`
   - Protocol: Spark / Hive

4. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` tears down reporting cluster.
   - From: `continuumCasDataPipelineDags` / To: `gcpDataprocCluster` / Protocol: GCP Dataproc REST API

5. **End**: Dummy operator marks DAG completion.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Reporting Spark job fails | `retries=0`; Airflow marks task `FAILED` | Reporting output not refreshed; downstream dashboards/BI tools see stale data |
| Cluster creation fails | DAG fails at create step; no Spark jobs submitted | Safe to re-trigger full DAG run |

## Sequence Diagram

```
CloudComposer -> CasDataPipelineDAGs: Trigger arbitration-reporting-pipeline DAG (NA or EMEA)
CasDataPipelineDAGs -> GCPDataproc: Create cluster arbitration-reporting-pipeline
CasDataPipelineDAGs -> GCPDataproc: Submit MainLogToCerebro (--region=na or --region=emea)
GCPDataproc -> HiveWarehouse: Read arbitration log data
GCPDataproc -> HiveWarehouse: Write reporting output tables
CasDataPipelineDAGs -> GCPDataproc: Delete cluster
```

## Related

- Architecture dynamic view: `dynamic-continuum-cas-data-pipeline-dags`
- Related flows: [NA Email Data Pipeline](na-email-data-pipeline.md), [NA Mobile Data Pipeline](na-mobile-data-pipeline.md)
