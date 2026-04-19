---
service: "file-transfer"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["mbus"]
---

# Events

## Overview

File Transfer Service publishes to a single JMS topic on the Groupon messagebus using a STOMP-protocol producer (`messagebus-clj`). It does not consume any async events; all work is triggered by scheduled CronJobs. The producer is a singleton that is started at the beginning of a `sync-files` job run and stopped (including connection teardown) in the `finally` block when the run completes.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.fed.FileTransfer` | File retrieval notification | File successfully uploaded to FSS | `filename`, `job-name`, `file-uuid` |

### File retrieval notification Detail

- **Topic**: `jms.topic.fed.FileTransfer`
- **Trigger**: A file has been downloaded from the SFTP server, uploaded to FSS, and its `job_files` record has been marked as processed
- **Payload**: JSON object containing:
  - `filename` — original filename on the SFTP server
  - `job-name` — name of the job that retrieved the file (e.g., `getaways_booking_files`)
  - `file-uuid` — FSS UUID returned by the File Sharing Service upload
- **Consumers**: Downstream consumers are tracked in the central architecture model; they subscribe independently to the JMS topic
- **Guarantees**: at-least-once (the producer uses JMS with no deduplication guarantee at the consumer side)

## Consumed Events

> No evidence found in codebase. This service does not consume any async events or queue messages.

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration is present in the repository.
