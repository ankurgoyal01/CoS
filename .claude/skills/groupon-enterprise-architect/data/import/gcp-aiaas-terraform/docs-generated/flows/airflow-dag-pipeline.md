---
service: "gcp-aiaas-terraform"
title: "Airflow DAG Orchestrated Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "airflow-dag-pipeline"
flow_type: batch
trigger: "Airflow DAG scheduled trigger or manual activation in Cloud Composer"
participants:
  - "continuumComposer"
  - "continuumStorageBuckets"
  - "continuumBigQuery"
architecture_ref: "containers-gcp-aiaas"
---

# Airflow DAG Orchestrated Pipeline

## Summary

GCP Cloud Composer (managed Apache Airflow 2.6.3) orchestrates multi-step data and ML pipelines via DAGs stored in GCS. When a DAG runs, the scheduler picks up tasks defined in Python DAG files, executes operators sequentially or in parallel according to task dependencies, reads pipeline input data from Cloud Storage and BigQuery, may spin up ephemeral Dataproc clusters for large-scale Spark processing, and writes results back to BigQuery or Cloud Storage. This pattern is used for batch ETL, model preprocessing, and offline ML evaluation workflows.

## Trigger

- **Type**: schedule or manual
- **Source**: Airflow DAG schedule expression (defined within the DAG Python file) or manual trigger via Airflow UI / Airflow REST API
- **Frequency**: Varies by DAG (daily, weekly, or on-demand; all DAGs are paused at creation — `dags_are_paused_at_creation = True`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Composer (Airflow) | Schedules, sequences, and monitors all DAG tasks | `continuumComposer` |
| Cloud Storage Buckets | Stores DAG Python files (input); stores pipeline artefacts (input/output) | `continuumStorageBuckets` |
| BigQuery | Source of structured input data and sink for pipeline results | `continuumBigQuery` |
| Dataproc (ephemeral) | Runs Spark-based ETL/SQL jobs when large-scale processing is needed (orchestrated by Airflow) | Not in DSL model — provisioned ephemerally by DAG |

## Steps

1. **Loads DAG definition**: Airflow scheduler reads the DAG Python file from the GCS DAGs bucket (configured as the Composer environment's DAGs bucket).
   - From: `continuumComposer`
   - To: `continuumStorageBuckets`
   - Protocol: GCP SDK (GCS read)

2. **Evaluates schedule / receives trigger**: Airflow scheduler evaluates the DAG's cron schedule or processes a manual trigger; queues the DAG run and individual tasks.
   - From: `continuumComposer` (scheduler)
   - To: `continuumComposer` (executor)
   - Protocol: Internal Airflow

3. **Reads pipeline input data**: An Airflow task reads input data from GCS (`data_bucket`) or BigQuery (`merchant_data_center` dataset) into the processing context.
   - From: `continuumComposer`
   - To: `continuumStorageBuckets` / `continuumBigQuery`
   - Protocol: GCP SDK (Airflow GCS/BigQuery operators)

4. **Submits Dataproc job (optional)**: For large-scale Spark processing, the DAG spawns an ephemeral Dataproc cluster (up to 25 workers, default 10), submits a Spark SQL job, and waits for completion.
   - From: `continuumComposer`
   - To: Dataproc (ephemeral, GCP DataprocOperator)
   - Protocol: GCP SDK (Airflow DataprocOperator)

5. **Writes results to BigQuery**: After processing, an Airflow task writes final results to the `merchant_data_center` BigQuery dataset.
   - From: `continuumComposer`
   - To: `continuumBigQuery`
   - Protocol: GCP SDK (Airflow BigQueryOperator)

6. **Writes artefacts to Cloud Storage**: Intermediate and final pipeline artefacts (model inputs, serialised objects) are written to GCS (`data_bucket` or `models_bucket`).
   - From: `continuumComposer`
   - To: `continuumStorageBuckets`
   - Protocol: GCP SDK (Airflow GCSHook)

7. **Reports task completion**: Airflow marks tasks and the DAG run as `success` or `failed`; task logs are forwarded to the ELK platform index via Filebeat.
   - From: `continuumComposer`
   - To: Airflow scheduler / ELK (log forwarding)
   - Protocol: Internal Airflow / Filebeat

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DAG task fails | Airflow retries per task `retry` configuration; marks task `failed` after retries exhausted | DAG run marked `failed`; alerting via Wavefront / PagerDuty |
| Dataproc bootstrap fails | Task is marked failed; check bootstrap script and CloudCore SCPs | DAG step fails; Dataproc cluster is not created |
| Dataproc Spark query fails | Increase instance count in DAG; check Kibana logs | Dataproc query step fails; DAG retries if configured |
| BigQuery write fails | Task marked failed; Airflow retries | Results not written; manual re-trigger required |
| Airflow scheduler dead | Restart via Terraform destroy + apply | All DAG scheduling halts until scheduler is recovered |

## Sequence Diagram

```
Cloud Composer  -> Cloud Storage      : Load DAG Python file (GCS DAGs bucket)
Cloud Composer  -> Cloud Storage      : Read pipeline input data (data_bucket)
Cloud Composer  -> BigQuery           : Read structured input data (merchant_data_center)
Cloud Composer  -> Dataproc           : Submit Spark job (ephemeral cluster, optional)
Dataproc        --> Cloud Composer    : Job complete / failed
Cloud Composer  -> BigQuery           : Write pipeline results (merchant_data_center)
Cloud Composer  -> Cloud Storage      : Write pipeline artefacts (models_bucket / data_bucket)
```

## Related

- Architecture dynamic view: `containers-gcp-aiaas`
- Airflow dashboard: `https://groupon.wavefront.com/dashboards/dssi-ml-toolkit`
- Dataproc logs: GCS staging bucket `dataproc-staging-us-central1-364685817243-joxbkjlz`
- Related flows: [Scheduled Background Job](scheduled-background-job.md)
