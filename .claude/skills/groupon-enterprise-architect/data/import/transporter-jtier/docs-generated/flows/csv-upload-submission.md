---
service: "transporter-jtier"
title: "CSV Upload Submission"
generated: "2026-03-03"
type: flow
flow_name: "csv-upload-submission"
flow_type: synchronous
trigger: "POST /v0/upload called by Transporter ITier with a CSV file body"
participants:
  - "continuumTransporterJtierService"
  - "transporterJtier_apiResource"
  - "uploadOrchestration"
  - "userTokenService"
  - "userService_TraJti"
  - "persistence"
  - "storageClients"
  - "continuumTransporterMysqlDatabase"
  - "awsS3ObjectStorage"
architecture_ref: "dynamic-transporter_jtier_components"
---

# CSV Upload Submission

## Summary

This flow handles the synchronous portion of a bulk Salesforce data upload. Transporter ITier posts a CSV file to the JTier backend. JTier validates the user's Salesforce token, creates an upload job record in MySQL, and stages the CSV input file to AWS S3. The response returns the new job ID, which ITier uses for subsequent status polling. Actual Salesforce execution happens asynchronously in the [Bulk Salesforce Upload worker flow](bulk-salesforce-upload-worker.md).

## Trigger

- **Type**: api-call
- **Source**: `transporter-itier` calls `POST /v0/upload` with `Content-Type: text/csv`
- **Frequency**: On-demand — once per user-initiated upload

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Transporter ITier | Submits the CSV upload request | External caller |
| Transporter API Resource | Receives POST /v0/upload, validates request, delegates to Upload Orchestration | `transporterJtier_apiResource` |
| Upload Orchestration | Coordinates validation, persistence, and file staging | `uploadOrchestration` |
| User Token Service | Validates the Salesforce user token before accepting the upload | `userTokenService` |
| User Service | Validates user ownership and access rights | `userService_TraJti` |
| Upload Persistence | Writes the new upload job record to MySQL | `persistence` |
| Cloud Storage Clients | Stages the CSV input file to AWS S3 | `storageClients` |
| Transporter MySQL | Stores the upload job record | `continuumTransporterMysqlDatabase` |
| AWS S3 | Stores the staged CSV input file | `awsS3ObjectStorage` |

## Steps

1. **Receives upload request**: Transporter ITier sends `POST /v0/upload` with CSV body and user auth context.
   - From: `transporter-itier`
   - To: `transporterJtier_apiResource`
   - Protocol: REST (HTTP), Content-Type: text/csv

2. **Validates user token**: The API Resource invokes the User Token Service to verify the Salesforce access token is valid.
   - From: `transporterJtier_apiResource`
   - To: `userTokenService`
   - Protocol: direct (in-process)

3. **Delegates to Upload Orchestration**: After token validation, the API Resource passes the upload request to the Upload Orchestration component.
   - From: `transporterJtier_apiResource`
   - To: `uploadOrchestration`
   - Protocol: direct (in-process)

4. **Validates user access**: Upload Orchestration invokes the User Service to confirm the user exists and has access rights for the requested Salesforce object.
   - From: `uploadOrchestration`
   - To: `userService_TraJti`
   - Protocol: direct (in-process)

5. **Creates upload job record**: Upload Orchestration instructs Upload Persistence to insert a new upload job row into MySQL with initial status (e.g., PENDING).
   - From: `uploadOrchestration`
   - To: `persistence`
   - Protocol: direct (in-process)

6. **Writes job to MySQL**: The persistence layer executes the JDBI insert.
   - From: `persistence`
   - To: `continuumTransporterMysqlDatabase`
   - Protocol: JDBI/MySQL

7. **Stages CSV to S3**: Upload Orchestration invokes the Cloud Storage Clients to upload the CSV file bytes to the configured AWS S3 bucket, keyed by job ID.
   - From: `uploadOrchestration`
   - To: `storageClients`
   - Protocol: direct (in-process)

8. **Writes file to S3**: The AWS SDK client uploads the CSV to S3.
   - From: `storageClients`
   - To: `awsS3ObjectStorage`
   - Protocol: S3 (AWS SDK v2, HTTPS)

9. **Returns job ID**: The API Resource responds to ITier with a JSON payload containing the new upload job ID.
   - From: `transporterJtier_apiResource`
   - To: `transporter-itier`
   - Protocol: REST (HTTP), Content-Type: application/json

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or expired Salesforce token | Token validation fails in User Token Service | HTTP error returned to ITier; upload rejected |
| User not found or unauthorized | User Service returns not-found or access-denied | HTTP 4xx returned to ITier; upload rejected |
| MySQL unavailable | JDBI insert fails | Upload job not created; error returned to ITier |
| S3 upload fails | AWS SDK throws exception | Upload job record may be left in PENDING with no file; error returned to ITier |

## Sequence Diagram

```
transporter-itier  ->  transporterJtier_apiResource  : POST /v0/upload (CSV body)
transporterJtier_apiResource  ->  userTokenService  : validateToken(user)
userTokenService  -->  transporterJtier_apiResource  : valid
transporterJtier_apiResource  ->  uploadOrchestration  : submitUpload(csv, objectType, operation)
uploadOrchestration  ->  userService_TraJti  : validateUserAccess(user)
userService_TraJti  ->  continuumTransporterMysqlDatabase  : SELECT user
continuumTransporterMysqlDatabase  -->  userService_TraJti  : user record
userService_TraJti  -->  uploadOrchestration  : authorized
uploadOrchestration  ->  persistence  : insertJob(jobRecord)
persistence  ->  continuumTransporterMysqlDatabase  : INSERT upload_job
continuumTransporterMysqlDatabase  -->  persistence  : jobId
persistence  -->  uploadOrchestration  : jobId
uploadOrchestration  ->  storageClients  : uploadFile(jobId, csvBytes)
storageClients  ->  awsS3ObjectStorage  : PUT s3://bucket/jobId/input.csv
awsS3ObjectStorage  -->  storageClients  : OK
storageClients  -->  uploadOrchestration  : fileKey
uploadOrchestration  -->  transporterJtier_apiResource  : jobId
transporterJtier_apiResource  -->  transporter-itier  : 200 JSON { jobId }
```

## Related

- Architecture dynamic view: `dynamic-transporter_jtier_components`
- Related flows: [Bulk Salesforce Upload (Worker Job)](bulk-salesforce-upload-worker.md), [Upload Status Query](upload-status-query.md)
