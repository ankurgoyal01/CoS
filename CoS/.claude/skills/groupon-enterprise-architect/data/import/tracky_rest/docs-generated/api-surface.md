---
service: "tracky-rest"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [none]
---

# API Surface

## Overview

Tracky REST exposes a single HTTP endpoint used by client applications to submit structured analytics and tracking events. The API is intentionally minimal: callers POST a JSON payload and receive a plain-text acknowledgement. No authentication is required. The endpoint is designed for high-throughput, fire-and-forget ingestion.

## Endpoints

### Event Ingestion

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/tracky` | Submit a JSON event object or array of event objects for structured logging | None |
| `OPTIONS` | `/tracky` | CORS preflight — returns 204 with CORS headers | None |
| `GET` | `/nginx_status` | Nginx stub status (internal monitoring only) | None (access log disabled) |

### POST `/tracky` Detail

- **Request body**: A single JSON object `{}` or a JSON array of objects `[{}, {}]`. All fields are caller-defined; the service adds enrichment fields automatically.
- **Response (success)**: HTTP 200, body `OK\n` (plain text).
- **Response (bad JSON)**: HTTP 400.
- **Response (non-POST method)**: HTTP 406 (DECLINED by Nginx).

### Enrichment fields added to every event

| Field | Source | Description |
|-------|--------|-------------|
| `__http_timestamp` | `Time::HiRes::time()` | Unix epoch (float) at time of server receipt |
| `__http_vhost_name` | `Host` request header | Virtual host name from the incoming HTTP request |
| `__http_xff` | `X-Forwarded-For` request header | Forwarded-for chain from upstream proxies |
| `__http_client_ip` | `True-Client-IP` header, fallback `remote_addr` | Resolved client IP address |
| `__http_x_request_id` | `X-Request-Id` request header | Request tracing ID (omitted if not present) |
| `__http_xrepsheet` | `X-Repsheet` request header | Repsheet fraud/abuse header (omitted if not present) |

## Request/Response Patterns

### Common headers

- **Request**: `Content-Type: application/json` (recommended; not enforced by Nginx).
- **Response (CORS)**: `Access-Control-Allow-Origin: *`, `Access-Control-Allow-Methods: POST`, `Access-Control-Allow-Headers: Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,X-Forwarded-For`, `Access-Control-Max-Age: 3600`.

### Error format

HTTP 400 is returned with no structured body when the request body is not valid JSON. HTTP 406 (DECLINED) is returned for non-POST methods. No JSON error envelope is used.

### Pagination

> Not applicable — this is a write-only ingestion endpoint.

## Rate Limits

> No rate limiting configured. Nginx worker connections are capped at 8192 per worker (`worker_connections 8192`); `worker_processes auto` scales to available CPU cores.

## Versioning

No URL versioning strategy. The service discovery descriptor identifies the API as `v1.tracky_REST_api` (see `doc/service_discovery/resources.json`), but no version is embedded in the path.

## OpenAPI / Schema References

A service discovery descriptor is available at `doc/service_discovery/resources.json`. A Ruby-format API description is at `doc/tracky_api.rb`. No OpenAPI/Swagger or proto file is present in the repository.
