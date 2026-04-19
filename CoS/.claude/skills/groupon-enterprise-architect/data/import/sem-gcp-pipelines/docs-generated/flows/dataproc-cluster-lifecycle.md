---
service: "sem-gcp-pipelines"
title: "Dataproc Cluster Lifecycle"
generated: "2026-03-03"
type: flow
flow_name: "dataproc-cluster-lifecycle"
flow_type: batch
trigger: "Airflow DAG run start — initiated by schedule or manual trigger"
participants:
  - "continuumSemGcpPipelinesComposer"
  - "gcpDataprocCluster_469e25"
  - "gcsDagsBucket_c78c51"
  - "gcsArtifactsBucket_aedc8c"
  - "gcpSecretManager_cc4b72"
architecture_ref: "dynamic-semGcpPipelinesDataprocLifecycle"
---

# Dataproc Cluster Lifecycle

## Summary

Every pipeline DAG in sem-gcp-pipelines (facebook, geo-cat, DSA, google-places, css-affiliates, google-appointment) follows the same cluster lifecycle pattern: create an ephemeral Dataproc cluster, load secrets, submit the Spark job, and delete the cluster on completion. This pattern ensures clean, isolated compute for each pipeline run and eliminates persistent cluster costs. Clusters are tagged with `service: sem-gcp-pipelines` and `owner: sem-devs` for cost allocation.

## Trigger

- **Type**: schedule (or manual)
- **Source**: Airflow Composer scheduler, based on per-pipeline `schedule_interval` cron expression in `global_variables_{env}.yml`
- **Frequency**: Varies by pipeline — from multiple times daily (Facebook: 4x daily) to once daily (Google Places, CSS Affiliates)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Composer | Orchestrates DAG tasks in sequence | `continuumSemGcpPipelinesComposer` |
| GCP Dataproc | Ephemeral compute cluster for Spark execution | `gcpDataprocCluster_469e25` |
| GCS Artifacts Bucket | Hosts init scripts and versioned job ZIP artifacts | `gcsArtifactsBucket_aedc8c` |
| GCS Data Bucket | Source and sink for pipeline data | `gcsDataBucket_a28d89` |
| GCP Secret Manager | Stores credentials for the Spark job | `gcpSecretManager_cc4b72` |

## Steps

1. **DAG Triggered**: Airflow scheduler fires the DAG based on `schedule_interval` (or operator clicks "Trigger DAG").
   - From: `continuumSemGcpPipelinesComposer` (Airflow scheduler)
   - To: DAG run created

2. **Create Dataproc Cluster**: `DataprocCreateClusterOperator` provisions an ephemeral cluster.
   - From: `continuumSemGcpPipelinesComposer`
   - To: `gcpDataprocCluster_469e25`
   - Protocol: GCP Dataproc API
   - Cluster config: `n1-highmem-4` master, image `1.5-debian10`, zone `us-central1-f`, internal IP only
   - Init script: `{common_bucket}/init/load-artifacts.sh` downloads the versioned ZIP artifact from Artifactory into the cluster
   - Metadata: `artifact_urls` set to `/com/groupon/transam/sem-gcp-pipelines/{VERSION}/sem-gcp-pipelines-{VERSION}.zip`

3. **Load Secrets**: `DataprocSubmitJobOperator` submits a Pig job to fetch credentials.
   - From: `continuumSemGcpPipelinesComposer`
   - To: `gcpDataprocCluster_469e25`
   - Protocol: GCP Dataproc Job API (Pig)
   - Action: `gcloud secrets versions access latest --secret=sem_common_jobs > /tmp/credentials`
   - Credentials source: `gcpSecretManager_cc4b72` (project `prj-grp-c-common-prod-ff2b`)

4. **Submit Spark Job**: `DataprocSubmitJobOperator` runs the pipeline-specific Spark job.
   - From: `continuumSemGcpPipelinesComposer`
   - To: `gcpDataprocCluster_469e25`
   - Protocol: GCP Dataproc Job API (Spark)
   - JAR: `gs://grpn-dnd-prod-analytics-grp-sem-group/user/grp_gdoop_sem_group/jars/sem-common-jobs-2.132.jar`
   - Main class: `com.groupon.transam.CommonJob`
   - Args: `-e {env} -c {countries} -cl {job_class}`
   - Deploy mode: `cluster`

5. **Delete Dataproc Cluster**: `DataprocDeleteClusterOperator` tears down the cluster.
   - From: `continuumSemGcpPipelinesComposer`
   - To: `gcpDataprocCluster_469e25`
   - Protocol: GCP Dataproc API
   - Executed whether the Spark job succeeds or fails (task dependency: always runs after `spark_process`)

6. **Callbacks**: On success, `resolve_event` is called (clears PagerDuty alert). On failure, `trigger_event` fires a PagerDuty alert.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cluster creation fails (quota, network) | Airflow task fails; no retry configured for cluster creation | DAG run marked failed; PagerDuty alert triggered |
| Load secrets fails | Airflow task fails; 0 retries | Cluster is not deleted (downstream tasks don't run); manual cleanup may be needed |
| Spark job fails | Airflow task fails; 0 retries (most pipelines) | `delete_cluster_operator` still runs; cluster cleaned up; PagerDuty alert |
| Cluster stuck idle | `idle_delete_ttl: 1800s` auto-deletes cluster | GCP cleans up automatically after 30 min idle |

## Sequence Diagram

```
Scheduler      -> Composer: Fire DAG based on schedule_interval
Composer       -> Dataproc API: DataprocCreateClusterOperator (cluster_name, cluster_config)
Dataproc API   -> Cluster: Provision n1-highmem-4 master; run load-artifacts.sh init
Cluster        -> Artifactory: Download sem-gcp-pipelines-{VERSION}.zip
Composer       -> Dataproc API: DataprocSubmitJobOperator (pig_job: gcloud secrets access)
Cluster        -> SecretManager: gcloud secrets versions access latest --secret=sem_common_jobs
SecretManager  -> Cluster: Return credential bundle → /tmp/credentials
Composer       -> Dataproc API: DataprocSubmitJobOperator (spark_job: CommonJob)
Cluster        -> GCS: Read input data / write output data
Cluster        -> AdPlatform: Deliver feed output
Composer       -> Dataproc API: DataprocDeleteClusterOperator
Dataproc API   --> Composer: Cluster deleted
```

## Related

- Architecture dynamic view: `dynamic-semGcpPipelinesDataprocLifecycle`
- Related flows: [Facebook Feed Generation](facebook-feed-generation.md), [Google Places Feed](google-places-feed.md), [CSS Affiliates Feed](css-affiliates-feed.md)
