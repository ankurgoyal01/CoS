---
service: "file-transfer"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumFileTransferDatabase"
    type: "mysql"
    purpose: "Tracks per-job file processing state for deduplication and unprocessed-file alerting"
---

# Data Stores

## Overview

File Transfer Service owns a single MySQL database (`file_transfer`) with one table (`job_files`). The table serves two purposes: deduplication (preventing re-processing of files already seen by a job) and alerting (detecting files that were recorded as "seen" but never successfully processed within one day).

## Stores

### file_transfer MySQL (`continuumFileTransferDatabase`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumFileTransferDatabase` |
| Purpose | Stores job file metadata and processing state |
| Ownership | owned |
| Migrations path | `src/migrations/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `job_files` | One row per file seen by a job; tracks processing lifecycle | `id`, `job_name`, `filename`, `external_id` (FSS UUID), `size`, `processed_at`, `created_at`, `updated_at` |

Schema (from `src/migrations/20140428132414-create-table-job-files.up.sql`):

```sql
CREATE TABLE IF NOT EXISTS job_files (
  id            int(11)      NOT NULL AUTO_INCREMENT,
  job_name      varchar(255) NOT NULL,
  filename      varchar(255) NOT NULL,
  external_id   varchar(255),          -- FSS UUID (added in migration 20140627)
  size          int(11)      DEFAULT 0,
  processed_at  datetime     DEFAULT NULL,
  created_at    timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    datetime     DEFAULT NULL,
  PRIMARY KEY (id),
  KEY job_files_index_job_name (job_name),
  KEY job_files_index_processed_at (processed_at)
) DEFAULT CHARSET=utf8
```

#### Access Patterns

- **Read**: Before processing a job, all previously processed files for that job (`processed_at IS NOT NULL`) are loaded into memory and used for deduplication (`get-previously-seen-files-for`). The `check-jobs` job queries for unprocessed files older than one day (`processed_at IS NULL AND created_at <= NOW() - 1 day`).
- **Write**: A new row is inserted when a file is first seen (`create-new-file`). The row is updated to set `processed_at` and `external_id` (FSS UUID) once the file has been successfully uploaded and the notification published (`mark-file-as-processed`).
- **Indexes**: `job_files_index_job_name` supports per-job file lookups; `job_files_index_processed_at` supports the unprocessed-file scan used by `check-jobs`.

## Caches

> No evidence found in codebase. No cache layer is used.

## Data Flows

All processed file state flows unidirectionally: the SFTP server is the source, files are written locally to `/tmp/transfer-files`, uploaded to FSS, and the resulting FSS UUID is persisted back to `job_files.external_id`. The `job_files` table is not replicated or exported to any other store.
