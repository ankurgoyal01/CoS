---
service: "file-transfer"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for File Transfer Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Sync Files](sync-files.md) | scheduled | Daily CronJob (`30 0 */1 * *`) | Retrieves new files from an SFTP server, uploads them to FSS, and publishes notifications |
| [Check Unprocessed Files](check-unprocessed-files.md) | scheduled | Daily CronJob (`0 1 */1 * *`) | Scans for files that have been seen but not processed within one day and logs an alert |
| [Job Retry](job-retry.md) | event-driven | Job execution error (any `Throwable`) | Retries a failed job up to 3 times with exponential back-off |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The [Sync Files](sync-files.md) flow spans multiple services: it touches the external SFTP server, the internal File Sharing Service, and the shared messagebus. The Structurizr dynamic view `dynamic-sync-files` captures this cross-service sequence.
