---
service: "cas-data-pipeline-dags"
title: "NA Email Arbitration Ranking"
generated: "2026-03-03"
type: flow
flow_name: "na-email-arbitration-ranking"
flow_type: batch
trigger: "Manual trigger or external orchestration via Cloud Composer; schedule_interval=None"
participants:
  - "continuumCasDataPipelineDags"
  - "continuumCasSparkBatchJobs"
  - "gcpDataprocCluster"
  - "hiveWarehouse"
  - "arbitrationPostgres"
architecture_ref: "dynamic-continuum-cas-data-pipeline-dags"
---

# NA Email Arbitration Ranking

## Summary

The NA Email Arbitration Ranking flow (`orchestrator/na_email_arbitration_ranking.py`, config `na_email_arbitration_ranking.json`, DAG ID `na_email_arbitration_ranking`) runs the `com.groupon.arbitration.ranking.na.ModelRanking` Spark job with `--platform email`. It creates a Dataproc cluster with idle-delete TTL (1800 seconds), executes the ranking job against the feature tables in Hive, writes the ranked output to `arbitrationPostgres`, and deletes the cluster. This is the final scoring step in the NA email arbitration ML pipeline; its output is consumed by the real-time arbitration-service.

## Trigger

- **Type**: manual / external orchestration
- **Source**: Cloud Composer Airflow scheduler (DAG ID `na_email_arbitration_ranking`); `schedule_interval=None`; typically triggered after the NA Email ML Feature Pipeline completes
- **Frequency**: Daily as part of the CAS ML pipeline cadence

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Composer (Airflow) | Schedules and triggers DAG execution | `gcpCloudComposer` |
| CAS Data Pipeline DAGs | Orchestrates cluster lifecycle and ranking job submission | `continuumCasDataPipelineDags` |
| GCP Dataproc cluster `na-email-arbitration-ranking` | Executes ModelRanking Spark job | `gcpDataprocCluster` |
| CAS Spark Batch Jobs — `ModelRanking` | Reads feature tables from Hive, applies ranking model | `continuumCasSparkBatchJobs` |
| Hive Warehouse | Source of computed ML feature tables | `hiveWarehouse` |
| Arbitration PostgreSQL | Target for ranked scoring output | `arbitrationPostgres` |

## Steps

1. **Create Dataproc cluster**: `DataprocCreateClusterOperator` creates cluster `na-email-arbitration-ranking`; n1-standard-8 master + N workers, image `1.5-debian10`, `http_port_access` enabled, idle-delete TTL 1800 seconds, `service_account_scopes: https://www.googleapis.com/auth/cloud-platform`.
   - From: `continuumCasDataPipelineDags`
   - To: `gcpDataprocCluster`
   - Protocol: GCP Dataproc REST API

2. **NA Email Model Ranking job**: `DataprocSubmitJobOperator` submits `com.groupon.arbitration.ranking.na.ModelRanking`; args: `--platform email`; driver 8 GB, executor 15 GB × 2 cores × 200 instances.
   - Reads ML feature tables from `hiveWarehouse`
   - Applies trained arbitration model to rank deals per user
   - Writes ranking scores to `arbitrationPostgres` via JDBC
   - From: `gcpDataprocCluster`
   - To: `hiveWarehouse` (read), `arbitrationPostgres` (write)
   - Protocol: Spark / Hive (read), JDBC / PostgreSQL (write)

3. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` tears down `na-email-arbitration-ranking` cluster.
   - From: `continuumCasDataPipelineDags`
   - To: `gcpDataprocCluster`
   - Protocol: GCP Dataproc REST API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `ModelRanking` Spark job fails | `retries=0`; Airflow marks task `FAILED`; cluster proceeds to delete step only if task succeeds | Ranking scores not updated in Postgres; arbitration-service uses stale scores until re-run succeeds |
| JDBC write to Postgres fails | Spark job exception; task `FAILED` | Partial write may exist in Postgres; check for partial data and truncate before re-run |
| Cluster idle timeout | Idle-delete TTL (1800 s) removes cluster if Spark job stalls | DAG task times out; cluster cleaned up automatically |

## Sequence Diagram

```
CloudComposer -> CasDataPipelineDAGs: Trigger na_email_arbitration_ranking DAG
CasDataPipelineDAGs -> GCPDataproc: DataprocCreateClusterOperator (na-email-arbitration-ranking)
CasDataPipelineDAGs -> GCPDataproc: Submit ModelRanking (--platform email)
GCPDataproc -> HiveWarehouse: Read NA email feature tables
GCPDataproc -> ArbitrationPostgres: Write ranking scores (JDBC)
CasDataPipelineDAGs -> GCPDataproc: DataprocDeleteClusterOperator
```

## Related

- Architecture dynamic view: `dynamic-continuum-cas-data-pipeline-dags`
- Related flows: [NA Email ML Feature Pipeline](na-email-ml-feature-pipeline.md), [NA Email Data Pipeline](na-email-data-pipeline.md)
