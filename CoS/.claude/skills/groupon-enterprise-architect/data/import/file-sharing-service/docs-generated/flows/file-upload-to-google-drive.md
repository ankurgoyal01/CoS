---
service: "file-sharing-service"
title: "File Upload to Google Drive"
generated: "2026-03-03"
type: flow
flow_name: "file-upload-to-google-drive"
flow_type: synchronous
trigger: "POST /files/upload"
participants:
  - "continuumFileSharingService"
  - "continuumFileSharingMySql"
  - "googleOAuth"
  - "googleDriveApi"
architecture_ref: "dynamic-FileUploadToGoogleDrive"
---

# File Upload to Google Drive

## Summary

This flow handles the complete path for uploading a file to Google Drive via the service. The caller submits a multipart form with file data and an optional `user-uuid`. The service saves the file to the local filesystem, creates a MySQL record, determines the appropriate Google Drive authentication method, uploads the file to Drive, deletes the local MySQL blob, and returns the `file-uuid` to the caller.

## Trigger

- **Type**: api-call
- **Source**: HTTP client (internal Groupon service or admin tool) calling `POST /files/upload`
- **Frequency**: On demand, per upload request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API | Receives request, extracts `user-uuid` and file data, returns response | `continuumFileSharingService` |
| File Service | Orchestrates local persistence, Drive upload, DB update, blob deletion | `continuumFileSharingService` |
| Google Drive Client | Resolves auth method, constructs Drive instance, calls Drive API | `continuumFileSharingService` |
| File Sharing MySQL | Stores file metadata and blob; receives status updates | `continuumFileSharingMySql` |
| Google OAuth2 API | Provides/refreshes OAuth2 tokens for per-user Drive access (Tier 3 fallback) | `googleOAuth` |
| Google Drive API v3 | Receives the file upload and stores it; returns a file ID | `googleDriveApi` |

## Steps

1. **Receive upload request**: HTTP API receives `POST /files/upload` with multipart `file-data` and optional `user-uuid`.
   - From: external caller
   - To: `continuumFileSharingService` (HTTP API)
   - Protocol: HTTP multipart/form-data

2. **Persist file locally**: File Service writes the uploaded file bytes to disk under `uploads/<user-uuid>/` (or `uploads/nil/` if no user) using `noir.io/upload-file`. A `files` record is created in MySQL with status `waiting_for_download`, then updated to `downloaded` with the filename.
   - From: `continuumFileSharingService` (File Service)
   - To: `continuumFileSharingMySql`
   - Protocol: JDBC

3. **Resolve Drive authentication method**: Google Drive Client evaluates `GOOGLE_AUTH_MODE` and attempts tiers in order:
   - **Tier 1**: Load service account JSON key from `GOOGLE_SERVICE_ACCOUNT_JSON_PATH`; create Drive service targeting `GOOGLE_SHARED_DRIVE_FOLDER_ID`
   - **Tier 2** (if Tier 1 fails and `GOOGLE_DELEGATED_USER_EMAIL` is set): Create service account credential with domain-wide delegation; create Drive service
   - **Tier 3** (if Tier 2 fails or not configured and user is provided): Load user's `current-token`/`refresh-token` from MySQL; construct OAuth2 credential; refresh token if expiring within 5 minutes
   - From: `continuumFileSharingService` (Google Drive Client)
   - To: `googleOAuth` (Tier 3 token refresh only)
   - Protocol: HTTPS / Google OAuth2 SDK

4. **Upload file to Google Drive**: Google Drive Client calls `Drive.files().create()` with file metadata and binary content, setting `supportsAllDrives=true` and `parents=[folder-id]` for shared drives. Retried up to 5 times.
   - From: `continuumFileSharingService` (Google Drive Client)
   - To: `googleDriveApi`
   - Protocol: HTTPS (Drive API v3)

5. **Delete MySQL blob**: After a successful Drive upload, File Service calls `delete-file-contents` to remove the `file_contents` row for this file.
   - From: `continuumFileSharingService` (File Service)
   - To: `continuumFileSharingMySql`
   - Protocol: JDBC

6. **Update file record**: File Service updates the `files` row with `external-file-id` (Google Drive file ID), `external-file-id-type = "google"`, and `status = "uploaded"`.
   - From: `continuumFileSharingService` (File Service)
   - To: `continuumFileSharingMySql`
   - Protocol: JDBC

7. **Return response**: HTTP API returns JSON `{"file-uuid": "<uuid>"}` to the caller.
   - From: `continuumFileSharingService` (HTTP API)
   - To: external caller
   - Protocol: HTTP JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Tier 1 (service account) fails | Log crit; emit metrics; try Tier 2 (delegation) if configured | Proceeds to next tier |
| Tier 2 (delegation) fails | Log crit; emit metrics; try Tier 3 (OAuth) if user provided | Proceeds to next tier |
| Tier 3 (OAuth) fails or no user | Throw RuntimeException with all failure messages | HTTP 500 to caller |
| Forced mode (non-auto) fails | Throw RuntimeException immediately; no fallback | HTTP 500 to caller |
| Drive upload fails (up to 5 retries) | Exception thrown after all retries exhausted; metrics emitted | HTTP 500 to caller |
| MySQL write fails | Exception propagates; no partial state cleanup | HTTP 500 to caller |

## Sequence Diagram

```
Caller -> HTTP API: POST /files/upload (multipart: file-data, user-uuid)
HTTP API -> File Service: persist-file-locally(file-data, user-uuid)
File Service -> MySQL: INSERT INTO files (uuid, user-id, status='waiting_for_download')
File Service -> MySQL: UPDATE files SET filename, status='downloaded'
File Service -> Google Drive Client: upload(file, :google)
Google Drive Client -> Google Drive Client: get-drive-service(user) [tier resolution]
Google Drive Client --> Google OAuth: refresh token (if Tier 3 and near-expiry)
Google OAuth --> Google Drive Client: refreshed access token
Google Drive Client -> Google Drive API: files.create(filename, content, parent-folder-id)
Google Drive API --> Google Drive Client: {id: "<drive-file-id>"}
File Service -> MySQL: DELETE FROM file_contents WHERE file-id=<id>
File Service -> MySQL: UPDATE files SET external-file-id, external-file-id-type='google', status='uploaded'
HTTP API --> Caller: {"file-uuid": "<uuid>"}
```

## Related

- Architecture dynamic view: `dynamic-FileUploadToGoogleDrive`
- Related flows: [File Content Store](file-content-store.md), [File Share](file-share.md)
