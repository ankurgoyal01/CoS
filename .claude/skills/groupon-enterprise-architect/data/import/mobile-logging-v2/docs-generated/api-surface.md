---
service: "mobile-logging-v2"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [none]
---

# API Surface

## Overview

The Mobile Logging Service exposes an HTTP REST API under the `/v2/mobile/` path prefix. All endpoints accept binary MessagePack payloads from mobile clients. The primary production endpoint is `POST /v2/mobile/logs`; additional endpoints exist for debugging, conversion, and operational control. The API is versioned via the URL path (`/v2/`). No authentication is applied at the service layer — access control is handled upstream by `api-proxy`. The OpenAPI specification is available at `doc/swagger/swagger.yaml`.

## Endpoints

### Log Ingestion

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v2/mobile/logs` | Primary ingestion endpoint — accepts a MessagePack log file, decodes events, and publishes to Kafka `mobile_tracking` | None (api-proxy upstream) |
| `POST` | `/v2/mobile/logsval` | Log ingestion with validation response — same as `/v2/mobile/logs` but returns a plain-text validation result | None |

### Debug / Conversion

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v2/mobile/convert` | Decodes a MessagePack payload and returns CSV text — used for local development and debugging | None |
| `POST` | `/v2/mobile/convert_json` | Decodes a MessagePack payload and returns JSON text — used for local development and debugging | None |

### Operational

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v2/mobile/health` | Returns service health status as JSON | None |
| `GET` | `/v2/mobile/log_level` | Adjusts runtime log level for one or more classes; changes revert after `durationMillis` | None |

## Request/Response Patterns

### Common headers

| Header | Direction | Required | Notes |
|--------|-----------|----------|-------|
| `Content-Type` | Request | No | Must be `binary/messagepack` for log upload endpoints |
| `true-client-ip` | Request | No | Client IP forwarded by api-proxy |

### Query parameters (log ingestion endpoints)

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `client_id` | string | No | App client identifier |
| `client_version_id` | string | No | App client version string |
| `fileName` | string | No | Name of the uploaded log file |

### Query parameters (`/v2/mobile/log_level`)

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `classNames` | string[] | Yes | Fully-qualified class name(s) or `ROOT` |
| `level` | string | Yes | `INFO`, `ERROR`, `WARN`, or `DEBUG` |
| `durationMillis` | integer | No | Duration before log level reverts to default |

### Request body

Log upload requests carry a binary attachment (MessagePack format). The payload contains:
- A prefix timestamp row (discarded)
- A client header row (device info: platform, version, locale, bcookie, device ID, session ID, etc.)
- One or more event rows per GRP event type (GRP5, GRP7, GRP8, GRP9, GRP14, GRP36, GRP40, and others)

### Error format

> No evidence found of a standardised error response body. The JTier/Dropwizard framework returns HTTP status codes with plain-text or JSON error messages depending on the exception type.

### Pagination

> Not applicable. The service processes a complete log file per request; there is no paginated API.

## Rate Limits

> No rate limiting configured at the service layer. Rate limiting is handled upstream by `api-proxy`.

## Versioning

API versioning uses the URL path prefix `/v2/`. This is the second major version of the mobile logging pipeline (the first was a Ruby-based service).

## OpenAPI / Schema References

- OpenAPI 2.0 specification: `doc/swagger/swagger.yaml`
- Example decoded event payload (JSON): `doc/example message.json`
