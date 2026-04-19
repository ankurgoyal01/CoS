---
service: "file-sharing-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 0
---

# Integrations

## Overview

File Sharing Service has four external dependencies: Google Drive API v3 (file storage), Google OAuth2 API v2 (user authentication and token management), InfluxDB/Telegraf (metrics), and a logging platform reached via Filebeat/Log4j. There are no direct internal Groupon service dependencies — all integrations are with Google Cloud APIs or infrastructure-level systems.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Drive API v3 | HTTPS (REST SDK) | Upload files and set share permissions | yes | `googleDriveApi` |
| Google OAuth2 API v2 | HTTPS (REST SDK) | Exchange auth codes, fetch user info, refresh tokens | yes | `googleOAuth` |
| InfluxDB / Telegraf | HTTP (InfluxDB line protocol) | Emit operational metrics (server errors, upload failures) | no | `influxDb` |
| Logging Platform (Filebeat/ELK) | Log4j file + Filebeat | Ship structured JSON logs to Elasticsearch index `us-*:filebeat-file-sharing-service_api` | no | `loggingPlatform` |

### Google Drive API v3 Detail

- **Protocol**: HTTPS via Google APIs Java client (`com.google.apis:google-api-services-drive:v3-rev20241206-2.0.0`)
- **Base URL / SDK**: `https://www.googleapis.com/drive/v3` (managed by SDK)
- **Auth**: Three-tier strategy controlled by `GOOGLE_AUTH_MODE`:
  1. Service account JSON key (`GOOGLE_SERVICE_ACCOUNT_JSON_PATH`) — uploads to shared drive folder (`GOOGLE_SHARED_DRIVE_FOLDER_ID`)
  2. Service account with domain-wide delegation (`GOOGLE_DELEGATED_USER_EMAIL`) — impersonates a domain user
  3. Per-user OAuth2 tokens (`current-token` / `refresh-token` from `users` table) — uploads to personal drive
- **Purpose**: Receives uploaded files; creates file permissions (share with email addresses)
- **Failure mode**: Upload failures are caught and retried up to 5 times (`retry-times 5`); if all auth tiers fail, an exception is thrown and a `500` error is returned to the caller; metrics are emitted on failure
- **Circuit breaker**: No circuit breaker — retry with up to 5 attempts via `retry-times`

### Google OAuth2 API v2 Detail

- **Protocol**: HTTPS via Google APIs Java client (`com.google.apis:google-api-services-oauth2:v2-rev59-1.17.0-rc`)
- **Base URL / SDK**: `https://oauth2.googleapis.com` (managed by SDK)
- **Auth**: Client ID (`GOOGLE_CLIENT_ID`) and secret (`GOOGLE_SECRET`); redirect URI `https://developers.google.com/oauthplayground`
- **Purpose**: Exchanges OAuth2 authorization codes for access/refresh tokens during user registration; retrieves user email/`hd` (hosted domain) to verify `@groupon.com` accounts; refreshes expired tokens
- **Failure mode**: `TokenResponseException` on invalid/used auth codes — returns HTTP 400 to caller; validation failure throws `Throwable`
- **Circuit breaker**: No

### InfluxDB / Telegraf Detail

- **Protocol**: HTTP, InfluxDB line protocol batch points
- **Base URL / SDK**: Configurable via `TELEGRAF_URL` (default: `http://localhost:8086/`); database `telegraf`
- **Auth**: Username/password (default `root`/`root`)
- **Purpose**: Records `custom.file-sharing-service.general.server_error` measurements including duration, count, URI, request method, remote IP, and exception type; tagged with environment/deploy metadata from `DEPLOY_AZ`, `DEPLOY_ENV`, `DEPLOY_SERVICE`, `DEPLOY_REGION`, etc.
- **Failure mode**: Metrics write failures are caught and logged; they do not fail the request
- **Circuit breaker**: No — metrics failures are silently swallowed after logging

### Logging Platform (Filebeat / ELK) Detail

- **Protocol**: Log4j rolling file appender writes to `file-sharing-service.log`; Filebeat sidecar ships logs to Elasticsearch
- **Base URL / SDK**: Kibana index `us-*:filebeat-file-sharing-service_api`; endpoints documented at Groupon logging platform docs
- **Auth**: Infrastructure-managed (Filebeat sidecar)
- **Purpose**: Structured JSON request logs, error context, upload debug traces, token warnings
- **Failure mode**: If log file write fails, no fallback — standard JVM behavior
- **Circuit breaker**: No

## Internal Dependencies

> No evidence found in codebase. File Sharing Service does not call any other internal Groupon services directly.

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known client libraries exist for Clojure (`fss-clj`) and Ruby (`file-sharing-service-ruby-client`) in the finance-engineering GitHub org.

## Dependency Health

- Google Drive and OAuth2 calls use retry logic (up to 5 attempts) via the `retry-times` helper in `src/file_sharing_service/util.clj`
- InfluxDB metric failures are caught at the middleware level (`wrap-metrics-exception`) and do not propagate to the caller
- Token expiry is proactively detected: if a user's `current-token-expires-at` is within 5 minutes of now, the token is refreshed before use
