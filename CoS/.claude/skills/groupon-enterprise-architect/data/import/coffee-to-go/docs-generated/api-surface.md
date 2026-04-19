---
service: "coffee-to-go"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: ["oauth2", "session", "api-key"]
---

# API Surface

## Overview

The Coffee To Go API is a RESTful service built on Express 5 that provides endpoints for querying deals, managing usage tracking, performing health checks, and accessing authentication. Consumers authenticate via Google OAuth (session-based) or API keys (for service-to-service access). All deal and tracking endpoints require authentication; health endpoints are public. The API serves a Swagger UI for interactive documentation at `/api/docs`.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/health` | Basic health check with database connectivity status | Public |
| GET | `/api/livez` | Liveness probe for orchestration | Public |

### Authentication (Better Auth)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| ALL | `/api/auth/*` | Better Auth endpoints (Google OAuth sign-in, session management) | Public |

### Deals

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/deals` | Get filtered deals using optimized materialized view with spatial indexing | Session or API Key (`access` permission) |
| GET | `/api/deals/taxonomy-groups` | Get taxonomy groups for a given country | Session or API Key (`access` permission) |
| GET | `/api/deals/primary-deal-services` | Get primary deal services for a given country | Session or API Key (`access` permission) |

### Usage Tracking

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/usage/events` | Submit a batch of usage tracking events (max 50 per request) | Session |
| GET | `/api/usage/events/graph` | Get usage analytics as graph data points aggregated by day or week | Session |

### Documentation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/docs` | Swagger UI interactive API documentation | Public |
| GET | `/api/swagger.json` | OpenAPI 3.0 specification in JSON format | Public |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for all JSON request/response bodies
- `Cookie: __Secure-coffee.session_token=...` for session-based authentication
- `x-api-key: coffee...` for API key authentication
- `sentry-trace` and `baggage` headers are allowed for distributed tracing

### Error format

All errors follow a standard JSON shape:

```json
{
  "error": "Human-readable error message",
  "code": "MACHINE_READABLE_CODE"
}
```

In development mode, responses also include `cause` and `stack` fields. Standard error codes include: `SESSION_NOT_FOUND`, `ACCESS_DENIED`, `DOMAIN_NOT_ALLOWED`, `RATE_LIMIT_EXCEEDED`, `TRACKING_RATE_LIMIT_EXCEEDED`, `DEALS_FETCH_ERROR`, `INVALID_OWNER_TYPE`, `NOT_FOUND`, `INTERNAL_ERROR`.

### Pagination

The `/api/deals` endpoint supports offset-based pagination:

- `limit` (default: 50, max: 1000) -- number of results per page
- `offset` (default: 0) -- pagination offset
- Response includes `meta.has_more` boolean indicating if more results exist

### Request Validation

All deal query parameters are validated using Zod schemas. Parameters include: `lat`, `lon`, `radius`, `search`, `categories`, `verticals`, `stages`, `activity`, `priorities`, `pds`, `tgs`, `competitors`, `owner_types`, `owner`, `minimum_rating`, `sort_by`, `limit`, `offset`, `boost`. Many parameters accept comma-separated strings or arrays.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| General (deals, tracking reads) | 250 requests per user/IP | 15 minutes |
| Tracking (event submission) | 50 requests per user/IP | 1 minute |

Rate limit key is derived from authenticated user ID, falling back to IP address.

## Versioning

No explicit API versioning is configured. The API is served at the `/api` path prefix.

## OpenAPI / Schema References

- Swagger UI: `/api/docs`
- OpenAPI 3.0 JSON spec: `/api/swagger.json`
- Source: `apps/coffee-api/src/swagger.ts` and JSDoc annotations in route files
