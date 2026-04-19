---
service: "mds-feed-job"
title: "Metrics and Monitoring"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "metrics-monitoring"
flow_type: batch
trigger: "Internal — invoked by publishingAndValidation at job completion and at pipeline checkpoints"
participants:
  - "publishingAndValidation"
  - "externalApiAdapters"
  - "continuumMarketingDealService"
architecture_ref: "dynamic-mds-feed-job-feed-generation"
---

# Metrics and Monitoring

## Summary

Metrics and Monitoring covers how MDS Feed Job collects and emits operational signals during and after a feed batch run. The `publishingAndValidation` component is responsible for publishing run metrics to InfluxDB 2.9 and updating batch lifecycle status in the Marketing Deal Service. Metrics include feed record counts, transformer error counts, validation pass/fail outcomes, API call latencies, and overall run duration.

## Trigger

- **Type**: internal (programmatic)
- **Source**: `publishingAndValidation` at batch completion; also at key pipeline checkpoints (post-validation, post-publish)
- **Frequency**: Once per batch run at completion; optionally at intermediate pipeline stages

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Publishing and Validation | Collects run metrics and initiates all metric write calls | `publishingAndValidation` |
| External API Adapters | Executes InfluxDB metric writes and Feed API status updates | `externalApiAdapters` |
| Marketing Deal Service | Receives batch status, lifecycle state, and feed run metrics | `continuumMarketingDealService` |
| InfluxDB | Time-series metrics store for operational dashboards and alerting | external |

## Steps

1. **Collect run metrics**: At the end of the pipeline run, `publishingAndValidation` assembles a metrics payload: total records processed, records filtered, validation pass/fail counts, transformer error counts, feed file sizes, and total run duration.
   - From: `publishingAndValidation`
   - To: in-memory metrics accumulator
   - Protocol: direct

2. **Write metrics to InfluxDB**: `externalApiAdapters` sends the assembled metrics to InfluxDB 2.9 as time-series data points tagged with feed type, run date, division, and batch ID.
   - From: `externalApiAdapters`
   - To: InfluxDB (InfluxDB client 2.9)
   - Protocol: HTTPS (InfluxDB Line Protocol)

3. **Update batch status in Feed API**: `externalApiAdapters` posts the final batch run status (SUCCESS or FAILED) and summary metrics to the Marketing Deal Service.
   - From: `externalApiAdapters`
   - To: `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

4. **Publish feed validation outcome**: If validation rules produced warnings or failures, `publishingAndValidation` sends a structured validation report to the Feed API for tracking.
   - From: `externalApiAdapters`
   - To: `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

5. **Trigger upload notification** (if applicable): On success, `publishingAndValidation` notifies the Feed API to trigger downstream upload workflows (Merchant Center, partner delivery).
   - From: `externalApiAdapters`
   - To: `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| InfluxDB write fails | Failsafe retry; if exhausted, metric loss is logged but does not fail the batch | Operational metrics gap for the run; batch result unaffected |
| Feed API status update fails | Failsafe retry; if exhausted, logged as warning | Batch status may be stale in Marketing Deal Service; alert on stale state |
| Metrics accumulator empty (no data collected) | Defensive check; writes zero-value metrics | Dashboard shows zero-record run; alerting detects anomaly |

## Sequence Diagram

```
publishingAndValidation -> publishingAndValidation : Assemble metrics payload (records, errors, duration)
publishingAndValidation -> externalApiAdapters      : Write metrics to InfluxDB
externalApiAdapters     -> InfluxDB                : POST /write (line protocol, feed_type, batch_id tags)
InfluxDB               --> externalApiAdapters      : 204 No Content
publishingAndValidation -> externalApiAdapters      : Update batch status
externalApiAdapters     -> continuumMarketingDealService : POST /batch/{id}/status (SUCCESS/FAILED)
continuumMarketingDealService --> externalApiAdapters : Status confirmed
publishingAndValidation -> externalApiAdapters      : Publish validation report
externalApiAdapters     -> continuumMarketingDealService : POST /batch/{id}/validation-report
publishingAndValidation -> externalApiAdapters      : Trigger upload notification (if SUCCESS)
externalApiAdapters     -> continuumMarketingDealService : POST /batch/{id}/trigger-upload
```

## Related

- Architecture dynamic view: `dynamic-mds-feed-job-feed-generation`
- Related flows: [Feed Job Orchestration](feed-job-orchestration.md), [Feed Output Validation and Publishing](feed-output-validation-publishing.md)
