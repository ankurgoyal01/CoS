---
service: "file-sharing-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumFileSharingMySql"
    type: "mysql"
    purpose: "Primary store for user credentials, file metadata, and temporary file content blobs"
---

# Data Stores

## Overview

File Sharing Service owns a single MySQL database (`file_sharing_service`) that serves as the primary record of truth for registered users (with their Google OAuth2 tokens), file metadata (UUID, filename, status, Google Drive file ID), and temporary binary file content (stored as `LONGBLOB` until uploaded to Google Drive or until the `delete-at` timestamp is reached). Schema migrations are managed with Lobos. Google Drive is the long-term file storage destination — MySQL blobs are transient.

## Stores

### File Sharing MySQL (`continuumFileSharingMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumFileSharingMySql` |
| Purpose | Stores registered users (OAuth tokens), file metadata, and temporary file content blobs |
| Ownership | owned |
| Migrations path | `src/lobos/migrations.clj` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `users` | Registered Google accounts with OAuth2 access/refresh tokens | `uuid` (CHAR 36, unique), `email` (VARCHAR 255, unique), `desc`, `current-token`, `current-token-expires-at`, `refresh-token`, `created-at`, `updated-at` |
| `files` | File metadata record created per upload | `uuid` (CHAR 36, unique), `user-id` (FK to users, nullable), `external-file-id` (Google Drive file ID), `external-file-id-type` (e.g. `"google"`), `filename`, `status` (`waiting_for_download`, `downloaded`, `uploaded`), `created-at`, `updated-at` |
| `file_contents` | Temporary binary file storage | `file-id` (FK to files), `content` (LONGBLOB), `delete-at` (DATETIME, nullable), `deleted-at` (DATETIME, nullable), `created-at`, `updated-at` |
| `lobos_migrations` | Migration tracking table managed by Lobos | `name` |

#### Access Patterns

- **Read**: Fetch user by UUID or email for token refresh and Drive credential construction; fetch file by UUID or ID for download/share; query `file_contents` joined to `files` where `delete-at <= now AND deleted-at IS NULL` for scheduled blob clearing
- **Write**: Insert user record on registration; create file record on upload; insert `file_contents` blob on `POST /files`; update file status and `external-file-id` after Google Drive upload; zero-out blob content (write empty bytes + set `deleted-at`) on scheduled clear; delete `file_contents` row after Google Drive upload via `POST /files/upload`
- **Indexes**: `users(uuid)`, `users(email)`, `users(current-token)`, `users(refresh-token)`, `files(uuid)`, `files(external-file-id, external-file-id-type)`, `files(filename)`, `files(status)`, `file_contents(delete-at)`, `file_contents(deleted-at)`

## Caches

> No evidence found in codebase. No in-memory or external cache is used.

## Data Flows

1. On `POST /files`: binary content is written to local disk under `uploads/<user-uuid>/` then read back and stored as a `LONGBLOB` in `file_contents`.
2. On `POST /files/upload`: binary content is written to local disk, then uploaded directly to Google Drive; the `file_contents` row is deleted after a successful Drive upload, and the `files` record is updated with the `external-file-id`.
3. On `POST /files/share` when file is not yet on Drive: the service first calls the upload path (writing to Drive and clearing `file_contents`), then issues share permissions.
4. Daily at midnight (cron): the `daily-clear-file-content-task` queries for `file_contents` rows where `delete-at` has passed and `deleted-at` is null, then overwrites the `content` column with an empty byte array and sets `deleted-at` to the current timestamp.
