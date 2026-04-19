---
service: "file-transfer"
title: "Check Unprocessed Files"
generated: "2026-03-03"
type: flow
flow_name: "check-unprocessed-files"
flow_type: scheduled
trigger: "Kubernetes CronJob on schedule 0 1 */1 * * (daily at 01:00 UTC)"
participants:
  - "fileTransfer_jobRunner"
  - "fileProcessor"
  - "fileTransferRepository"
  - "continuumFileTransferDatabase"
architecture_ref: "dynamic-sync-files"
---

# Check Unprocessed Files

## Summary

The check-unprocessed-files flow runs once per day after the sync-files CronJob completes. It queries the `job_files` table for any files that were seen (a row was created) but never successfully processed (i.e., `processed_at IS NULL`) and that are older than one day. For each such file it logs a structured error, which is picked up by Splunk for alerting. This flow acts as a safety net to detect any silent failures in the sync-files flow.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob `unprocessed` — schedule `0 1 */1 * *`
- **Frequency**: Daily at 01:00 UTC; invokes `run-job.sh check-jobs _`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Job Runner | Receives CLI arguments and invokes `execute-job` with `check-jobs` function | `fileTransfer_jobRunner` |
| File Processor | Executes `check-jobs`; queries for unprocessed files and logs errors | `fileProcessor` |
| File Transfer Repository | Queries `job_files` for stale unprocessed rows | `fileTransferRepository` |
| file_transfer MySQL | Persistence layer for `job_files` table | `continuumFileTransferDatabase` |

## Steps

1. **Receives job invocation**: The Kubernetes CronJob executes `run-job.sh check-jobs _`. The `-main` function reads `check-jobs` as the job function and `_` as a placeholder job name.
   - From: Kubernetes CronJob
   - To: `fileTransfer_jobRunner`
   - Protocol: process exec

2. **Invokes `check-jobs` function**: `execute-job` resolves and calls `file-transfer.core/check-jobs` with the placeholder arguments.
   - From: `fileTransfer_jobRunner`
   - To: `fileProcessor` (`check-jobs` fn)
   - Protocol: direct (in-process)

3. **Queries for unprocessed files**: Calls `db/get-unprocessed-files`, which runs:
   ```sql
   SELECT * FROM job_files
   WHERE processed_at IS NULL
   AND   created_at <= NOW() - INTERVAL 1 DAY
   ```
   - From: `fileTransferRepository`
   - To: `continuumFileTransferDatabase`
   - Protocol: JDBC/MySQL (TCP 3306)

4. **Logs an alert for each unprocessed file**: If any rows are returned, emits a structured error log event for each: `{:type :file/unprocessed :investigate-cause? true :file <row>}`.
   - From: `fileProcessor`
   - To: Log output (Filebeat → Kafka → ELK / Splunk)
   - Protocol: stdout (structured JSON via log-data)

5. **Job completes**: If no unprocessed files exist, the function returns silently with no log output. Logs `job/finished` event.
   - From: `fileTransfer_jobRunner`
   - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL query fails | Exception propagates to `execute-job`; `retry-job` called | Up to 3 retries; if all fail, logs `job/out-of-retries` |
| Unprocessed files detected | Logs `file/unprocessed` error per file | Splunk alert is expected to fire; human investigation required |

## Sequence Diagram

```
CronJob        -> JobRunner    : exec run-job.sh check-jobs _
JobRunner      -> FileProcessor: execute-job "check-jobs" "_"
FileProcessor  -> Repository   : get-unprocessed-files
Repository     -> MySQL        : SELECT * FROM job_files WHERE processed_at IS NULL AND created_at <= NOW() - 1 DAY
MySQL         --> Repository   : unprocessed rows (may be empty)
Repository    --> FileProcessor: file list
FileProcessor  -> Log          : log/error {:type :file/unprocessed ...} (for each file)
JobRunner      -> Log          : log/info {:type :job/finished}
```

## Related

- Architecture dynamic view: `dynamic-sync-files`
- Related flows: [Sync Files](sync-files.md), [Job Retry](job-retry.md)
