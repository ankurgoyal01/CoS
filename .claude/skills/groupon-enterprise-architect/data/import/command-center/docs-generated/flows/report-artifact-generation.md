---
service: "command-center"
title: "Report Artifact Generation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "report-artifact-generation"
flow_type: batch
trigger: "Background job execution produces output records requiring CSV report artifact creation"
participants:
  - "continuumCommandCenterWorker"
  - "continuumCommandCenterMysql"
  - "cloudPlatform"
  - "continuumCommandCenterWeb"
architecture_ref: "dynamic-cmdcenter-tool-request-processing"
---

# Report Artifact Generation

## Summary

When a tool job produces bulk output records (such as the results of a mass deal update or voucher processing run), the Command Center Worker generates a CSV report artifact and uploads it to object storage (`cloudPlatform` / S3). The worker then persists a reference to the artifact in MySQL. Operators subsequently retrieve the report through the Command Center web UI, which reads the artifact reference from MySQL and delivers the file from S3.

## Trigger

- **Type**: event (job completion producing output records)
- **Source**: `cmdCenter_workerJobs` within `continuumCommandCenterWorker` — occurs at the end of a tool job that generates reportable output
- **Frequency**: Per job execution that produces output data (on-demand, tool-dependent)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Command Center Worker | Generates the CSV artifact and uploads it to S3 | `continuumCommandCenterWorker` |
| Command Center MySQL | Stores the artifact reference linked to the originating job | `continuumCommandCenterMysql` |
| Cloud Platform (S3) | Stores the CSV artifact payload in object storage | `cloudPlatform` |
| Command Center Web | Reads the artifact reference and serves the file to the operator | `continuumCommandCenterWeb` |

## Steps

1. **Accumulate output records**: As the job handler (`cmdCenter_workerJobs`) executes bulk operations, it collects result records for each processed item.
   - From: `cmdCenter_workerJobs`
   - To: in-process accumulator
   - Protocol: direct (in-process)

2. **Serialize to CSV**: Job handler serializes accumulated output records into a CSV format.
   - From: `cmdCenter_workerJobs`
   - To: in-process CSV serializer
   - Protocol: direct (in-process)

3. **Upload CSV to object storage**: Job handler uploads the serialized CSV file to `cloudPlatform` (S3).
   - From: `cmdCenter_workerApiClients` within `continuumCommandCenterWorker`
   - To: `cloudPlatform` (S3 bucket)
   - Protocol: S3 APIs

4. **Persist artifact reference**: Worker persistence layer writes a record to MySQL linking the S3 artifact to the originating job.
   - From: `cmdCenter_workerPersistence`
   - To: `continuumCommandCenterMysql` (`cmdCenter_schema` report artifacts table)
   - Protocol: ActiveRecord / MySQL

5. **Operator requests report**: Operator navigates to the job result page in the Command Center web UI.
   - From: Operator (browser)
   - To: `continuumCommandCenterWeb`
   - Protocol: HTTP

6. **Serve artifact reference**: Web layer reads the artifact reference from MySQL and generates a download link or proxy URL for the operator.
   - From: `cmdCenter_webPersistence` within `continuumCommandCenterWeb`
   - To: `continuumCommandCenterMysql`
   - Protocol: ActiveRecord / MySQL

7. **Deliver file to operator**: Operator downloads the CSV report artifact from the URL provided by the web layer.
   - From: `continuumCommandCenterWeb` or `cloudPlatform` (direct S3 pre-signed URL, inferred)
   - To: Operator (browser)
   - Protocol: HTTP / S3 pre-signed URL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| S3 upload failure | Job handler exception; Delayed Job retries entire job or the upload step | Artifact not available until retry succeeds |
| MySQL write failure for artifact reference | Delayed Job retries; artifact may be orphaned in S3 without a MySQL reference | Operator cannot discover artifact via UI; manual recovery may be needed |
| S3 artifact missing at download time | Web layer receives S3 not-found error | Operator sees a download error; artifact may need to be regenerated |

## Sequence Diagram

```
cmdCenter_workerJobs      -> cmdCenter_workerJobs           : Accumulates output records (in-process)
cmdCenter_workerJobs      -> cmdCenter_workerJobs           : Serializes records to CSV (in-process)
cmdCenter_workerApiClients -> cloudPlatform                 : Uploads CSV artifact to S3 (S3 APIs)
cloudPlatform             --> cmdCenter_workerApiClients    : Upload confirmation (S3 APIs)
cmdCenter_workerPersistence -> continuumCommandCenterMysql  : Persists artifact reference (ActiveRecord/MySQL)
Operator                  -> continuumCommandCenterWeb      : Requests job result page (HTTP)
cmdCenter_webPersistence  -> continuumCommandCenterMysql    : Reads artifact reference (ActiveRecord/MySQL)
continuumCommandCenterWeb --> Operator                      : Returns download link (HTTP)
Operator                  -> cloudPlatform                  : Downloads CSV report artifact (HTTP / S3 pre-signed URL)
```

## Related

- Architecture dynamic view: `dynamic-cmdcenter-tool-request-processing`
- Related flows: [Background Job Execution](background-job-execution.md), [Tool Request Processing](tool-request-processing.md)
