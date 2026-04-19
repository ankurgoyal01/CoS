---
service: "transporter-itier"
title: "CSV Upload Flow"
generated: "2026-03-03"
type: flow
flow_name: "csv-upload-flow"
flow_type: synchronous
trigger: "User selects a CSV file and submits the upload form on /new-upload"
participants:
  - "continuumTransporterItierWeb"
  - "uploadProxy"
  - "jtierClient"
  - "transporterJtierSystem_7f3a2c"
architecture_ref: "dynamic-upload-flow"
---

# CSV Upload Flow

## Summary

This flow enables internal Groupon employees to bulk-insert, update, or delete records in Salesforce by uploading a CSV file through the Transporter I-Tier web portal. The browser parses the CSV client-side to validate format and count rows, then posts the file to the I-Tier upload proxy, which buffers it in memory and streams it directly to the `transporter-jtier` backend. The jtier service performs the actual Salesforce bulk operation asynchronously and stores the job record.

## Trigger

- **Type**: user-action
- **Source**: User submits the upload form on the `/new-upload` page by selecting a CSV file, choosing a Salesforce action (insert/update/delete) and object type, then clicking "Upload"
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (Preact Upload component) | Parses CSV client-side, constructs FormData, and posts to the proxy endpoint | `transporterItier_webUi` |
| JTIER Upload Proxy | Receives multipart upload, buffers file in memory, proxies to jtier | `uploadProxy` |
| JTIER Client | Used by the new-upload page load to validate the user before rendering the form | `jtierClient` |
| transporter-jtier | Receives the CSV binary, triggers Salesforce bulk operation, persists job record | `transporterJtierSystem_7f3a2c` |

## Steps

1. **User navigates to `/new-upload`**: The `uploadProxy` component's page action validates the user via jtier before rendering the form.
   - From: `Browser`
   - To: `continuumTransporterItierWeb`
   - Protocol: HTTPS

2. **Validate user**: The server calls jtier to confirm the user is registered.
   - From: `jtierClient`
   - To: `transporter-jtier GET /validUser?user=<username>`
   - Protocol: HTTP

3. **Render upload form**: If user is valid, the server renders the upload page with a CSRF token embedded.
   - From: `continuumTransporterItierWeb`
   - To: `Browser`
   - Protocol: HTTPS (HTML response)

4. **User selects CSV file**: The browser-side Preact `Upload` component calls `Papa.parse` on the selected file to count rows and extract column headers. The file is validated as CSV format (`text/csv`, `application/vnd.ms-excel`, `application/csv`). A unique S3 key is generated as `<filename>_<uuidv4>.csv`.
   - From: `Browser (Preact Upload component)`
   - To: Local (client-side only)
   - Protocol: Browser File API

5. **User submits upload form**: The browser POSTs `multipart/form-data` to `/jtier-upload-proxy` with fields: `myFile` (binary), `action`, `object`, `batchSize` (default 200), `s3Key`, `recordsCount`, `userName`. The CSRF token is sent as `x-csrf-token` header.
   - From: `Browser`
   - To: `continuumTransporterItierWeb POST /jtier-upload-proxy`
   - Protocol: HTTPS (multipart/form-data)

6. **Upload proxy receives and buffers file**: The multer middleware with `memoryStorage` buffers the CSV binary in memory. The proxy resolves the jtier host from `DEPLOY_ENV`.
   - From: `uploadProxy`
   - To: Local (memory buffer)
   - Protocol: Internal

7. **Proxy streams CSV to jtier**: The upload proxy opens a plain HTTP connection to `transporter-jtier.{env}.service` port 80 and POSTs the CSV binary with `Content-Type: text/csv`. Query parameters encode the job metadata: `user`, `userInputFileName` (the S3 key), `salesforceObject`, `action`, `batchSize`, `inputFileRecords`.
   - From: `uploadProxy`
   - To: `transporter-jtier POST /v0/upload`
   - Protocol: HTTP

8. **jtier responds**: jtier stores the job record, triggers the Salesforce bulk operation, and returns an HTTP response. The proxy pipes the response (status and headers) directly back to the browser.
   - From: `transporter-jtier`
   - To: `uploadProxy` then `Browser`
   - Protocol: HTTP (piped)

9. **Browser displays result**: The Preact Upload component updates state to show success ("Successfully uploaded file to Itier server") or error message based on the HTTP status code (200 = success).
   - From: `Browser (Preact Upload component)`
   - To: User (UI update)
   - Protocol: Client-side state update

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Non-CSV file selected | Client-side validation in Preact component; rejects file | Error message displayed in browser; upload blocked |
| User not validated in jtier | Redirect to Salesforce OAuth login flow | User must authenticate before accessing the form |
| jtier upload endpoint unavailable | Proxy propagates HTTP error status | Browser Preact component catches axios error and displays "Error occurred in sending file to Itier server - <error>" |
| CSV upload returns non-200 | Axios `.catch` handler triggers UI error state | Error message shown; upload state reset |
| Missing required form fields (action, object, file) | HTML5 `required` attribute on select fields prevents submission | Form does not submit |

## Sequence Diagram

```
Browser          -> transporter-itier-web (GET /new-upload): Load upload page
transporter-itier-web -> transporter-jtier (GET /validUser?user=<u>): Validate user
transporter-jtier --> transporter-itier-web: 200 OK (user valid) or 4xx (invalid)
transporter-itier-web --> Browser: Render upload form (HTML + CSRF token)
Browser (local)  -> Browser (local): Papa.parse CSV, count rows, generate s3Key
Browser          -> transporter-itier-web (POST /jtier-upload-proxy): multipart/form-data + x-csrf-token
transporter-itier-web (uploadProxy) -> transporter-jtier (POST /v0/upload?...): CSV binary (text/csv)
transporter-jtier --> transporter-itier-web (uploadProxy): HTTP status + response
transporter-itier-web --> Browser: Piped response (status + headers)
Browser (Preact) -> Browser (Preact): Update UI state (success or error message)
```

## Related

- Architecture dynamic view: `dynamic-upload-flow`
- Related flows: [Salesforce OAuth Login Flow](salesforce-oauth-login-flow.md), [Job List and Pagination Flow](job-list-pagination-flow.md)
- [Flows Index](index.md)
