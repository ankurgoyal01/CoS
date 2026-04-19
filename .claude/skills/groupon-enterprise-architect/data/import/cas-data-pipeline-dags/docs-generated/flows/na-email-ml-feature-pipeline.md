---
service: "cas-data-pipeline-dags"
title: "NA Email ML Feature Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "na-email-ml-feature-pipeline"
flow_type: batch
trigger: "Manual trigger or external orchestration via Cloud Composer; schedule_interval=None"
participants:
  - "continuumCasDataPipelineDags"
  - "continuumCasSparkBatchJobs"
  - "gcpDataprocCluster"
  - "hiveWarehouse"
architecture_ref: "dynamic-continuum-cas-data-pipeline-dags"
---

# NA Email ML Feature Pipeline

## Summary

The NA Email ML Feature Pipeline (`orchestrator/na_email_feature_ml_jobs.py`, config `arbitration_machine_learning_na_email_feature_pipeline_connection.json`) computes ten machine-learning features required for the NA email arbitration ranking model. It creates a Dataproc cluster, runs ten sequential Spark feature-extraction jobs (user campaign counts, segment campaign counts, user counts, campaign features, campaign group features, business group features, RF segment features, CT segment features, user features, super funnel features), writes all outputs to Hive, and then deletes the cluster. These feature tables are consumed by the model training and ranking steps.

## Trigger

- **Type**: manual / external orchestration
- **Source**: Cloud Composer Airflow scheduler; `schedule_interval=None`; typically triggered after the NA Email Data Pipeline completes
- **Frequency**: Daily as part of the CAS ML pipeline cadence

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Composer (Airflow) | Schedules and triggers DAG execution | `gcpCloudComposer` |
| CAS Data Pipeline DAGs | Orchestrates cluster lifecycle and job submission | `continuumCasDataPipelineDags` |
| GCP Dataproc cluster | Executes Spark feature jobs | `gcpDataprocCluster` |
| CAS Spark Batch Jobs assembly JAR | Runs all ten feature Spark jobs | `continuumCasSparkBatchJobs` |
| Hive Warehouse | Source of raw engagement data; target for feature tables | `hiveWarehouse` |

## Steps

1. **Start**: Dummy operator marks pipeline start.
   - From: `continuumCasDataPipelineDags`
   - To: `start` dummy task
   - Protocol: Airflow task dependency

2. **Create Dataproc cluster**: Creates cluster using `DAG_CONFIG["cluster_config"]`; n1-standard-8 master + N workers, image `1.5-debian10`.
   - From: `continuumCasDataPipelineDags`
   - To: `gcpDataprocCluster`
   - Protocol: GCP Dataproc REST API

3. **NA Email User Campaign Counts**: Submits Spark job; reads raw sends/opens/clicks from Hive; writes per-user campaign count features.
   - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

4. **NA Email Segment Campaign Counts**: Writes segment-level campaign count features.
   - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

5. **NA Email User Counts**: Writes per-user event count features.
   - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

6. **NA Email Campaign Features**: Aggregates campaign-level features from user campaign counts.
   - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

7. **NA Email Campaign Group Features**: Aggregates campaign-group-level features.
   - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

8. **NA Email Business Group Features**: Aggregates business-group-level features.
   - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

9. **NA Email RF Segment Features**: Computes recency-frequency segment features.
   - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

10. **NA Email CT Segment Features**: Computes click-through segment features.
    - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

11. **NA Email User Features**: Assembles per-user feature vector from all prior steps.
    - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

12. **NA Email Super Funnel Features**: Computes super-funnel (cross-stage) features.
    - From: `gcpDataprocCluster` / To: `hiveWarehouse` / Protocol: Spark / Hive

13. **Delete Dataproc cluster**: Tears down cluster after all feature jobs complete.
    - From: `continuumCasDataPipelineDags` / To: `gcpDataprocCluster` / Protocol: GCP Dataproc REST API

14. **End**: Dummy operator marks pipeline completion.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Feature job fails mid-pipeline | `retries=0`; Airflow marks task `FAILED`; subsequent feature steps do not run | Partial feature tables in Hive; downstream ranking DAG should not be triggered until re-run completes |
| Cluster creation fails | DAG fails at create step; no Spark jobs submitted | Safe to re-trigger full DAG run |
| Hive schema evolution | Spark job throws `AnalysisException`; task fails | Check Hive table schema against Spark job expected schema; may require schema migration outside this repo |

## Sequence Diagram

```
CloudComposer -> CasDataPipelineDAGs: Trigger NA Email Feature DAG
CasDataPipelineDAGs -> GCPDataproc: Create cluster
GCPDataproc -> HiveWarehouse: na_email_user_campaign_counts job
GCPDataproc -> HiveWarehouse: na_email_segment_campaign_counts job
GCPDataproc -> HiveWarehouse: na_email_user_counts job
GCPDataproc -> HiveWarehouse: na_email_campaign_features job
GCPDataproc -> HiveWarehouse: na_email_campaign_group_features job
GCPDataproc -> HiveWarehouse: na_email_business_group_features job
GCPDataproc -> HiveWarehouse: na_email_rf_segment_features job
GCPDataproc -> HiveWarehouse: na_email_ct_segment_features job
GCPDataproc -> HiveWarehouse: na_email_user_features job
GCPDataproc -> HiveWarehouse: na_email_super_funnel_features job
CasDataPipelineDAGs -> GCPDataproc: Delete cluster
```

## Related

- Architecture dynamic view: `dynamic-continuum-cas-data-pipeline-dags`
- Related flows: [NA Email Data Pipeline](na-email-data-pipeline.md), [NA Email Arbitration Ranking](na-email-arbitration-ranking.md)
