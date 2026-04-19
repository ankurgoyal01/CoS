---
service: "mvrt"
title: "Offline Report Download"
generated: "2026-03-03"
type: flow
flow_name: "offline-report-download"
flow_type: synchronous
trigger: "HTTP GET /downloadFile?report=<fileName> from browser"
participants:
  - "mvrt_webRouting"
  - "mvrt_fileExport"
  - "aws-s3"
architecture_ref: "dynamic-search_and_redeem_flow"
---

# Offline Report Download

## Summary

After receiving the Rocketman notification email, the user clicks the download link or navigates to `GET /downloadFile?report=<fileName>`. MVRT authenticates the user via Okta, retrieves the file directly from the AWS S3 bucket using a streaming read, and pipes the S3 object byte-stream to the HTTP response as a file attachment. This avoids storing the report locally during the download flow.

## Trigger

- **Type**: user-action
- **Source**: User clicks download link from Rocketman notification email, or navigates directly to `/downloadFile?report=<fileName>`
- **Frequency**: On demand, per report download request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser / Email Client | Initiates GET request from notification email link | — |
| Web Routing and Auth (`mvrt_webRouting`) | Receives GET, validates Okta session, passes to File Export | `mvrt_webRouting` |
| File Export and Report Builder (`mvrt_fileExport`) | Calls S3 and streams the file to the HTTP response | `mvrt_fileExport` |
| AWS S3 | Source of the XLSX or CSV report file | `unknown_awss3bucket_da58205c` (stub) |

## Steps

1. **Receive download request**: User sends `GET /downloadFile?report=<fileName>` with active Okta session cookie.
   - From: Browser
   - To: `mvrt_webRouting`
   - Protocol: REST/HTTP GET

2. **Authenticate and extract parameters**: Web Routing validates Okta session; extracts `report` query parameter (the S3 object key / filename) and `oktaUser`. Passes `report`, `res` (HTTP response object), and `oktaUser` to the File Export component.
   - From: `mvrt_webRouting`
   - To: `mvrt_fileExport`
   - Protocol: Direct (in-process)

3. **Initiate S3 stream**: File Export instantiates an `AWS.S3` client with credentials from the secrets file; calls `s3.getObject({Bucket, Key: fileName}).createReadStream()`.
   - From: `mvrt_fileExport`
   - To: AWS S3
   - Protocol: AWS SDK (streaming)

4. **Set response headers and stream**: Sets `Content-Disposition: attachment; filename=<fileName>` via `res.attachment(fileName)`; pipes the S3 read stream directly to the HTTP response.
   - From: `mvrt_fileExport`
   - To: Browser
   - Protocol: HTTP chunked transfer (file attachment)

5. **Complete download**: S3 stream completes; HTTP response ends naturally. Browser saves the file.
   - From: AWS S3 → `mvrt_fileExport` → Browser
   - Protocol: HTTP response stream

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| S3 `getObject` stream error | Error logged as `[S3-BUCKET-ERROR]`; browser redirected to `/error` | User sees error page; report not delivered |
| File not found in S3 | S3 returns NoSuchKey error; stream error handler fires | Browser redirected to `/error` |
| Unauthenticated request | Okta middleware rejects; redirected to login | User must re-authenticate |

## Sequence Diagram

```
Browser -> mvrt_webRouting: GET /downloadFile?report=<fileName>
mvrt_webRouting -> mvrt_webRouting: validate Okta session
mvrt_webRouting -> mvrt_fileExport: downloadFile(fileName, awsCredentials, res)
mvrt_fileExport -> aws-s3: getObject({Bucket, Key: fileName}).createReadStream()
aws-s3 --> mvrt_fileExport: byte stream
mvrt_fileExport -> mvrt_fileExport: res.attachment(fileName)
mvrt_fileExport -> Browser: pipe(S3 stream -> HTTP response)
Browser --> User: file downloaded (XLSX or CSV)
```

## Related

- Architecture dynamic view: `dynamic-search_and_redeem_flow`
- Related flows: [Offline Search Job Submission](offline-job-submission.md), [Offline Search Batch Processing](offline-batch-processing.md)
