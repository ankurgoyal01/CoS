---
service: "badges-trending-calculator"
title: "Daily Job Restart via Airflow"
generated: "2026-03-03"
type: flow
flow_name: "daily-job-restart"
flow_type: scheduled
trigger: "Airflow DAG cron schedule: 22 3 * * * (03:22 UTC daily)"
participants:
  - "continuumBadgesTrendingCalculator"
architecture_ref: "dynamic-deal-purchase-badge-computation"
---

# Daily Job Restart via Airflow

## Summary

Because Badges Trending Calculator is a long-running Spark Streaming job, it is restarted daily to apply new artifact versions, recover from accumulated state, and combine unconsumed Kafka batches into a fresh processing run. An Apache Airflow DAG (`badges-trending-calculator-job`) running in Google Cloud Composer orchestrates this restart at 03:22 UTC every day by deleting the existing Dataproc cluster, creating a new one with the latest deployment configuration, and submitting the Spark job.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow Cloud Composer DAG `badges-trending-calculator-job`
- **Frequency**: Daily at 03:22 UTC (`cron: "22 3 * * *"`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Apache Airflow (Cloud Composer) | Orchestrator — manages the DAG and task execution | External (GCP Cloud Composer) |
| Google Cloud Dataproc | Compute platform — hosts the Spark YARN cluster | External (GCP) |
| Groupon Artifactory | Artifact registry — serves the latest fat JAR | External |
| Badges Trending Calculator (Spark job) | The compute unit being restarted | `continuumBadgesTrendingCalculator` |

## Steps

1. **DAG triggers at 03:22 UTC**: Airflow Cloud Composer evaluates the cron schedule and starts the `badges-trending-calculator-job` DAG run.
   - From: Airflow scheduler
   - To: DAG execution
   - Protocol: Airflow internal

2. **Delete existing cluster**: `DataprocDeleteClusterOperator` deletes the `badges-trending-calculator` Dataproc cluster in the target GCP project and region. Uses `trigger_rule=ALL_DONE` so it runs even if the previous run's job failed.
   - From: Airflow DAG (`delete_cluster` task)
   - To: GCP Dataproc API
   - Protocol: GCP API (HTTPS)

3. **Create new Dataproc cluster**: `DataprocCreateClusterOperator` creates a fresh cluster from the configuration in `badges_trending_calculator.json`. The initialization action (`load-certificates-with-truststore.sh`) runs at cluster startup to inject TLS certificates from GCP Secret Manager.
   - From: Airflow DAG (`create_dataproc_cluster` task)
   - To: GCP Dataproc API + GCP Secret Manager
   - Protocol: GCP API (HTTPS)

4. **Submit Spark job**: `DataprocSubmitJobOperator` submits the Spark job to the new cluster. The job config specifies:
   - Main class: `com.groupon.BadgeCalculator`
   - JAR: fetched from Artifactory at `{artifact_version}` resolved from the `PIPELINE_ARTIFACT_VERSION` Airflow variable
   - Args: `--shufflePartitions 200 --batch_interval 600 --skipAlert --groupId mds_janus_msk_dev --offsetReset latest`
   - From: Airflow DAG (`spark_job` task)
   - To: GCP Dataproc API → YARN → Spark
   - Protocol: GCP API (HTTPS) / YARN

5. **Spark job initializes**: `BadgeCalculator` starts, reads config from `application_prod.conf`, triggers `GeoServiceTask.triggerScheduler()` (starts the hourly division refresh), and begins consuming from `janus-tier1`.
   - From: Spark driver (`BadgeCalculator`)
   - To: Kafka, Redis, Bhuvan
   - Protocol: Kafka SSL, HTTPS, Redis

6. **DAG ends**: The `end` DummyOperator marks the DAG run complete. The Spark job continues running indefinitely until the next daily restart.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Delete cluster fails | `trigger_rule=ALL_DONE` on create step ensures creation still proceeds | May leave orphaned cluster; creation step will handle it |
| Create cluster fails | Airflow marks DAG run as failed; email alert sent to `coreappsdev@groupon.com` | Job not running; manual intervention required |
| Spark job submission fails | `retries=0` on `DataprocSubmitJobOperator`; DAG fails | Manual trigger of DAG required |
| Spark job crashes mid-run | Not restarted until next daily DAG run (03:22 UTC next day) | Operator can manually trigger DAG to restart earlier |

## Sequence Diagram

```
AirflowScheduler    DataprocAPI    SecretManager    Artifactory    SparkJob
       |                 |               |               |             |
  03:22 UTC              |               |               |             |
       |--delete cluster->|              |               |             |
       |<--cluster deleted|              |               |             |
       |--create cluster->|              |               |             |
       |                  |--fetch certs->|              |             |
       |                  |<--JKS files---|              |             |
       |<--cluster ready--|              |               |             |
       |--submit job----->|              |               |             |
       |                  |--fetch JAR--------------------------->|   |
       |                  |<--assembly JAR------------------------|   |
       |                  |--start Spark job----------------------->  |
       |                  |                               |       running...
```

## Related

- Architecture dynamic view: `dynamic-deal-purchase-badge-computation`
- Related flows: [Deal Purchase Badge Computation](deal-purchase-badge-computation.md)
