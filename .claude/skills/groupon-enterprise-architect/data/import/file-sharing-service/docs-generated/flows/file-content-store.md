---
service: "file-sharing-service"
title: "File Content Store (Local Only)"
generated: "2026-03-03"
type: flow
flow_name: "file-content-store"
flow_type: synchronous
trigger: "POST /files"
participants:
  - "continuumFileSharingService"
  - "continuumFileSharingMySql"
architecture_ref: "components-continuumFileSharingService"
---

# File Content Store (Local Only)

## Summary

This flow handles the storage of a file's binary content in the local MySQL database without immediately uploading it to Google Drive. It is used when callers want to stage a file in the service with an optional expiry timestamp (`content-delete-at`), deferring Drive upload to a later explicit call or `POST /files/share`. The caller receives a `file-uuid` that can be used to retrieve the file as long as it has not been cleared.

## Trigger

- **Type**: api-call
- **Source**: HTTP client calling `POST /files` with multipart `file-data` and optional `user-uuid` and `content-delete-at`
- **Frequency**: On demand, per upload request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API | Receives request, extracts parameters, returns JSON response | `continuumFileSharingService` |
| File Service | Orchestrates local disk write, file record creation, blob storage | `continuumFileSharingService` |
| Database Access | Inserts and updates records in MySQL | `continuumFileSharingService` |
| File Sharing MySQL | Stores file metadata (`files`) and binary blob (`file_contents`) | `continuumFileSharingMySql` |

## Steps

1. **Receive store request**: HTTP API receives `POST /files` with multipart `file-data`, optional `user-uuid`, and optional `content-delete-at` (ISO 8601 datetime string).
   - From: external caller
   - To: `continuumFileSharingService` (HTTP API)
   - Protocol: HTTP multipart/form-data

2. **Persist file locally**: File Service calls `persist-file-locally` — looks up the user record by `user-uuid` (allows nil user for system uploads), creates a `files` row with `status = "waiting_for_download"`, writes the file bytes to `uploads/<user-uuid>/<file-uuid>-<filename>` on local disk, then updates the `files` row with `filename` and `status = "downloaded"`.
   - From: `continuumFileSharingService` (File Service)
   - To: `continuumFileSharingMySql`
   - Protocol: JDBC

3. **Store file contents blob**: File Service calls `save-file-contents`, reading the file back from disk as a byte array and inserting into `file_contents` with the `file-id`, the raw `LONGBLOB` content, and the parsed `delete-at` timestamp (if provided).
   - From: `continuumFileSharingService` (File Service)
   - To: `continuumFileSharingMySql`
   - Protocol: JDBC

4. **Return response**: HTTP API returns JSON `{"file-uuid": "<uuid>"}` to the caller.
   - From: `continuumFileSharingService` (HTTP API)
   - To: external caller
   - Protocol: HTTP JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `user-uuid` not found in DB | User is `nil`; file is created with `user_id = NULL` (backward-compatible behavior); warning logged | Upload proceeds without user association |
| Disk write fails | Exception propagates from `noir.io/upload-file` | HTTP 500 to caller |
| MySQL insert fails | Exception propagates from Korma | HTTP 500 to caller |
| `content-delete-at` parse fails | `clj-time.format/parse` throws; exception propagates | HTTP 500 to caller |

## Sequence Diagram

```
Caller -> HTTP API: POST /files (multipart: file-data, user-uuid?, content-delete-at?)
HTTP API -> File Service: persist-file-locally(file-data, user-uuid)
File Service -> MySQL: INSERT INTO files (uuid, user-id, status='waiting_for_download')
File Service -> Local Disk: write bytes to uploads/<user-uuid>/<uuid>-<filename>
File Service -> MySQL: UPDATE files SET filename, status='downloaded'
HTTP API -> File Service: save-file-contents(file, delete-at)
File Service -> Local Disk: read bytes back as byte array
File Service -> MySQL: INSERT INTO file_contents (file-id, content LONGBLOB, delete-at)
HTTP API --> Caller: {"file-uuid": "<uuid>"}
```

## Related

- Architecture dynamic view: `dynamic-FileUploadToGoogleDrive`
- Related flows: [File Upload to Google Drive](file-upload-to-google-drive.md), [Scheduled File Content Expiry](scheduled-file-content-expiry.md)
