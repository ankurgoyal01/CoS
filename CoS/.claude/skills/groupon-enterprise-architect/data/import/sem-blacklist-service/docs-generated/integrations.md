---
service: "sem-blacklist-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 1
---

# Integrations

## Overview

The SEM Blacklist Service has two external dependencies and one internal dependency. The two external integrations are the Asana REST API (for task-driven denylist change requests) and the Google Sheets API (for scheduled PLA blacklist synchronization from spreadsheets). The single internal dependency is the owned PostgreSQL database. There is no service mesh, circuit breaker library, or service discovery client observed in the source code.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Asana REST API | HTTPS / REST | Poll open denylist change request tasks and update task status fields | no | `asanaApi` (stub) |
| Google Sheets API | HTTPS / Google API v4 | Read PLA blacklist spreadsheets for scheduled refresh | no | `googleSheetsApi` (stub) |

### Asana REST API Detail

- **Protocol**: HTTPS / REST
- **Base URL**: `https://app.asana.com/api/1.0`
- **Auth**: Bearer token (`asanaApiKey` config value) sent as `Authorization: Bearer <token>` header
- **Purpose**: The `AsanaClient` polls the configured Asana section (`asanaSectionGid`) for open, incomplete tasks. Tasks with a custom field `Service Status` set to `ADD_REQUEST` or `DELETE_REQUEST` are processed as denylist mutations. After processing, the client updates the task's `Service Status` field to `PROCESSED`, `DELETED`, or `INVALID_DATA` and marks the task as completed.
- **Endpoints used**:
  - `GET /sections/{sectionGid}/tasks?completed_since=now&opt_fields=name,created_at,completed,resource_subtype,custom_fields` — fetch open tasks with pagination
  - `PUT /tasks/{taskGid}` — update task status and completion flag
- **Failure mode**: If the Asana API returns a non-200 response, an `IOException` is thrown. The `DenylistAsanaTaskProcessor` catches per-task exceptions, logs an error event (`AsanaTaskProcessingError`), and continues processing remaining tasks. A fatal exception at the batch level is logged as `AsanaTaskProcessingFatalError`.
- **Circuit breaker**: No circuit breaker configured.

### Google Sheets API Detail

- **Protocol**: HTTPS / Google Sheets API v4
- **Base URL / SDK**: `google-api-services-sheets` v4-rev502-1.18.0-rc with `google-oauth-client-jetty` for OAuth2
- **Auth**: OAuth2 service account credentials stored at the path configured by `credentialLocation`
- **Purpose**: The `GoogleDocsClient` reads a meta-sheet to discover sheet IDs by program/channel/country combinations, then reads PLA deal and PLA deal option blacklist sheets. The `GDocBlacklistStore` converts rows into `BlacklistEntity` objects and calls `RawBlacklistDAO.refreshRawBlacklist()` to perform a full transactional replace of the current active PLA blacklist.
- **Sheets accessed**: Configured via `plaGdoc`, `plaUsGDocDealSheet`, `plaUsGDocDealOptionSheet`, `gdocMeta`, `gdocDealSheet`, `gdocMerchantSheet`, `gdocBrandSheet` config keys
- **Failure mode**: IOException propagates from the Quartz job; the job logs the failure and waits for the next scheduled run.
- **Circuit breaker**: No circuit breaker configured.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| SEM Blacklist Postgres (DaaS) | JDBC | Persistent storage of all denylist entries | `continuumSemBlacklistPostgres` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Based on service discovery configuration, the service is accessible at:
> - Production (on-prem/legacy): `http://sem-blacklisting-vip.snc1`
> - Staging (on-prem/legacy): `http://sem-blacklisting-staging-vip.snc1`
> - Production (GCP): Kubernetes service in namespace `sem-blacklist-service-production`, cluster `gcp-production-us-central1`

## Dependency Health

- **Asana API**: No automated health check. Connectivity is implicitly tested on each Quartz job run. API errors are logged with event name `AsanaApiError`.
- **Google Sheets API**: No automated health check. Connectivity is implicitly tested on each Quartz job run.
- **PostgreSQL**: JTier's DaaS module provides connection pool management. The service includes a `SemBlacklistServiceHealthCheck` registered with the Dropwizard health check framework, accessible via the admin port (8081).
