---
service: "mds-feed-job"
title: "Feed Output Validation and Publishing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "feed-output-validation-publishing"
flow_type: batch
trigger: "Internal — invoked by transformerPipeline after dataset transformation completes"
participants:
  - "publishingAndValidation"
  - "externalApiAdapters"
  - "continuumMarketingDealService"
architecture_ref: "dynamic-mds-feed-job-feed-generation"
---

# Feed Output Validation and Publishing

## Summary

Feed Output Validation and Publishing is the final stage of a feed batch run. The `publishingAndValidation` component receives the transformed Spark dataset, applies feed quality validation rules, writes output files to GCS staging, triggers upload or publication workflows for downstream consumers (Google Merchant Center, partner channels), and updates batch lifecycle status in the Marketing Deal Service.

## Trigger

- **Type**: internal (programmatic)
- **Source**: `transformerPipeline` hands off the transformed dataset
- **Frequency**: Once per feed batch run, after transformer pipeline completes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Publishing and Validation | Validates feed output, writes files, triggers uploads, updates batch status | `publishingAndValidation` |
| External API Adapters | Calls Marketing Deal Service to publish status and trigger upload workflows | `externalApiAdapters` |
| Marketing Deal Service | Receives batch status updates and upload trigger requests | `continuumMarketingDealService` |
| GCS (feed staging) | Destination for validated feed output files | `continuumMdsFeedJob` (storage) |
| Google Merchant Center | Receives finalized feed uploads | external |
| Google Ads | Receives SEM/ads feed uploads | external |

## Steps

1. **Receive transformed dataset**: `publishingAndValidation` receives the finalized Spark DataFrame/Dataset from `transformerPipeline`.
   - From: `transformerPipeline`
   - To: `publishingAndValidation`
   - Protocol: direct (Spark dataset)

2. **Run feed validation rules**: `publishingAndValidation` applies validation rules against the dataset (record count thresholds, required field presence, value range checks, format compliance).
   - From: `publishingAndValidation`
   - To: Spark dataset (in-memory)
   - Protocol: direct (Spark SQL / DataFrame operations)

3. **Evaluate validation results**: If validation fails (e.g., record count below threshold, critical field missing), the publish step is aborted and the batch is marked failed.
   - From: `publishingAndValidation`
   - To: `externalApiAdapters`
   - Protocol: direct → HTTPS/JSON to `continuumMarketingDealService`

4. **Write feed output files**: On validation pass, `publishingAndValidation` writes the dataset to GCS staging in the target format (CSV via OpenCSV, XML via spark-xml, or other feed-type-specific format).
   - From: `publishingAndValidation`
   - To: GCS feed staging bucket
   - Protocol: GCS SDK

5. **Publish metrics**: `publishingAndValidation` calls `externalApiAdapters` to write feed run metrics (record counts, validation pass/fail, latency) to InfluxDB and the Feed API.
   - From: `publishingAndValidation`
   - To: `externalApiAdapters`
   - Protocol: direct → HTTPS/JSON (InfluxDB, Marketing Deal Service)

6. **Trigger upload workflow**: `publishingAndValidation` calls `externalApiAdapters` to notify Marketing Deal Service to trigger downstream distribution (Merchant Center upload, partner feed delivery).
   - From: `publishingAndValidation`
   - To: `externalApiAdapters` → `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

7. **Update batch lifecycle to complete**: `externalApiAdapters` posts final batch status (SUCCESS or FAILED) to Marketing Deal Service.
   - From: `externalApiAdapters`
   - To: `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation rule fails (record count below threshold) | Publish aborted; batch marked failed via Feed API | No feed file written to GCS; batch status = FAILED |
| Validation rule fails (required field missing) | Publish aborted; batch marked failed | No feed file written; batch status = FAILED |
| GCS write fails | Failsafe retry; if retries exhausted, exception propagated | Batch marked failed; no output delivered |
| Merchant Center upload fails | Failsafe retry; failure logged and batch marked failed | Feed not refreshed for this run in Merchant Center |
| Feed API status update fails | Failsafe retry; logged | Batch status may be stale in Marketing Deal Service |
| Zero-record output passes validation | Feed file written as empty | Downstream consumers receive empty feed; alert triggered by monitoring |

## Sequence Diagram

```
transformerPipeline       -> publishingAndValidation : Transformed dataset
publishingAndValidation   -> publishingAndValidation : Run validation rules (record count, required fields)
publishingAndValidation   -> GCS                    : Write feed output file (CSV/XML)
GCS                      --> publishingAndValidation : Write confirmation
publishingAndValidation   -> externalApiAdapters     : Publish run metrics
externalApiAdapters       -> continuumMarketingDealService : POST /metrics
externalApiAdapters       -> InfluxDB                : Write operational metrics
publishingAndValidation   -> externalApiAdapters     : Trigger upload workflow
externalApiAdapters       -> continuumMarketingDealService : POST /batch/trigger-upload
continuumMarketingDealService --> externalApiAdapters : Upload acknowledged
externalApiAdapters       -> continuumMarketingDealService : POST /batch/complete (SUCCESS)
continuumMarketingDealService --> externalApiAdapters : Status updated
```

## Related

- Architecture dynamic view: `dynamic-mds-feed-job-feed-generation`
- Related flows: [Feed Job Orchestration](feed-job-orchestration.md), [Transformer Pipeline Execution](transformer-pipeline-execution.md), [Metrics and Monitoring](metrics-monitoring.md)
