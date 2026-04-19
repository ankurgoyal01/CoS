---
service: "sem-ui"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest, http]
auth_mechanisms: [session]
---

# API Surface

## Overview

SEM Admin UI exposes two categories of routes: browser-facing page routes that serve the Preact single-page application, and server-side proxy routes that forward requests to downstream SEM backend services. Proxy routes are consumed by the Preact UI components via client-side fetch. All routes are served by the I-Tier server runtime.

## Endpoints

### Page Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | SEM dashboard home / landing page | I-Tier session |
| GET | `/attribution-lens` | Attribution analysis page | I-Tier session |
| GET | `/denylisting` | Denylist management page | I-Tier session |
| GET | `/keyword-manager` | Keyword management page | I-Tier session |

### Proxy Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST/PUT/DELETE | `/proxy/attribution/orders` | Proxies attribution order data requests to GPN Data API | I-Tier session |
| GET/POST/PUT/DELETE | `/proxy/denylist` | Proxies denylist entry management requests to SEM Blacklist Service | I-Tier session |
| GET/POST/PUT/DELETE | `/proxy/keyword/deals/{permalink}/keywords` | Proxies keyword read/write operations for a given deal permalink to SEM Keywords Service | I-Tier session |

## Request/Response Patterns

### Common headers

- `Cookie` — I-Tier session cookie for authentication (managed by `itier-user-auth`)
- `Content-Type: application/json` — for proxy API requests with request bodies

### Error format

> No evidence found in codebase. Error response shape is delegated to I-Tier framework defaults and upstream service responses.

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

No API versioning strategy is applied. The proxy routes are structured by resource path rather than versioned URL segments.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec or GraphQL schema file detected in the repository.
