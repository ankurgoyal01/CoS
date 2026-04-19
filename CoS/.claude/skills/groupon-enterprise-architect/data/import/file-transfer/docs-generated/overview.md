---
service: "file-transfer"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Finance Engineering"
platform: "Continuum"
team: "Finance Engineering"
status: active
tech_stack:
  language: "Clojure"
  language_version: "1.5.1"
  framework: "N/A"
  framework_version: "N/A"
  runtime: "JVM"
  runtime_version: "Java 8"
  build_tool: "Leiningen"
  build_tool_version: "2.7.1"
  package_manager: "Leiningen"
---

# File Transfer Service Overview

## Purpose

File Transfer Service (FTS) is a scheduled worker that periodically retrieves files from remote SFTP servers, uploads them to Groupon's internal File Sharing Service (FSS), and notifies downstream consumers via the messagebus that the files are available. It exists to automate the ingestion of partner-supplied files (such as Getaways booking files) into Groupon's internal data infrastructure without manual intervention.

## Scope

### In scope

- Polling configured SFTP servers for new files on a scheduled cadence
- Deduplication of files using a MySQL-backed processing log (`job_files` table)
- Uploading retrieved files to FSS and recording the resulting FSS UUID
- Publishing file-availability notifications to the JMS topic `jms.topic.fed.FileTransfer`
- Retry logic (up to 3 attempts, with exponential back-off) for failed job executions
- Alerting when files remain in an unprocessed state for more than one day

### Out of scope

- Serving an HTTP API — this service has no inbound HTTP interface
- File content parsing or transformation — files are transferred as opaque blobs
- Long-term file storage — retention and deletion are delegated to FSS
- Upstream consumer logic — downstream services subscribe independently to the messagebus topic

## Domain Context

- **Business domain**: Finance Engineering
- **Platform**: Continuum
- **Upstream consumers**: Any service subscribed to `jms.topic.fed.FileTransfer` (tracked in the central architecture model)
- **Downstream dependencies**: Remote SFTP servers (partner-managed), File Sharing Service (FSS), messagebus (JMS/STOMP), MySQL `file_transfer` database

## Stakeholders

| Role | Description |
|------|-------------|
| Finance Engineering | Owns and operates the service; contact: fed@groupon.com |
| SOX Compliance | Production deployments are gated through `sox-inscope` GitHub organisation |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Clojure | 1.5.1 | `project.clj` |
| Runtime | JVM | Java 8 | `README.md`, `Dockerfile` |
| Build tool | Leiningen | 2.7.1 | `.ci/Dockerfile` |
| Package manager | Leiningen / Artifactory | — | `project.clj` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `org.clojure/clojure` | 1.5.1 | language | Core Clojure runtime |
| `org.clojars.wilkes/sfteepee` | 0.5.1 | sftp-client | SFTP connection, `ls`, and `grab` operations |
| `com.groupon.clojure/fss-clj` | 0.4.3 | http-client | Uploads files to the internal File Sharing Service |
| `com.groupon.clojure/messagebus-clj` | 1.0.5 | message-client | JMS/STOMP producer for the messagebus |
| `com.groupon.clojure/log-data` | 0.3.0 | logging | Structured JSON logging |
| `mysql/mysql-connector-java` | 8.0.33 | db-client | JDBC driver for MySQL |
| `honeysql` | 0.4.3 | orm | SQL query generation via Clojure data structures |
| `migratus` | 0.7.0 | db-migration | SQL schema migration runner |
| `clj-time` | 0.6.0 | utility | Date/time arithmetic (file retention calculations) |
| `camel-snake-kebab` | 0.1.5 | serialization | Column-name case conversion for JDBC result sets |
| `log4j` | 1.2.16 | logging | Log4j appender configuration |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `project.clj` for a full list.
