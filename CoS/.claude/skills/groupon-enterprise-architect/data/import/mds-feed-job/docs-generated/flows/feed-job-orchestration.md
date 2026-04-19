---
service: "mds-feed-job"
title: "Feed Job Orchestration"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "feed-job-orchestration"
flow_type: batch
trigger: "Livy job submission by external scheduler"
participants:
  - "feedOrchestrator"
  - "externalApiAdapters"
  - "continuumMarketingDealService"
  - "transformerPipeline"
  - "publishingAndValidation"
architecture_ref: "dynamic-mds-feed-job-feed-generation"
---

# Feed Job Orchestration

## Summary

Feed Job Orchestration is the top-level lifecycle of a single MDS feed batch run. The `feedOrchestrator` component bootstraps the Spark context, loads feed configuration and batch state from the Marketing Deal Service, coordinates the transformer pipeline, and ensures batch status is updated on completion or failure. This flow spans the entire run from Spark application start to job exit.

## Trigger

- **Type**: schedule
- **Source**: External scheduler or Livy REST API submission
- **Frequency**: Per scheduled feed run (varies by feed type — daily, hourly, or on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Feed Orchestrator | Bootstraps, coordinates, and terminates the batch run | `feedOrchestrator` |
| External API Adapters | Loads feed definitions and batch state from Feed API | `externalApiAdapters` |
| Marketing Deal Service | Source of feed definitions and batch lifecycle state | `continuumMarketingDealService` |
| Transformer Pipeline | Executes feed transformation logic | `transformerPipeline` |
| Publishing and Validation | Validates and publishes feed output | `publishingAndValidation` |

## Steps

1. **Receive job submission**: External scheduler submits Spark job to Livy with feed type, batch ID, and run date arguments.
   - From: `external-scheduler`
   - To: `feedOrchestrator`
   - Protocol: Livy REST / Spark application args

2. **Load feed definition**: `feedOrchestrator` calls `externalApiAdapters` to fetch feed configuration and current batch state.
   - From: `feedOrchestrator`
   - To: `externalApiAdapters`
   - Protocol: direct (in-process)

3. **Fetch feed definition and batch state**: Adapter calls Marketing Deal Service to retrieve feed definition and register batch start.
   - From: `externalApiAdapters`
   - To: `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

4. **Initialize Spark context**: `feedOrchestrator` configures the Spark session, dataset schemas, and broadcast variables for the run.
   - From: `feedOrchestrator`
   - To: Spark runtime
   - Protocol: direct

5. **Start transformer execution**: `feedOrchestrator` invokes `transformerPipeline` with the loaded feed definition and Spark context.
   - From: `feedOrchestrator`
   - To: `transformerPipeline`
   - Protocol: direct

6. **Execute transformer pipeline**: `transformerPipeline` reads MDS snapshots from GCS/HDFS, applies transformer and UDF chains, and calls `externalApiAdapters` for enrichment. See [Transformer Pipeline Execution](transformer-pipeline-execution.md).
   - From: `transformerPipeline`
   - To: GCS/HDFS, `externalApiAdapters`
   - Protocol: GCS SDK / HDFS / direct

7. **Hand off to publishing**: `transformerPipeline` passes the transformed dataset to `publishingAndValidation`.
   - From: `transformerPipeline`
   - To: `publishingAndValidation`
   - Protocol: direct (Spark dataset)

8. **Validate and publish**: `publishingAndValidation` runs validation rules, writes feed files to GCS staging, and triggers upload. See [Feed Output Validation and Publishing](feed-output-validation-publishing.md).
   - From: `publishingAndValidation`
   - To: GCS staging, `externalApiAdapters`
   - Protocol: GCS SDK / direct

9. **Update batch lifecycle**: `publishingAndValidation` calls `externalApiAdapters` to update batch status (success or failure) in Marketing Deal Service.
   - From: `publishingAndValidation`
   - To: `externalApiAdapters` → `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

10. **Job exits**: Spark application terminates; Livy reports final status to the scheduler.
    - From: `feedOrchestrator`
    - To: Livy / external scheduler
    - Protocol: Livy job status API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Feed definition load fails | Failsafe retry on Marketing Deal Service call; job fails if retries exhausted | Batch marked as failed; job exits with error |
| Spark context initialization failure | Spark application exits with non-zero code | Livy reports FAILED status; scheduler alerts |
| Transformer pipeline fails mid-run | Exception propagates to `feedOrchestrator`; batch status updated to failed | Batch marked failed; partial output not published |
| Publishing step fails | `publishingAndValidation` catches exception; calls adapter to mark batch failed | Batch status updated to failed in Marketing Deal Service |
| Livy submission timeout | External scheduler handles retry policy | Retry or alert per scheduler configuration |

## Sequence Diagram

```
Scheduler     -> Livy           : Submit Spark job (feed_type, batch_id, run_date)
Livy          -> feedOrchestrator : Start Spark application
feedOrchestrator -> externalApiAdapters : Load feed definition + batch state
externalApiAdapters -> continuumMarketingDealService : GET /feed-definition, POST /batch/start
continuumMarketingDealService --> externalApiAdapters : Feed config + batch ID
externalApiAdapters --> feedOrchestrator : Feed definition loaded
feedOrchestrator -> transformerPipeline : Start transformer execution
transformerPipeline -> GCS/HDFS  : Read MDS snapshots
transformerPipeline -> externalApiAdapters : Enrichment API calls (see external-api-enrichment)
transformerPipeline --> publishingAndValidation : Transformed dataset
publishingAndValidation -> GCS   : Write feed output files
publishingAndValidation -> externalApiAdapters : Publish metrics + update batch status
externalApiAdapters -> continuumMarketingDealService : POST /batch/complete
feedOrchestrator --> Livy        : Job exit (SUCCESS/FAILED)
```

## Related

- Architecture dynamic view: `dynamic-mds-feed-job-feed-generation`
- Related flows: [Transformer Pipeline Execution](transformer-pipeline-execution.md), [Feed Output Validation and Publishing](feed-output-validation-publishing.md), [Metrics and Monitoring](metrics-monitoring.md)
