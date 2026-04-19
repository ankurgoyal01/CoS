---
service: "file-transfer"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 2
---

# Integrations

## Overview

File Transfer Service has four outbound integrations: two internal Groupon services (File Sharing Service and the messagebus) and two external dependency categories (partner SFTP servers and its own MySQL database). All connections are strictly outbound — no inbound integration exists. Network egress is restricted by a Kubernetes `NetworkPolicy` to ports 22 (SFTP), 61613 (STOMP/mbus), and 3306 (MySQL).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Partner SFTP Server (e.g., Getaways booking server) | SFTP (TCP 22) | Source of files to be ingested | yes | `sftpServer` (stub) |

### Partner SFTP Server Detail

- **Protocol**: SFTP over SSH (TCP port 22)
- **Base URL / SDK**: Connection parameters configured per job via env vars (`GETAWAYS_BOOKING_HOST`, `GETAWAYS_BOOKING_PORT`, `GETAWAYS_BOOKING_DOWNLOAD_DIR`, etc.); SFTP library: `sfteepee 0.5.1`
- **Auth**: SSH public-key authentication (path configured via `GETAWAYS_BOOKING_PUBKEY_PATH` and `SSH_PATH`); password auth also supported via `:password` field
- **Purpose**: Lists files matching `GETAWAYS_BOOKING_DOWNLOAD_FILE_REGEXP` in `GETAWAYS_BOOKING_DOWNLOAD_DIR`, then downloads any that have not been previously processed
- **Failure mode**: Job execution throws, triggers retry logic (up to 3 attempts with exponential back-off); after 3 failures, logs `job/out-of-retries` error
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| File Sharing Service (FSS) | HTTPS | Stores uploaded files and returns a UUID for each | `fileSharingService` (stub) |
| Messagebus | JMS/STOMP (TCP 61613) | Publishes file-availability notifications | `messagebus` (stub) |
| file_transfer MySQL | JDBC/MySQL (TCP 3306) | Persists and queries job file processing state | `continuumFileTransferDatabase` |

### File Sharing Service (FSS) Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `FILE_SHARING_HOST` env var; library: `com.groupon.clojure/fss-clj 0.4.3`
- **Auth**: `FILE_SHARING_USER_UUID` env var
- **Purpose**: Receives file content and returns a UUID (`file-uuid`) and optional content-delete-at timestamp; handles long-term retention
- **Failure mode**: Upload fails; job throws and triggers retry logic
- **Circuit breaker**: No evidence found in codebase

### Messagebus Detail

- **Protocol**: JMS/STOMP
- **Base URL / SDK**: `MESSAGEBUS_HOST:MESSAGEBUS_PORT`; library: `com.groupon.clojure/messagebus-clj 1.0.5`
- **Auth**: Username/password via `MESSAGEBUS_USER` / `MESSAGEBUS_PASSWORD`
- **Purpose**: Publishes JSON notification to topic `jms.topic.fed.FileTransfer` after each file is successfully uploaded
- **Failure mode**: Send fails; job throws and triggers retry logic; producer connection is torn down in `finally` block regardless of success or failure
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model. Any service subscribed to `jms.topic.fed.FileTransfer` is a consumer.

## Dependency Health

Retry semantics are implemented at the job level in `execute-job` / `retry-job`: on any `Throwable`, the job is re-attempted up to 3 times with a delay of 5 s × retry-count. After exhausting retries, an error is logged with `investigate-cause? true`. No circuit breaker or health-check probe against external dependencies is implemented.
