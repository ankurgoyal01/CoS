---
service: "mis-data-pipelines-dags"
title: "MDS Backfill Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "mds-backfill-pipeline"
flow_type: scheduled
trigger: "Cron: 0 2,14,18 * * * (three times daily at 02:00, 14:00, 18:00 UTC)"
participants:
  - "misDags_dagOrchestrator"
  - "misDags_dataprocJobConfig"
  - "edw"
  - "cloudPlatform"
  - "loggingStack"
architecture_ref: "dynamic-mis-dags-core-flow"
---

# MDS Backfill Pipeline

## Summary

The MDS Backfill Pipeline is a scheduled Airflow DAG that runs three times daily and detects newly added deals in the `active_deals` Hive table, then enqueues those deal IDs into the Redis queue for processing by the MDS batch worker. This ensures that deals added between Janus streaming cycles are not missed. The pipeline runs on an ephemeral Dataproc cluster (`dataproc-ephemeral-cluster-mds-backfill`) that is created on demand and automatically deleted after 3600 seconds of idle time. It uses the `mds-backfill` Spark assembly jar and reads deal data from Hive via Dataproc Metastore.

## Trigger

- **Type**: schedule
- **Source**: Airflow Scheduler (Cloud Composer)
- **Frequency**: Three times daily — `0 2,14,18 * * *` (02:00, 14:00, 18:00 UTC)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Orchestrator | Creates Backfill Dataproc cluster and submits Spark job | `misDags_dagOrchestrator` |
| Dataproc Job Config | Provides cluster and job parameters from `mds_backfill_job_config.json` | `misDags_dataprocJobConfig` |
| Enterprise Data Warehouse (Hive) | Source of `active_deals` Hive table data | `edw` |
| GCP Cloud Platform (Dataproc) | Ephemeral cluster `dataproc-ephemeral-cluster-mds-backfill` running Spark job | `cloudPlatform` |
| Logging Stack | Receives Spark driver, executor, and YARN logs via Stackdriver | `loggingStack` |

## Steps

1. **Load Backfill Job Config**: DAG Orchestrator reads `orchestrator/config/{env}/mds_backfill_job_config.json` to get cluster name, machine types (1 master + 2 workers, `e2-standard-8`, 500GB boot disk), idle TTL (3600s), and Spark job parameters.
   - From: `misDags_dagOrchestrator`
   - To: `misDags_dataprocJobConfig`
   - Protocol: File I/O

2. **Create Backfill Dataproc Cluster**: DAG Orchestrator provisions ephemeral cluster `dataproc-ephemeral-cluster-mds-backfill` in GCP project `prj-grp-mktg-eng-prod-e034`, region `us-central1`, zone `us-central1-f`. Cluster image `1.5.69-debian10` with Anaconda/Jupyter optional components; connected to Metastore `grpn-dpms-prod-analytics`.
   - From: `misDags_dagOrchestrator`
   - To: `cloudPlatform` (GCP Dataproc API)
   - Protocol: GCP REST API

3. **Submit Backfill Spark Job**: DAG Orchestrator submits the backfill job using `DataprocSubmitJobOperator`. Main class: `com.groupon.mds.backfill.jobs.BackFillJob`. JAR: `mds-backfill_2-4-8_2.12-1.0.4-assembly.jar` from Artifactory, plus `json-serde` and `json-udf` JARs from GCS. Spark config: 6 executor instances, 4 cores each, 10g memory (with 1g overhead), KryoSerializer, adaptive SQL enabled, dynamic allocation disabled.
   - From: `misDags_dagOrchestrator`
   - To: `cloudPlatform` (Dataproc Spark job submission)
   - Protocol: GCP Dataproc Jobs API

4. **Read Active Deals from Hive**: Backfill Spark job queries the `active_deals` Hive table via Dataproc Metastore to identify deal IDs that have been newly added since the last backfill run.
   - From: `cloudPlatform` (Backfill Spark job)
   - To: `edw` (Hive via Metastore `grpn-dpms-prod-analytics`)
   - Protocol: Hive SQL / Spark SQL

5. **Enqueue New Deal IDs to Redis**: Backfill Spark job writes the newly identified deal IDs to the Redis queue for asynchronous batch processing. Redis ownership is external to this service.
   - From: `cloudPlatform` (Backfill Spark job)
   - To: Redis (external batch worker queue)
   - Protocol: Redis protocol

6. **Emit Execution Logs**: Spark driver, executor, and YARN container logs forwarded to Stackdriver Logging.
   - From: `cloudPlatform`
   - To: `loggingStack`
   - Protocol: Stackdriver Logging API

7. **Cluster Auto-Delete**: Cluster automatically deletes after 3600 seconds of idle time to avoid unnecessary GCP compute costs.
   - From: `cloudPlatform`
   - To: `cloudPlatform`
   - Protocol: GCP Dataproc lifecycle management

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hive query fails (Metastore unavailable) | Spark job exits; Airflow task marked failed | No deal IDs enqueued; Backfill job must be re-triggered manually |
| Spark job OOM (executor memory) | JVM GC with `-XX:+UseConcMarkSweepGC`; executor restart by YARN | Possible partial backfill; recommend re-triggering the DAG |
| Redis unavailable | Spark job exits; Airflow task marked failed | Deal IDs not enqueued; Janus streaming remains the primary ingestion path |
| Dataproc cluster creation fails | Airflow task fails | DAG run marked failed; next scheduled run at 02:00/14:00/18:00 will retry |

## Sequence Diagram

```
Airflow Scheduler -> misDags_dagOrchestrator: Trigger backfill DAG (cron 0 2,14,18 * * *)
misDags_dagOrchestrator -> misDags_dataprocJobConfig: Read mds_backfill_job_config.json
misDags_dagOrchestrator -> cloudPlatform: Create Dataproc cluster (dataproc-ephemeral-cluster-mds-backfill)
misDags_dagOrchestrator -> cloudPlatform: Submit Spark job (mds-backfill_2-4-8_2.12-1.0.4-assembly.jar)
cloudPlatform -> edw: Query active_deals Hive table for new deal IDs
edw --> cloudPlatform: New deal IDs
cloudPlatform -> Redis: Enqueue new deal IDs for batch worker
cloudPlatform -> loggingStack: Forward Spark and YARN logs
cloudPlatform -> cloudPlatform: Auto-delete cluster after 3600s idle
```

## Related

- Architecture dynamic view: `dynamic-mis-dags-core-flow`
- Related flows: [Janus Kafka Streaming](janus-kafka-streaming.md), [MDS Archival Pipeline](mds-archival-pipeline.md)
