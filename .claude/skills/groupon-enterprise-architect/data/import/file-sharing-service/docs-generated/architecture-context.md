---
service: "file-sharing-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumFileSharingService", "continuumFileSharingMySql"]
---

# Architecture Context

## System Context

File Sharing Service is a container within the `continuumSystem` (Continuum platform). It exposes a REST API consumed by internal Groupon services — primarily finance engineering tools — to manage file upload, retrieval, and sharing workflows. Externally it integrates with Google Drive API v3 for file storage and Google OAuth2 API for user credential management. It records user and file metadata in a dedicated MySQL database (`continuumFileSharingMySql`) and emits operational metrics to InfluxDB via Telegraf.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| File Sharing Service | `continuumFileSharingService` | Backend API | Clojure / Jetty | 0.1.0-SNAPSHOT | Uploads, downloads, and shares files on Google Drive |
| File Sharing MySQL | `continuumFileSharingMySql` | Database | MySQL | 8.0.33 | Stores users, files, and file contents metadata |

## Components by Container

### File Sharing Service (`continuumFileSharingService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP API | Ring/Compojure routes and request handlers for `/files`, `/users`, `/tasks`, `/grpn` | Clojure / Ring |
| File Service | File persistence to local disk, upload to Google Drive, sharing via Drive Permissions API, blob lifecycle | Clojure |
| User Service | User registration using Google OAuth2 auth-code exchange, token storage and refresh | Clojure |
| Google Drive Client | OAuth credential construction, service account credential loading, three-tier Drive service resolution, file upload and permission creation | Google APIs Java client |
| Database Access | Korma entity definitions and CRUD operations against MySQL via JDBC | Korma / JDBC |
| Metrics Client | Connects to InfluxDB/Telegraf and writes batch points for server errors and upload failures | InfluxDB Java client |
| Task Scheduler | Cron jobs: daily midnight clear of expired `file_contents` blobs, hourly status logging | cronj |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumFileSharingService` | `continuumFileSharingMySql` | Reads and writes user, file, and file content records | JDBC |
| `continuumFileSharingService` | `googleOAuth` | Authorizes users and refreshes OAuth2 tokens | OAuth2 / HTTPS |
| `continuumFileSharingService` | `googleDriveApi` | Uploads files and creates share permissions | HTTPS (Drive API v3) |
| `continuumFileSharingService` | `influxDb` | Writes operational metrics | HTTP (InfluxDB line protocol) |
| `continuumFileSharingService` | `loggingPlatform` | Emits structured JSON logs picked up by Filebeat | Log4j / Filebeat |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumFileSharingService`
- Dynamic view: `dynamic-FileUploadToGoogleDrive`
