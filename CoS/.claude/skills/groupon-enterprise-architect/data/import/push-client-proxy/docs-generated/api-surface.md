---
service: "push-client-proxy"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

push-client-proxy exposes a REST HTTP API on port 8080. There are three groups of endpoints: email operations (send and verify), audience operations (patch and get counts), and health checks. Bloomreach is the primary caller of the email endpoints; the internal Audience Management Service is the primary caller of the audience endpoints. All endpoints return JSON except `/email/verify` which returns plain text. Rate limiting is applied to email send and audience patch endpoints using Redis-backed Bucket4j token buckets.

## Endpoints

### Email Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/email/verify` | Verifies email-send credentials; returns `OK` or `401 Invalid credentials` | `Chan-Example-Token` header (optional in current implementation) |
| `POST` | `/email/send-email` | Accepts an email message, validates rate limit / user / exclusions, and injects via SMTP | `Chan-Example-Token` header (optional in current implementation) |

### Audience Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `PATCH` | `/audiences/{audienceId}` | Applies add/remove patch operations on audience membership (max 500 UUIDs per request); updates Redis and PostgreSQL | None documented |
| `GET` | `/audiences/{audienceId}` | Returns current audience membership counts from Redis/PostgreSQL | None documented |

### Health Checks

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/health` | Returns service status, Kafka config state, and Redis config state | None |
| `GET` | `/grpn/healthcheck` | Groupon standard health check (same payload as `/api/health`) | None |
| `GET` | `/` | Root ping — confirms service is running | None |

## Request/Response Patterns

### Common headers

- `Chan-Example-Token` — authentication token for email endpoints (currently permissive)
- `accept` — `application/json` (default) for email endpoints; `text/plain` for verify
- `content-type` — `application/json` required for `POST /email/send-email`
- `X-Rate-Limit-Remaining` — returned in successful email and audience responses indicating remaining token-bucket tokens
- `X-Rate-Limit-Retry-After-Seconds` — returned in `429` responses

### Error format

- `400 Bad Request` — returned for validation failures (missing audience ID, batch size exceeds 500, malformed email send request)
- `429 Too Many Requests` — returned with `X-Rate-Limit-Retry-After-Seconds` header when rate limit is exceeded
- `500 Internal Server Error` — returned on unexpected processing failures

For the email send endpoint, error responses include an `EmailResponse` JSON body containing the original `requestId`.

### Pagination

> Not applicable. Audience get returns a single `AudienceCountResponse` object with no pagination.

## Rate Limits

Rate limiting is enforced per-endpoint using Bucket4j token buckets backed by the primary Redis cluster. Configuration values are externalized but defaults are not documented in source.

| Tier | Limit | Window |
|------|-------|--------|
| Email send | Configured via Redis bucket | Per bucket refill period |
| Audience patch | Configured via Redis bucket | Per bucket refill period |

Requests that exceed the limit receive `HTTP 429` with `X-Rate-Limit-Retry-After-Seconds` indicating when to retry.

## Versioning

No URL path versioning is used. There is no `/v1/`, `/v2/` scheme. API contracts are managed through deployment coordination with callers.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or Swagger annotations are present in the repository.
