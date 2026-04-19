---
service: "mds-feed-api"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for the Marketing Feed Service (mds-feed-api).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Feed Configuration Lifecycle](feed-configuration-lifecycle.md) | synchronous | API call (POST/PUT/PATCH/DELETE `/feed`) | Create, update, patch, and delete feed configurations |
| [Scheduled Feed Generation](scheduled-feed-generation.md) | scheduled | Quartz cron via feed group schedule | Automatic periodic Spark job submission for all feeds in a group |
| [Manual Feed Generation](manual-feed-generation.md) | synchronous | API call (POST `/sparkjob/{feedUuid}`) | Operator-triggered Spark job submission for a single feed |
| [Batch Status Polling](batch-status-polling.md) | scheduled | Quartz cron (every minute) | Polls Livy API to update batch states and publish completion events |
| [Feed File Upload](feed-file-upload.md) | synchronous | API call (GET `/upload/feed/{feedUuid}`) | Orchestrates upload of a generated feed file to an external destination |
| [Feed File Dispatch](feed-file-dispatch.md) | synchronous | API call (GET `/dispatcher/feed/{feedUuid}`) | Resolves and returns a download URL for a generated feed file |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |
| Mixed (triggered synchronously, executed asynchronously) | 1 |

## Cross-Service Flows

- **Scheduled Feed Generation** spans `continuumMdsFeedApi` → Apache Livy → `mds-feed-job` (Spark) → GCS → `continuumMdsFeedApi` (metrics callback). See [Scheduled Feed Generation](scheduled-feed-generation.md).
- **Batch Status Polling** triggers an Mbus publish to `mds-feed-publishing` which crosses into downstream marketing systems. See [Batch Status Polling](batch-status-polling.md).
- **Feed File Upload** spans `continuumMdsFeedApi` → GCS (download) → external SFTP/S3/GCP partner. See [Feed File Upload](feed-file-upload.md).
