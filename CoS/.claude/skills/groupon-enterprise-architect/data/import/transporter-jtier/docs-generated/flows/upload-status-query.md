---
service: "transporter-jtier"
title: "Upload Status Query"
generated: "2026-03-03"
type: flow
flow_name: "upload-status-query"
flow_type: synchronous
trigger: "GET /v0/getUploads or GET /v0/getUploadsById called by Transporter ITier"
participants:
  - "continuumTransporterJtierService"
  - "transporterJtier_apiResource"
  - "userTokenService"
  - "uploadOrchestration"
  - "persistence"
  - "continuumTransporterMysqlDatabase"
architecture_ref: "dynamic-transporter_jtier_components"
---

# Upload Status Query

## Summary

This flow allows Transporter ITier to poll the status of bulk upload jobs. ITier calls either `GET /v0/getUploads` to retrieve all jobs or `GET /v0/getUploadsById` to retrieve a single job record. The JTier backend validates the user's Salesforce token, queries MySQL via the JDBI persistence layer, and returns the job state including any result file references (GCS signed URLs) when the job has completed.

## Trigger

- **Type**: api-call
- **Source**: `transporter-itier` calls `GET /v0/getUploads` or `GET /v0/getUploadsById`
- **Frequency**: On-demand — polled by ITier while the user views upload history or waits for job completion

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Transporter ITier | Initiates status query | External caller |
| Transporter API Resource | Receives the GET request and delegates | `transporterJtier_apiResource` |
| User Token Service | Validates the Salesforce user token | `userTokenService` |
| Upload Orchestration | Delegates the query to persistence | `uploadOrchestration` |
| Upload Persistence | Executes the MySQL query | `persistence` |
| Transporter MySQL | Returns job records | `continuumTransporterMysqlDatabase` |

## Steps

1. **Receives status request**: Transporter ITier sends `GET /v0/getUploads` or `GET /v0/getUploadsById`.
   - From: `transporter-itier`
   - To: `transporterJtier_apiResource`
   - Protocol: REST (HTTP)

2. **Validates user token**: The API Resource invokes the User Token Service to verify the Salesforce access token.
   - From: `transporterJtier_apiResource`
   - To: `userTokenService`
   - Protocol: direct (in-process)

3. **Queries Redis for cached token**: The User Token Service checks Redis for a cached token before attempting re-validation with Salesforce.
   - From: `userTokenService`
   - To: `continuumTransporterRedisCache`
   - Protocol: Redis

4. **Delegates to Upload Orchestration**: After token validation, the API Resource passes the query to Upload Orchestration.
   - From: `transporterJtier_apiResource`
   - To: `uploadOrchestration`
   - Protocol: direct (in-process)

5. **Reads upload records**: Upload Orchestration instructs Upload Persistence to query the upload jobs table.
   - From: `uploadOrchestration`
   - To: `persistence`
   - Protocol: direct (in-process)

6. **Queries MySQL**: The persistence layer executes a JDBI SELECT to retrieve all jobs (list query) or a specific job by ID (single query).
   - From: `persistence`
   - To: `continuumTransporterMysqlDatabase`
   - Protocol: JDBI/MySQL

7. **Returns job records**: MySQL returns the matching rows including job status, timestamps, and GCS result URL if COMPLETED.
   - From: `continuumTransporterMysqlDatabase`
   - To: `persistence`
   - Protocol: JDBI/MySQL

8. **Returns JSON response**: The API Resource serializes the job records to JSON and responds to ITier.
   - From: `transporterJtier_apiResource`
   - To: `transporter-itier`
   - Protocol: REST (HTTP), Content-Type: application/json

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or expired user token | Token validation fails | HTTP error returned to ITier |
| Job ID not found (`getUploadsById`) | JDBI returns empty result | HTTP 404 or empty JSON response |
| MySQL unavailable | JDBI throws exception | HTTP 500 returned to ITier |

## Sequence Diagram

```
transporter-itier  ->  transporterJtier_apiResource  : GET /v0/getUploads (or /v0/getUploadsById)
transporterJtier_apiResource  ->  userTokenService  : validateToken(user)
userTokenService  ->  continuumTransporterRedisCache  : GET user:<id>
continuumTransporterRedisCache  -->  userTokenService  : token (or miss)
userTokenService  -->  transporterJtier_apiResource  : valid
transporterJtier_apiResource  ->  uploadOrchestration  : getUploads(user) or getUploadById(jobId)
uploadOrchestration  ->  persistence  : queryJobs(user) or queryJob(jobId)
persistence  ->  continuumTransporterMysqlDatabase  : SELECT * FROM upload_jobs [WHERE id=?]
continuumTransporterMysqlDatabase  -->  persistence  : [jobRecords]
persistence  -->  uploadOrchestration  : [jobRecords]
uploadOrchestration  -->  transporterJtier_apiResource  : [jobRecords]
transporterJtier_apiResource  -->  transporter-itier  : 200 JSON [jobRecords]
```

## Related

- Architecture dynamic view: `dynamic-transporter_jtier_components`
- Related flows: [CSV Upload Submission](csv-upload-submission.md), [Bulk Salesforce Upload (Worker Job)](bulk-salesforce-upload-worker.md), [Salesforce User Authentication](salesforce-user-authentication.md)
