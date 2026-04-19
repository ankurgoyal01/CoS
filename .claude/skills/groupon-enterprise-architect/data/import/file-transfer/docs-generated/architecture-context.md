---
service: "file-transfer"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["fileTransferService", "continuumFileTransferDatabase"]
---

# Architecture Context

## System Context

File Transfer Service is a background worker within the `continuumSystem` (Continuum Platform). It has no inbound HTTP interface. It connects outbound to partner SFTP servers to retrieve files, uploads those files to the internal File Sharing Service (`fileSharingService`), persists transfer state to its own MySQL database (`continuumFileTransferDatabase`), and publishes notifications to the shared messagebus (`messagebus`). It is operated by Finance Engineering and is classified as SOX in-scope.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| File Transfer Service | `fileTransferService` | Worker / CronJob | Clojure | 1.5.1 | Retrieves files from SFTP, uploads to FSS, publishes notifications to the messagebus |
| file_transfer MySQL | `continuumFileTransferDatabase` | Database | MySQL | 8.x | Stores job file metadata and processing state |

## Components by Container

### File Transfer Service (`fileTransferService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Job Runner | Executes configured jobs with retry semantics (up to 3 retries with 5 s × retry-count back-off) | Clojure |
| File Processor | Coordinates file retrieval, deduplication, upload, and persistence for a single job run | Clojure |
| SFTP Client | Lists (`ls`) and downloads (`grab`) files from remote SFTP servers using SSH key or password auth | sfteepee 0.5.1 |
| File Sharing Service Client | Uploads file content to FSS via HTTPS and receives the FSS UUID in return | com.groupon.fss-clj 0.4.3 |
| Messagebus Producer | Publishes a JSON notification message (filename, job-name, file-uuid) to the JMS topic | messagebus-clj 1.0.5 |
| File Transfer Repository | Reads and writes `job_files` records; enforces deduplication by filename + size | clojure.java.jdbc + HoneySQL 0.4.3 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `fileTransfer_jobRunner` | `fileProcessor` | Runs job execution | direct (in-process) |
| `fileProcessor` | `sftpClient` | Lists and downloads files | direct (in-process) |
| `sftpClient` | External SFTP Server | Retrieves files from partner server | SFTP (TCP port 22) |
| `fileProcessor` | `fileTransferRepository` | Checks and records processing state | direct (in-process) |
| `fileTransferRepository` | `continuumFileTransferDatabase` | Reads/writes `job_files` table | JDBC/MySQL (TCP port 3306) |
| `fileProcessor` | `fssClient` | Uploads file content | direct (in-process) |
| `fssClient` | `fileSharingService` | Uploads files | HTTPS |
| `fileProcessor` | `messagebusProducer` | Publishes file notification | direct (in-process) |
| `messagebusProducer` | `messagebus` | Publishes events | JMS/STOMP (TCP port 61613) |

## Architecture Diagram References

- Component: `components-file-transfer-service`
- Dynamic (sync-files flow): `dynamic-sync-files`
