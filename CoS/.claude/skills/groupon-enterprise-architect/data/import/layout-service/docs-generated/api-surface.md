---
service: "layout-service"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

Layout Service exposes HTTP REST endpoints under the `/layout/*` path prefix. These endpoints are consumed by Groupon i-tier frontend applications to request rendered page chrome (header, footer, navigation) composed with locale, market, and user session context. All responses are synchronous request/response; no streaming or long-polling patterns are used.

## Endpoints

### Layout Composition

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/layout/*` | Retrieve composed layout fragment (header, footer, or full chrome) for a given locale/market/user context | Session / i-tier internal |

> The `/layout/*` wildcard covers sub-paths for distinct layout zones (e.g., header, footer, navigation). Exact sub-paths are defined by the i-tier routing conventions and managed within `layoutSvc_httpApi`.

## Request/Response Patterns

### Common headers

- `Accept-Language` — locale hint used by `layoutSvc_requestComposer` to select the correct locale context
- `X-Forwarded-For` / `X-Real-IP` — passed through from the i-tier reverse proxy for region/market resolution
- Standard i-tier internal service headers for request tracing

### Error format

> No evidence found of a formally documented error response schema in the architecture inventory. Standard i-tier HTTP error responses (4xx/5xx) with plain-text or JSON body are expected. Refer to itier-server conventions.

### Pagination

> Not applicable — layout endpoints return a single composed fragment per request.

## Rate Limits

> No rate limiting configured at the Layout Service level. Rate limiting is managed at the i-tier gateway/load balancer layer upstream.

## Versioning

Layout Service does not implement explicit API versioning. Endpoint paths are stable; breaking changes are coordinated with consuming i-tier teams via the Frontend Platform team.

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec or schema file in the architecture inventory. Schema is implicitly defined by the Mustache template contracts and i-tier response conventions.
