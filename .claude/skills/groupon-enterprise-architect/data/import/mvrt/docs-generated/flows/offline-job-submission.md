---
service: "mvrt"
title: "Offline Search Job Submission"
generated: "2026-03-03"
type: flow
flow_name: "offline-job-submission"
flow_type: synchronous
trigger: "Sequence of POST /createCodesList and POST /createJsonFile HTTP requests from browser"
participants:
  - "mvrt_webRouting"
  - "mvrt_fileExport"
  - "aws-s3"
architecture_ref: "dynamic-search_and_redeem_flow"
---

# Offline Search Job Submission

## Summary

When a user wants to search more codes than the online limit allows (up to 300,000), they initiate an offline search. Because large code lists may exceed a single HTTP request body size, the browser submits codes in paginated chunks via `POST /createCodesList`, each of which is uploaded and appended to a temporary object in AWS S3. Once all chunks are submitted, the browser calls `POST /createJsonFile` to finalise the job: MVRT downloads the full code list from S3, constructs a JSON job file on the local filesystem, and deletes the temporary S3 object. The offline job scheduler picks up the JSON file within the next 1-minute polling cycle.

## Trigger

- **Type**: user-action
- **Source**: MVRT browser SPA — user selects "Offline Search" mode and submits a large code file
- **Frequency**: On demand, when search scope exceeds online limit

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser SPA | Submits code chunks; finalises job creation | — |
| Web Routing and Auth (`mvrt_webRouting`) | Receives HTTP POSTs, enforces auth, passes to File Export | `mvrt_webRouting` |
| File Export and Report Builder (`mvrt_fileExport`) | Orchestrates chunk upload to S3 and JSON job file creation | `mvrt_fileExport` |
| AWS S3 | Temporary storage for code list chunks and final report delivery | `unknown_awss3bucket_da58205c` (stub) |

## Steps

1. **Submit first code chunk**: Browser POSTs to `/createCodesList` with `codes` (first batch), `isNewObject: true`, `tempFileName`, and user/config context.
   - From: Browser SPA
   - To: `mvrt_webRouting`
   - Protocol: REST/HTTP POST

2. **Upload first chunk to S3**: `mvrt_fileExport` writes codes to a local temp file in `CodesForOfflineSearch/Json_Files/`, uploads to S3, and deletes the local temp file. Returns the S3 public URL.
   - From: `mvrt_fileExport`
   - To: AWS S3 (`uploadCodesToS3`)
   - Protocol: AWS SDK

3. **Submit subsequent chunks**: Browser POSTs additional chunks to `/createCodesList` with `isNewObject: false` and the same `tempFileName`.
   - From: Browser SPA
   - To: `mvrt_webRouting`
   - Protocol: REST/HTTP POST

4. **Append chunks to S3 object**: `mvrt_fileExport` downloads the existing S3 object, appends the new codes, re-uploads, and deletes the local temp file. This repeats until all chunks are submitted.
   - From: `mvrt_fileExport`
   - To: AWS S3 (`getObject` + `uploadCodesToS3`)
   - Protocol: AWS SDK

5. **Finalise job via createJsonFile**: Browser POSTs to `/createJsonFile` with `tempFileName`, `codeType`, `action`, `fileType` (xlsx/csv), `redemptionNotes`, `all_countries_reqd`, and user context.
   - From: Browser SPA
   - To: `mvrt_webRouting`
   - Protocol: REST/HTTP POST

6. **Download full code list from S3**: `mvrt_fileExport` calls `s3Bucket.getAllCodes` to retrieve the complete comma-separated code list from the temporary S3 object.
   - From: `mvrt_fileExport`
   - To: AWS S3 (`getObject`)
   - Protocol: AWS SDK

7. **Write job JSON file to local filesystem**: `mvrt_fileExport` constructs the job descriptor JSON (including user context, code list, code type, file type, i18n country, and host name) and writes it to `CodesForOfflineSearch/Json_Files/<tempFileName>.json`.
   - From: `mvrt_fileExport` (internal)
   - Protocol: Filesystem write

8. **Delete temporary S3 object**: `mvrt_fileExport` calls `s3Bucket.deleteCodesObject` to clean up the temporary codes object from S3.
   - From: `mvrt_fileExport`
   - To: AWS S3 (`deleteObject`)
   - Protocol: AWS SDK

9. **Acknowledge to browser**: `mvrt_webRouting` returns HTTP 200 JSON to the browser confirming the job is queued.
   - From: `mvrt_webRouting`
   - To: Browser SPA
   - Protocol: REST/HTTP 200 JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| S3 upload error on chunk | Error logged as `[S3-BUCKET-ERROR]`; promise rejected | Browser receives error response; user must retry |
| S3 getObject error (append mode) | Error logged; promise rejected | Browser receives error; partial codes lost; retry required |
| Local filesystem write error | Error logged | Job file not created; offline job will not be queued |
| S3 deleteObject error | Error logged; does not block main flow | Temporary S3 object may persist; manual cleanup required |

## Sequence Diagram

```
Browser -> mvrt_webRouting: POST /createCodesList {codes, isNewObject:true, tempFileName}
mvrt_webRouting -> mvrt_fileExport: uploadCodesToS3 (new object)
mvrt_fileExport -> aws-s3: PUT <tempFileName> (codes chunk 1)
aws-s3 --> mvrt_fileExport: success
mvrt_fileExport --> mvrt_webRouting: S3 URL
mvrt_webRouting --> Browser: 200 OK

Browser -> mvrt_webRouting: POST /createCodesList {codes, isNewObject:false, tempFileName}
mvrt_webRouting -> mvrt_fileExport: readAndUploadCodesToS3 (append)
mvrt_fileExport -> aws-s3: GET <tempFileName>
aws-s3 --> mvrt_fileExport: existing codes
mvrt_fileExport -> aws-s3: PUT <tempFileName> (existing + new codes)
mvrt_webRouting --> Browser: 200 OK

Browser -> mvrt_webRouting: POST /createJsonFile {tempFileName, codeType, fileType, ...}
mvrt_webRouting -> mvrt_fileExport: getAllCodes + createJobFile
mvrt_fileExport -> aws-s3: GET <tempFileName>
aws-s3 --> mvrt_fileExport: full codes list
mvrt_fileExport -> filesystem: write Json_Files/<tempFileName>.json
mvrt_fileExport -> aws-s3: DELETE <tempFileName>
mvrt_webRouting --> Browser: 200 OK (job queued)
```

## Related

- Architecture dynamic view: `dynamic-search_and_redeem_flow`
- Related flows: [Offline Search Batch Processing](offline-batch-processing.md), [Offline Report Download](offline-report-download.md)
