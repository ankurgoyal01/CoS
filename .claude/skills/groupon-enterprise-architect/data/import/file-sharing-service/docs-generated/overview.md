---
service: "file-sharing-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Finance Engineering"
platform: "Continuum"
team: "finance-engineering"
status: active
tech_stack:
  language: "Clojure"
  language_version: "1.7.0"
  framework: "Compojure / Ring"
  framework_version: "1.6.1 / 1.6.3"
  runtime: "JVM"
  runtime_version: "Java 8+"
  build_tool: "Leiningen"
  package_manager: "Leiningen (Maven Central / Nexus)"
---

# File Sharing Service Overview

## Purpose

File Sharing Service (FSS) provides a REST API that enables internal Groupon services and users to upload, download, and share files stored on Google Drive. The service acts as an abstraction layer over the Google Drive API, managing user OAuth credentials and file metadata in a MySQL database, and supporting both personal-drive OAuth and shared-drive service-account authentication modes. It was originally built for the Finance Engineering team (FED) and is available to any internal consumer.

## Scope

### In scope

- Accepting file uploads via HTTP multipart form and storing them locally before forwarding to Google Drive
- Storing file binary content temporarily in MySQL (`file_contents` table) with optional timed deletion
- Uploading files to Google Drive using service account credentials (with optional domain-wide delegation) or per-user OAuth tokens
- Sharing uploaded Google Drive files with specified email addresses and email types via the Drive Permissions API
- Registering users by exchanging Google OAuth2 authorization codes for access and refresh tokens
- Returning Google Drive file IDs (`external-file-id`) to callers for downstream reference
- Scheduled daily task that clears expired `file_contents` blobs from MySQL
- Metrics emission to InfluxDB/Telegraf and structured JSON logging via log4j/Filebeat

### Out of scope

- Long-term file storage (Google Drive manages the file lifecycle after upload)
- Direct browser-facing UI for end users (no frontend component)
- User authentication beyond Google OAuth2 token management
- File versioning, conflict resolution, or collaborative editing
- Access control enforcement beyond Google Drive share permissions

## Domain Context

- **Business domain**: Finance Engineering — internal tooling for file exchange between finance systems and teams
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon services (e.g., accounting-service, Ruby and Clojure client libraries), direct HTTP callers using `user-uuid` credentials
- **Downstream dependencies**: Google Drive API v3, Google OAuth2 API v2, MySQL (file/user metadata), InfluxDB/Telegraf (metrics)

## Stakeholders

| Role | Description |
|------|-------------|
| Finance Engineering team (FED) | Service owner; manages deployment, credentials, and feature development |
| Internal service consumers | Services that upload or retrieve financial files via the FSS REST API |
| Google Cloud admin | Manages the Google Cloud project `clever-aleph-427` and service account credentials |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Clojure | 1.7.0 | `project.clj` |
| Framework | Compojure | 1.6.1 | `project.clj` |
| HTTP server | Ring / Jetty | 1.6.3 | `project.clj` |
| Build tool | Leiningen | 2+ | `project.clj`, `README.md` |
| Runtime | JVM | Java 8+ | `README.md`, `.java-version` |
| Container base | docker.groupondev.com/clojure | lein-2.7.1 | `.ci/Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| compojure | 1.6.1 | http-framework | HTTP routing |
| ring | 1.6.3 | http-framework | HTTP server abstraction |
| korma | 0.3.0-RC6 | orm | SQL DSL and entity mapping for MySQL |
| lobos | 1.0.0-beta1 | db-client | Database schema migrations |
| mysql/mysql-connector-java | 8.0.33 | db-client | JDBC driver for MySQL 8 |
| google-api-services-drive | v3-rev20241206-2.0.0 | auth | Google Drive API v3 client |
| google-api-services-oauth2 | v2-rev59-1.17.0-rc | auth | Google OAuth2 user info client |
| google-auth-library-oauth2-http | 1.19.0 | auth | Service account credential support |
| cronj | 1.4.4 | scheduling | Cron-style scheduled tasks |
| pantomime | 2.1.0 | serialization | MIME type detection for uploaded files |
| org.influxdb/influxdb-java | 2.2 | metrics | Writes metrics to InfluxDB/Telegraf |
| log4j | 1.2.16 | logging | Rolling file appender, JSON log output |
| com.groupon.clojure/logging-middleware | 0.3.1 | logging | Groupon request logging Ring middleware |
| com.newrelic.agent.java/newrelic-api | 3.5.0 | metrics | New Relic APM instrumentation |
| cheshire | 5.5.0 | serialization | JSON encoding/decoding |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `project.clj` for the full dependency list.
