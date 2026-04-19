---
service: "transporter-jtier"
title: "Bulk Salesforce Upload (Worker Job)"
generated: "2026-03-03"
type: flow
flow_name: "bulk-salesforce-upload-worker"
flow_type: scheduled
trigger: "Quartz scheduler fires the sf-upload-worker job on the configured interval"
participants:
  - "continuumTransporterJtierService"
  - "uploadWorker"
  - "persistence"
  - "storageClients"
  - "salesforceAccess"
  - "continuumTransporterMysqlDatabase"
  - "awsS3ObjectStorage"
  - "gcsObjectStorage"
architecture_ref: "dynamic-transporter_jtier_components"
---

# Bulk Salesforce Upload (Worker Job)

## Summary

This is the core asynchronous batch processing flow of Transporter JTier. The `sf-upload-worker` Quartz job, running in a dedicated Kubernetes component, polls MySQL for pending upload jobs, fetches each CSV input file from AWS S3, executes the appropriate Salesforce bulk operation (insert, update, or delete), writes result files to GCS, and updates the job state in MySQL. This flow is entirely internal to the JTier service and does not expose an HTTP API.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (`jtier-quartz-bundle`) internal to the `sf-upload-worker` Kubernetes pod
- **Frequency**: Configured via the JTier YAML config file; exact interval not visible in config files present in the repository

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upload Worker | Quartz job that drives the entire flow | `uploadWorker` |
| Upload Persistence | Reads pending jobs and updates job state | `persistence` |
| Cloud Storage Clients | Fetches CSV from S3; writes results to GCS | `storageClients` |
| Salesforce Access Client | Executes Salesforce bulk API calls | `salesforceAccess` |
| Transporter MySQL | Source of truth for job state | `continuumTransporterMysqlDatabase` |
| AWS S3 | Provides the CSV input file | `awsS3ObjectStorage` |
| GCS | Receives result files; provides signed download URLs | `gcsObjectStorage` |

## Steps

1. **Quartz trigger fires**: The Quartz scheduler in the `sf-upload-worker` pod fires the upload job on schedule.
   - From: Quartz scheduler
   - To: `uploadWorker`
   - Protocol: in-process (JVM scheduling)

2. **Queries pending jobs**: The Upload Worker instructs Upload Persistence to query MySQL for upload jobs in PENDING or QUEUED state.
   - From: `uploadWorker`
   - To: `persistence`
   - Protocol: direct (in-process)

3. **Reads pending jobs from MySQL**: The persistence layer executes a JDBI SELECT query.
   - From: `persistence`
   - To: `continuumTransporterMysqlDatabase`
   - Protocol: JDBI/MySQL

4. **Marks job as IN_PROGRESS**: The Upload Worker updates each selected job's status to IN_PROGRESS in MySQL to prevent concurrent processing.
   - From: `uploadWorker` via `persistence`
   - To: `continuumTransporterMysqlDatabase`
   - Protocol: JDBI/MySQL

5. **Fetches CSV input from S3**: The Upload Worker invokes the Cloud Storage Clients to retrieve the CSV file from the S3 key stored on the job record.
   - From: `uploadWorker`
   - To: `storageClients`
   - Protocol: direct (in-process)

6. **Downloads file from S3**: The AWS SDK client retrieves the file bytes.
   - From: `storageClients`
   - To: `awsS3ObjectStorage`
   - Protocol: S3 (AWS SDK v2, HTTPS); authenticated via IRSA token

7. **Executes Salesforce bulk operation**: The Upload Worker invokes the Salesforce Access Client to perform the bulk data operation (insert, update, or delete) against the target Salesforce object.
   - From: `uploadWorker`
   - To: `salesforceAccess`
   - Protocol: direct (in-process)

8. **Calls Salesforce Bulk API**: The Salesforce Access Client sends the CSV data to Salesforce via the REST/Bulk API.
   - From: `salesforceAccess`
   - To: Salesforce Bulk API
   - Protocol: OAuth2/REST (HTTPS)

9. **Receives Salesforce result**: Salesforce returns success/failure records for the bulk operation.
   - From: Salesforce
   - To: `salesforceAccess`
   - Protocol: OAuth2/REST (HTTPS)

10. **Writes result file to GCS**: The Upload Worker instructs the Cloud Storage Clients to write the result data (success/error records) to a GCS bucket, generating a signed URL for download.
    - From: `uploadWorker`
    - To: `storageClients`
    - Protocol: direct (in-process)

11. **Uploads result to GCS**: The GCS SDK client writes the result file.
    - From: `storageClients`
    - To: `gcsObjectStorage`
    - Protocol: GCS SDK (HTTPS); authenticated via GCP Workload Identity

12. **Updates job state in MySQL**: The Upload Worker instructs Upload Persistence to mark the job as COMPLETED (or FAILED on error) and store the GCS result file reference.
    - From: `uploadWorker` via `persistence`
    - To: `continuumTransporterMysqlDatabase`
    - Protocol: JDBI/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No pending jobs found | Worker exits cleanly; waits for next Quartz trigger | No action taken |
| S3 file not found | Download throws exception | Job marked FAILED in MySQL with error details |
| Salesforce API error | HTTP error response from Salesforce | Job marked FAILED; error recorded in MySQL |
| Salesforce token expired | Access Client detects 401; may attempt refresh | If refresh fails, job marked FAILED |
| GCS write fails | SDK exception | Result not written; job may be marked FAILED |
| MySQL unreachable | JDBI exception | Worker cannot read or update jobs; retried on next Quartz trigger |

## Sequence Diagram

```
QuartzScheduler  ->  uploadWorker  : fire()
uploadWorker  ->  persistence  : getPendingJobs()
persistence  ->  continuumTransporterMysqlDatabase  : SELECT * FROM upload_jobs WHERE status='PENDING'
continuumTransporterMysqlDatabase  -->  persistence  : [jobRecords]
persistence  -->  uploadWorker  : [jobRecords]
uploadWorker  ->  persistence  : updateStatus(jobId, IN_PROGRESS)
persistence  ->  continuumTransporterMysqlDatabase  : UPDATE upload_jobs SET status='IN_PROGRESS'
uploadWorker  ->  storageClients  : fetchFile(s3Key)
storageClients  ->  awsS3ObjectStorage  : GET s3://bucket/jobId/input.csv
awsS3ObjectStorage  -->  storageClients  : csvBytes
storageClients  -->  uploadWorker  : csvBytes
uploadWorker  ->  salesforceAccess  : executeBulkOperation(object, operation, csvBytes)
salesforceAccess  ->  Salesforce  : POST /services/data/vXX/jobs/ingest (Bulk API)
Salesforce  -->  salesforceAccess  : bulkResult
salesforceAccess  -->  uploadWorker  : result
uploadWorker  ->  storageClients  : writeResult(jobId, resultBytes)
storageClients  ->  gcsObjectStorage  : PUT gs://bucket/jobId/result.csv
gcsObjectStorage  -->  storageClients  : signedUrl
storageClients  -->  uploadWorker  : signedUrl
uploadWorker  ->  persistence  : updateStatus(jobId, COMPLETED, signedUrl)
persistence  ->  continuumTransporterMysqlDatabase  : UPDATE upload_jobs SET status='COMPLETED'
```

## Related

- Architecture dynamic view: `dynamic-transporter_jtier_components`
- Related flows: [CSV Upload Submission](csv-upload-submission.md), [Upload Status Query](upload-status-query.md)
