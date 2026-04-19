---
service: "sem-gcp-pipelines"
title: "Facebook Feed Generation"
generated: "2026-03-03"
type: flow
flow_name: "facebook-feed-generation"
flow_type: scheduled
trigger: "Cron schedule — multiple times daily per country (Location: 4x daily; Display: 3x daily)"
participants:
  - "continuumSemGcpPipelinesComposer"
  - "gcpDataprocCluster_469e25"
  - "gcpSecretManager_cc4b72"
  - "facebookAds"
architecture_ref: "dynamic-semGcpPipelinesFacebookFeed"
---

# Facebook Feed Generation

## Summary

The Facebook Feed Generation flow orchestrates the creation and delivery of two types of Facebook advertising feeds: Location feeds (5 countries: US, DE, AU, PL, ES — run 4x daily at 05:14/11:14/17:14/22:14 UTC) and Display feeds (13 countries: US, CA, UK, DE, FR, IT, NL, BE, IE, ES, AU, PL, AE — run 3x daily at 05:00/16:00/20:00 UTC). Each country has its own Airflow DAG with a staggered cron schedule to prevent cluster resource contention. All Facebook feed processing is handled by the `sem-common-jobs` Java Spark job (`FaceBookLocationProcessor` / `FacebookDisplayProcessor`) running on an ephemeral Dataproc cluster.

## Trigger

- **Type**: schedule
- **Source**: Airflow Composer scheduler
- **Frequency**:
  - Facebook Location (US, DE, AU, PL, ES): `'14 5,11,17,22 * * *'` through `'18 5,11,17,22 * * *'` (staggered by 1 min per country, 4x daily)
  - Facebook Display (13 countries): `'1 5,16,20 * * *'` through `'13 5,16,20 * * *'` (staggered by 1 min per country, 3x daily)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Composer | Schedules per-country DAGs and monitors task execution | `continuumSemGcpPipelinesComposer` |
| GCP Dataproc | Ephemeral cluster running the Facebook feed Spark job | `gcpDataprocCluster_469e25` |
| GCP Secret Manager | Provides `sem_common_jobs` credentials at job startup | `gcpSecretManager_cc4b72` |
| Facebook Ads | Receives the generated location / display feed data | `facebookAds` |

## Steps

1. **DAG Triggered by Schedule**: Airflow fires the per-country Facebook DAG at the configured cron time.
   - From: `continuumSemGcpPipelinesComposer`
   - To: DAG run started (e.g., `facebook-location-us`, `facebook-display-de`)

2. **Create Dataproc Cluster**: `DataprocCreateClusterOperator` provisions the ephemeral cluster.
   - From: `continuumSemGcpPipelinesComposer`
   - To: `gcpDataprocCluster_469e25`
   - Protocol: GCP Dataproc API
   - Labels: `service: sem-gcp-pipelines`, `owner: sem-devs`, `pipeline: {dag_id}`

3. **Load Secrets**: Pig job step fetches `sem_common_jobs` secret from GCP Secret Manager.
   - From: `gcpDataprocCluster_469e25`
   - To: `gcpSecretManager_cc4b72`
   - Protocol: gcloud CLI
   - Output: credentials written to `/tmp/credentials` on cluster

4. **Submit Facebook Spark Job**: `DataprocSubmitJobOperator` submits the `CommonJob` Spark job.
   - From: `continuumSemGcpPipelinesComposer`
   - To: `gcpDataprocCluster_469e25`
   - Protocol: GCP Dataproc Job API (Spark)
   - JAR: `gs://grpn-dnd-prod-analytics-grp-sem-group/user/grp_gdoop_sem_group/jars/sem-common-jobs-2.132.jar`
   - Main class: `com.groupon.transam.CommonJob`
   - For Location feeds — job class: `com.groupon.transam.spark.facebook.location.FaceBookLocationProcessor`
   - For Display feeds — job class: `com.groupon.transam.spark.facebook.display.FacebookDisplayProcessor`
   - Args: `-e {env} -c {country} -cl {job_class}`
   - The Spark job reads deal/merchant data from GCS, processes it, and delivers the feed to Facebook Ads

5. **Deliver Feed to Facebook Ads**: The Spark job uploads the generated feed to Facebook Ads platform.
   - From: `gcpDataprocCluster_469e25`
   - To: `facebookAds`
   - Protocol: Facebook Ads API (managed inside `sem-common-jobs` JAR)

6. **Delete Dataproc Cluster**: Airflow tears down the ephemeral cluster.
   - From: `continuumSemGcpPipelinesComposer`
   - To: `gcpDataprocCluster_469e25`
   - Protocol: GCP Dataproc API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cluster creation fails | Airflow task fails; 0 retries | PagerDuty alert; feed not delivered for this country/cycle |
| Secrets loading fails | Pig task fails; Spark job not submitted | Cluster may need manual cleanup; PagerDuty alert |
| Spark job fails (Facebook API error) | 0 retries; task fails | PagerDuty alert; cluster deleted; feed not delivered |
| Facebook API rate limit / timeout | Managed inside `sem-common-jobs` JAR | Job may fail; next scheduled run covers the missed delivery |

## Sequence Diagram

```
Scheduler        -> Composer: Trigger facebook-{type}-{country} DAG
Composer         -> DataprocAPI: DataprocCreateClusterOperator
DataprocAPI      -> Cluster: Provision + init (download sem-gcp-pipelines artifact)
Cluster          -> SecretManager: gcloud secrets access (sem_common_jobs) → /tmp/credentials
Composer         -> DataprocAPI: DataprocSubmitJobOperator (spark_job, CommonJob, FaceBook*Processor)
Cluster          -> GCS: Read deal/merchant data for {country}
Cluster          -> FacebookAds: Upload generated Location/Display feed
FacebookAds      --> Cluster: Delivery acknowledgement
Composer         -> DataprocAPI: DataprocDeleteClusterOperator
```

## Related

- Architecture dynamic view: `dynamic-semGcpPipelinesFacebookFeed`
- Related flows: [Dataproc Cluster Lifecycle](dataproc-cluster-lifecycle.md), [CSS Affiliates Feed](css-affiliates-feed.md)
