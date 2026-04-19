---
service: "file-sharing-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for File Sharing Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [File Upload to Google Drive](file-upload-to-google-drive.md) | synchronous | `POST /files/upload` | Persists file locally, selects Google Drive auth method, uploads to Drive, updates file record |
| [File Content Store (Local Only)](file-content-store.md) | synchronous | `POST /files` | Persists file locally and stores binary blob in MySQL with optional expiry timestamp |
| [File Share](file-share.md) | synchronous | `POST /files/share` | Shares an uploaded file on Google Drive with one or more email addresses; uploads to Drive first if not already there |
| [User Registration](user-registration.md) | synchronous | `POST /users/register` | Exchanges a Google OAuth2 auth code for tokens, validates domain, creates user record |
| [Scheduled File Content Expiry](scheduled-file-content-expiry.md) | scheduled | Daily cron at midnight UTC | Queries for expired `file_contents` blobs and clears them from MySQL |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The dynamic view `dynamic-FileUploadToGoogleDrive` in the central architecture model documents the cross-system interaction:

1. `continuumFileSharingService` → `continuumFileSharingMySql` — creates file record and stores contents
2. `continuumFileSharingService` → `googleOAuth` — authorizes or refreshes token
3. `continuumFileSharingService` → `googleDriveApi` — uploads file (Drive API v3)

See [Architecture Context](../architecture-context.md) for container and relationship references.
