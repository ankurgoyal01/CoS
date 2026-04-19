---
service: "gcp-aiaas-terraform"
title: "Scheduled Background Job via Cloud Scheduler and Cloud Tasks"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-background-job"
flow_type: scheduled
trigger: "Cloud Scheduler cron job fires at 00:00 UTC daily"
participants:
  - "continuumCloudScheduler"
  - "continuumCloudTasks"
  - "continuumCloudRunService"
  - "continuumBigQuery"
  - "continuumStorageBuckets"
architecture_ref: "dynamic-scheduled-workflow"
---

# Scheduled Background Job via Cloud Scheduler and Cloud Tasks

## Summary

On a daily schedule (00:00 UTC), GCP Cloud Scheduler triggers the creation of an item in a GCP Cloud Tasks queue. Cloud Tasks then invokes the `aidg-top-deals` Cloud Run service at the `/top-deals-async` endpoint. The Cloud Run service executes a batch ML job, writes the computed top-deals results to BigQuery, and stores any intermediate artefacts to Cloud Storage. This flow is the primary scheduled batch ML workload pattern for the AIaaS platform and is captured in the Structurizr dynamic view `dynamic-scheduled-workflow`.

## Trigger

- **Type**: schedule
- **Source**: GCP Cloud Scheduler job `aidg-top-deals-async`
- **Frequency**: Daily at 00:00 UTC (`0 0 * * *`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Scheduler | Fires the cron trigger; creates a Cloud Tasks item with OIDC auth | `continuumCloudScheduler` |
| Cloud Tasks | Queues the HTTP task and reliably delivers it to Cloud Run | `continuumCloudTasks` |
| Cloud Run Service (`aidg-top-deals`) | Executes batch ML job at `/top-deals-async` | `continuumCloudRunService` |
| BigQuery | Receives written results from the batch job | `continuumBigQuery` |
| Cloud Storage Buckets | Receives intermediate artefacts stored by the batch job | `continuumStorageBuckets` |

## Steps

1. **Fires daily schedule**: Cloud Scheduler evaluates cron expression `0 0 * * *` (UTC) and fires.
   - From: `continuumCloudScheduler`
   - To: `continuumCloudTasks`
   - Protocol: GCP internal (Cloud Scheduler enqueues task)

2. **Enqueues task**: Cloud Scheduler creates an HTTP task in the Cloud Tasks queue targeting `https://aidg-top-deals-364685817243.us-central1.run.app/top-deals-async`, with an OIDC token generated from the `loc-sa-vertex-ai-pipeline` service account.
   - From: `continuumCloudScheduler`
   - To: `continuumCloudTasks`
   - Protocol: GCP Cloud Tasks API

3. **Invokes Cloud Run via HTTP**: Cloud Tasks delivers the queued HTTP task to the Cloud Run `aidg-top-deals` service at `/top-deals-async`.
   - From: `continuumCloudTasks`
   - To: `continuumCloudRunService`
   - Protocol: HTTPS (OIDC-authenticated)

4. **Executes batch ML job**: The `aidg-top-deals` Cloud Run service processes the top-deals computation (ML inference, ranking, filtering).
   - From: `continuumCloudRunService`
   - To: Internal batch processing (within Cloud Run container)
   - Protocol: Internal

5. **Writes results to BigQuery**: The Cloud Run service writes computed top-deals results to the `merchant_data_center` dataset in BigQuery.
   - From: `continuumCloudRunService`
   - To: `continuumBigQuery`
   - Protocol: GCP SDK (BigQuery client)

6. **Stores artefacts to Cloud Storage**: The Cloud Run service writes any intermediate or result artefacts to the appropriate GCS bucket.
   - From: `continuumCloudRunService`
   - To: `continuumStorageBuckets`
   - Protocol: GCP SDK (GCS client)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cloud Scheduler fails to enqueue | GCP Cloud Scheduler retries per scheduler retry configuration | Task is eventually enqueued; if persistent, SRE investigates scheduler logs |
| Cloud Tasks fails to deliver | Cloud Tasks retries delivery with backoff until task TTL expires | Cloud Run invocation delayed; if TTL exceeded, task is dropped |
| Cloud Run returns non-2xx | Cloud Tasks retries the HTTP task | If max retries exceeded, task is discarded; Wavefront alert fires if systematic |
| Cloud Run OOM or crash | Cloud Run restarts the container instance | Task is retried by Cloud Tasks |
| BigQuery write fails | Cloud Run application handles error; job step fails | Results not persisted for that batch; requires manual re-trigger or investigation |

## Sequence Diagram

```
Cloud Scheduler  -> Cloud Tasks       : Enqueue HTTP task (aidg-top-deals-async, 00:00 UTC)
Cloud Tasks      -> Cloud Run Service : POST /top-deals-async [OIDC token]
Cloud Run Service -> BigQuery         : Write top-deals results (GCP SDK)
Cloud Run Service -> Cloud Storage    : Store intermediate artefacts (GCP SDK)
Cloud Run Service --> Cloud Tasks     : HTTP 200 (task acknowledged)
```

## Related

- Architecture dynamic view: `dynamic-scheduled-workflow`
- Terragrunt config: `envs/dev/us-central1/gcp-cloud-scheduler/terragrunt.hcl`
- Related flows: [Airflow DAG Orchestrated Pipeline](airflow-dag-pipeline.md)
