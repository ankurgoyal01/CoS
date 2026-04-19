---
service: "file-sharing-service"
title: "Scheduled File Content Expiry"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-file-content-expiry"
flow_type: scheduled
trigger: "Daily cron at midnight UTC (cronj schedule: 0 0 0 * * * *)"
participants:
  - "continuumFileSharingService"
  - "continuumFileSharingMySql"
architecture_ref: "components-continuumFileSharingService"
---

# Scheduled File Content Expiry

## Summary

This scheduled flow runs nightly at midnight UTC and clears binary file content blobs from MySQL that have passed their `delete-at` expiry timestamp. It is designed to prevent unbounded growth of the `file_contents` table. Rather than physically deleting rows, it overwrites the `content` column with an empty byte array and stamps `deleted-at` with the current time, preserving the metadata record while freeing the BLOB storage. After clearing, a `GET /files/{fileUuid}` for that file returns HTTP 410.

## Trigger

- **Type**: schedule
- **Source**: `cronj` scheduler started internally by `task/start`; cron expression `0 0 0 * * * *` (every day at 00:00:00)
- **Frequency**: Daily at midnight UTC

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Task Scheduler (cronj) | Fires `daily-clear-file-content-task` according to schedule | `continuumFileSharingService` |
| File Service | Queries for expired file IDs; clears each blob | `continuumFileSharingService` |
| Database Access | Executes raw SQL query and update operations | `continuumFileSharingService` |
| File Sharing MySQL | Source of `file_contents` rows; receives blob clear updates | `continuumFileSharingMySql` |

## Steps

1. **Scheduler fires task**: `cronj` triggers `daily-clear-file-content-task-handler` at 00:00:00 UTC with the current timestamp as `now`.
   - From: `continuumFileSharingService` (Task Scheduler)
   - To: `continuumFileSharingService` (File Service)
   - Protocol: internal function call

2. **Query for expired file IDs**: File Service executes a raw SQL query against MySQL:
   ```sql
   SELECT files.id
   FROM files
   INNER JOIN file_contents ON files.id = file_contents.`file-id`
   WHERE file_contents.`delete-at` <= ?
     AND file_contents.`deleted-at` IS NULL
   ```
   The `now` timestamp is passed as the parameter. Returns a list of `file.id` values.
   - From: `continuumFileSharingService` (File Service)
   - To: `continuumFileSharingMySql`
   - Protocol: JDBC

3. **Clear each blob**: For each returned file ID, File Service:
   - Fetches the `file_contents` row by `file-id`
   - Updates the `file_contents` row: sets `content` to an empty byte array (`""`) and `deleted-at` to the current timestamp
   - From: `continuumFileSharingService` (File Service)
   - To: `continuumFileSharingMySql`
   - Protocol: JDBC

4. **Task completes**: cronj logs task status; the hourly `:status-task` will report scheduler health at the next hour boundary.
   - From: `continuumFileSharingService` (Task Scheduler)
   - To: log output
   - Protocol: Log4j

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL query fails | Exception propagates within the task handler; cronj logs it | That run fails; next run will retry at midnight the following day |
| Individual blob clear fails | Exception propagates from `doseq`; remaining IDs may not be processed in that run | Partial clear; unprocessed rows will be retried on the next scheduled run (since `deleted-at` is still null) |
| Scheduler not running | `GET /tasks/start` must be called to reinitialize | No expiry clearing until scheduler is restarted |

## Sequence Diagram

```
cronj Scheduler -> File Service: daily-clear-file-content-task-handler(now)
File Service -> MySQL: SELECT files.id FROM files JOIN file_contents WHERE delete-at <= now AND deleted-at IS NULL
MySQL --> File Service: [{id: 123}, {id: 456}, ...]
loop for each file id
  File Service -> MySQL: SELECT * FROM file_contents WHERE file-id=<id>
  MySQL --> File Service: file_contents row
  File Service -> MySQL: UPDATE file_contents SET content=<empty>, deleted-at=<now> WHERE id=<contents-id>
end
```

## Related

- Architecture component: `taskScheduler` within `continuumFileSharingService`
- Related flows: [File Content Store](file-content-store.md)
- Task control endpoints: `GET /tasks/start`, `GET /tasks/status`, `GET /tasks/stop`
