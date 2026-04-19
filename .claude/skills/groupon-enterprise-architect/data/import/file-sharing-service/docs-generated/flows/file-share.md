---
service: "file-sharing-service"
title: "File Share"
generated: "2026-03-03"
type: flow
flow_name: "file-share"
flow_type: synchronous
trigger: "POST /files/share"
participants:
  - "continuumFileSharingService"
  - "continuumFileSharingMySql"
  - "googleDriveApi"
architecture_ref: "components-continuumFileSharingService"
---

# File Share

## Summary

This flow allows a caller to share a previously uploaded file with one or more email addresses via Google Drive permissions. The caller provides a `file-uuid` and a list of sharing details (email, email-type). If the file has not yet been uploaded to Google Drive, the service automatically triggers a Drive upload (and clears the MySQL blob) before creating the share permissions.

## Trigger

- **Type**: api-call
- **Source**: HTTP client calling `POST /files/share` with a JSON body
- **Frequency**: On demand, per share request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API | Receives request, dispatches to File Service, returns share result | `continuumFileSharingService` |
| File Service | Fetches file record, optionally triggers Drive upload, calls share for each recipient | `continuumFileSharingService` |
| Google Drive Client | Resolves Drive auth, creates permissions via Drive Permissions API | `continuumFileSharingService` |
| File Sharing MySQL | Source of file metadata; updated if Drive upload is triggered | `continuumFileSharingMySql` |
| Google Drive API v3 | Creates `Permission` objects for each recipient email | `googleDriveApi` |

## Steps

1. **Receive share request**: HTTP API receives `POST /files/share` with JSON body containing `file-uuid` and `sharing-details` (array of `{email, email-type?}`).
   - From: external caller
   - To: `continuumFileSharingService` (HTTP API)
   - Protocol: HTTP JSON

2. **Fetch file record**: File Service calls `fetch(file-uuid)` to retrieve the file metadata from MySQL, including `external-file-id` (Google Drive file ID) and `status`.
   - From: `continuumFileSharingService` (File Service)
   - To: `continuumFileSharingMySql`
   - Protocol: JDBC

3. **Upload to Drive if not already there** (conditional): If the file record has no `external-file-id`, File Service triggers the full Drive upload flow (`upload(file, :google)`) and then deletes the MySQL `file_contents` blob (`delete-file-contents`).
   - From: `continuumFileSharingService` (File Service)
   - To: `continuumFileSharingMySql` (blob deletion) and `googleDriveApi` (upload)
   - Protocol: JDBC / HTTPS

4. **Resolve Drive authentication**: Google Drive Client applies the three-tier auth resolution (service account → delegation → OAuth) to obtain a valid `Drive` instance. See [File Upload to Google Drive](file-upload-to-google-drive.md) for auth tier details.
   - From: `continuumFileSharingService` (Google Drive Client)
   - To: internal resolution
   - Protocol: internal

5. **Create share permissions**: For each entry in `sharing-details`, Google Drive Client calls `Drive.permissions().create(google-file-id, permission)` with `emailAddress`, `type` (default `"user"`), and `role` (default `"reader"`). `supportsAllDrives=true` is set. Each call is retried up to 5 times.
   - From: `continuumFileSharingService` (Google Drive Client)
   - To: `googleDriveApi`
   - Protocol: HTTPS (Drive API v3 Permissions)

6. **Return result**: HTTP API returns the lazy sequence of permission creation results as JSON.
   - From: `continuumFileSharingService` (HTTP API)
   - To: external caller
   - Protocol: HTTP JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| File not found in MySQL | `file` is nil; `external-file-id` check triggers upload path; upload fails if file was never stored | HTTP 500 or partial result |
| Drive upload fails (not yet on Drive) | Exception from upload propagates | HTTP 500 to caller |
| Permission creation fails (after 5 retries) | Exception propagates for that sharing detail | HTTP 500 to caller |
| All auth tiers fail | RuntimeException thrown by `get-drive-service` | HTTP 500 to caller |

## Sequence Diagram

```
Caller -> HTTP API: POST /files/share {file-uuid, sharing-details: [{email, email-type?}]}
HTTP API -> File Service: fetch(file-uuid)
File Service -> MySQL: SELECT * FROM files WHERE uuid=<file-uuid>
MySQL --> File Service: file record (with or without external-file-id)
alt file not on Drive
  File Service -> Google Drive Client: upload(file, :google)
  Google Drive Client -> Google Drive API: files.create(...)
  Google Drive API --> Google Drive Client: {id: "<drive-file-id>"}
  File Service -> MySQL: DELETE FROM file_contents WHERE file-id=<id>
  File Service -> MySQL: UPDATE files SET external-file-id, status='uploaded'
end
File Service -> Google Drive Client: share(file, sharing-details)
Google Drive Client -> Google Drive Client: get-drive-service(user)
loop for each sharing-detail
  Google Drive Client -> Google Drive API: permissions.create(google-file-id, {email, type, role})
  Google Drive API --> Google Drive Client: permission object
end
HTTP API --> Caller: [permission results]
```

## Related

- Architecture dynamic view: `dynamic-FileUploadToGoogleDrive`
- Related flows: [File Upload to Google Drive](file-upload-to-google-drive.md), [File Content Store](file-content-store.md)
