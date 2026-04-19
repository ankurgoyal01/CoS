---
service: "file-transfer"
title: "Sync Files"
generated: "2026-03-03"
type: flow
flow_name: "sync-files"
flow_type: scheduled
trigger: "Kubernetes CronJob on schedule 30 0 */1 * * (daily at 00:30 UTC)"
participants:
  - "fileTransfer_jobRunner"
  - "fileProcessor"
  - "sftpClient"
  - "fileTransferRepository"
  - "continuumFileTransferDatabase"
  - "fssClient"
  - "fileSharingService"
  - "messagebusProducer"
  - "messagebus"
architecture_ref: "dynamic-sync-files"
---

# Sync Files

## Summary

The sync-files flow is the primary job of File Transfer Service. It connects to a configured SFTP server, lists files in the target directory, filters out any already processed, downloads the new files to local temporary storage, uploads each to the File Sharing Service, records the transfer in MySQL, and publishes a notification to the messagebus. This flow runs once per day per configured job via a Kubernetes CronJob.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob `getaways` — schedule `30 0 */1 * *`
- **Frequency**: Daily at 00:30 UTC; invokes `run-job.sh sync-files getaways_booking_files`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Job Runner | Receives CLI arguments, prepares the job config, and invokes `execute-job` | `fileTransfer_jobRunner` |
| File Processor | Orchestrates all steps: retrieve, deduplicate, upload, persist, notify | `fileProcessor` |
| SFTP Client | Connects to the remote server, lists matching files, downloads new ones | `sftpClient` |
| File Transfer Repository | Queries previously processed files; creates and updates `job_files` records | `fileTransferRepository` |
| file_transfer MySQL | Persistence layer for `job_files` table | `continuumFileTransferDatabase` |
| File Sharing Service Client | Uploads file content to FSS and receives a UUID | `fssClient` |
| File Sharing Service (FSS) | Stores the file content and enforces the retention policy | `fileSharingService` (stub) |
| Messagebus Producer | Publishes a JSON notification to the JMS topic | `messagebusProducer` |
| Messagebus | JMS/STOMP broker that delivers notifications to subscribers | `messagebus` (stub) |

## Steps

1. **Receives job invocation**: The Kubernetes CronJob executes `run-job.sh sync-files getaways_booking_files`. The `-main` function reads the job function name and job name from CLI args and loads the job config from configuration.
   - From: Kubernetes CronJob
   - To: `fileTransfer_jobRunner`
   - Protocol: process exec

2. **Prepares job config**: Casts port, delete-after-in-years, and download-file-regexp to their correct types; prepends SSH path to pubkey-path.
   - From: `fileTransfer_jobRunner`
   - To: `fileProcessor` (via `prepare-job`)
   - Protocol: direct (in-process)

3. **Creates local storage directory**: Ensures `/tmp/transfer-files` exists on the local filesystem.
   - From: `fileProcessor`
   - To: local filesystem
   - Protocol: OS call

4. **Lists files on SFTP server**: Opens an SFTP connection using the configured credentials and calls `sftp/ls` with `download-dir` and `download-file-regexp`.
   - From: `fileProcessor` → `sftpClient`
   - To: External SFTP server
   - Protocol: SFTP (TCP 22)

5. **Loads previously processed files**: Queries `job_files` for all rows where `processed_at IS NOT NULL` for this `job_name`.
   - From: `fileTransferRepository`
   - To: `continuumFileTransferDatabase`
   - Protocol: JDBC/MySQL (TCP 3306)

6. **Filters new files**: Compares the SFTP file list against processed records (by filename + size). Files not in the processed set are treated as new.
   - From: `fileProcessor` (in-memory comparison)
   - Protocol: direct (in-process)

7. **Downloads new files**: For each new file, calls `sftp/grab` to download the file content to `/tmp/transfer-files/<filename>`.
   - From: `sftpClient`
   - To: External SFTP server
   - Protocol: SFTP (TCP 22)

8. **Initialises processing record**: For each new file, upserts a `job_files` row (finds an existing unprocessed record or inserts a new one with `processed_at = NULL`).
   - From: `fileTransferRepository`
   - To: `continuumFileTransferDatabase`
   - Protocol: JDBC/MySQL (TCP 3306)

9. **Uploads file to FSS**: Calls `fss-clj/upload` with the local file path, FSS host URL, user UUID, and optional `content-delete-at` timestamp.
   - From: `fssClient`
   - To: `fileSharingService`
   - Protocol: HTTPS

10. **Publishes notification to messagebus**: Sends a JSON message `{:filename "..." :job-name "..." :file-uuid "..."}` to topic `jms.topic.fed.FileTransfer`.
    - From: `messagebusProducer`
    - To: `messagebus`
    - Protocol: JMS/STOMP (TCP 61613)

11. **Marks file as processed**: Updates the `job_files` row: sets `processed_at = NOW()` and `external_id = <fss-uuid>`.
    - From: `fileTransferRepository`
    - To: `continuumFileTransferDatabase`
    - Protocol: JDBC/MySQL (TCP 3306)

12. **Tears down messagebus producer**: In the `finally` block, calls `stop-mbus-producer` to close the STOMP connection.
    - From: `fileProcessor` (in `sync-files` finally)
    - To: `messagebusProducer`
    - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Any step throws `Throwable` | `retry-job` is called; job is re-queued with a delay of `5000 ms × retry-count` | Up to 3 retry attempts |
| 3 retries exhausted | Logs `job/out-of-retries` with `investigate-cause? true` | Job terminates; file remains unprocessed in DB; Splunk alert fires on next `check-jobs` run |
| FSS upload fails | Exception propagates to `execute-job`; triggers retry | File not marked processed; will be retried on next job run after retries exhaust |
| Messagebus publish fails | Exception propagates to `execute-job`; triggers retry | File upload may have succeeded but notification not sent; `external_id` not yet set in DB |
| SFTP connection fails | Exception propagates to `execute-job`; triggers retry | No files downloaded |

## Sequence Diagram

```
CronJob            -> JobRunner       : exec run-job.sh sync-files getaways_booking_files
JobRunner          -> FileProcessor   : execute-job "sync-files" "getaways_booking_files"
FileProcessor      -> SFTPClient      : ls(download-dir, download-file-regexp)
SFTPClient         -> SFTPServer      : SFTP ls
SFTPServer        --> SFTPClient      : file listing
FileProcessor      -> Repository      : get-previously-seen-files-for "getaways_booking_files"
Repository         -> MySQL           : SELECT * FROM job_files WHERE job_name=... AND processed_at IS NOT NULL
MySQL             --> Repository      : processed file rows
FileProcessor      -> SFTPClient      : grab(remote-path, /tmp/transfer-files)
SFTPClient         -> SFTPServer      : SFTP get
SFTPServer        --> SFTPClient      : file bytes
FileProcessor      -> Repository      : initialize-file-for-processing
Repository         -> MySQL           : INSERT/SELECT job_files
MySQL             --> Repository      : row id
FileProcessor      -> FSSClient       : upload(/tmp/transfer-files/filename, config)
FSSClient          -> FSS             : HTTPS PUT file content
FSS               --> FSSClient       : {uuid: "..."}
FileProcessor      -> MbusProducer    : send-json-message {filename, job-name, file-uuid}
MbusProducer       -> Messagebus      : JMS/STOMP publish to jms.topic.fed.FileTransfer
FileProcessor      -> Repository      : mark-file-as-processed (processed_at, external_id)
Repository         -> MySQL           : UPDATE job_files SET processed_at=..., external_id=...
FileProcessor      -> MbusProducer    : stop-mbus-producer (finally)
```

## Related

- Architecture dynamic view: `dynamic-sync-files`
- Related flows: [Check Unprocessed Files](check-unprocessed-files.md), [Job Retry](job-retry.md)
