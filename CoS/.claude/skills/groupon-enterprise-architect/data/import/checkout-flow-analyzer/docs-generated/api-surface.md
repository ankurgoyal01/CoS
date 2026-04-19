---
service: "checkout-flow-analyzer"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [oauth2, jwt, session]
---

# API Surface

## Overview

All API routes are Next.js Route Handlers served under the `/api` path prefix. They are called exclusively by the same-origin React UI — there is no public or cross-origin consumer. Every route except `/api/auth` requires an authenticated NextAuth session (JWT validated by middleware). Routes return JSON using a consistent envelope (`success`, `message`, `data`, optional `metadata`).

## Endpoints

### Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/auth/[...nextauth]` | NextAuth catch-all: handles sign-in, sign-out, session retrieval, OIDC callback | Public |
| POST | `/api/auth/[...nextauth]` | NextAuth: processes sign-in form POST and OIDC token exchange | Public |

### Time Window Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/csv-time-windows` | Lists all available time windows detected from CSV/ZIP files in `src/assets/data-files/`, with file completeness flags | Required |
| GET | `/api/csv-files` | Lists all individual CSV/ZIP files with type and time-window metadata | Required |
| POST | `/api/select-csv` | Selects a time window for the current session; stores `timeWindowId` in server-side store; redirects UI to `/sessions` | Required |
| GET | `/api/session-info` | Returns the currently selected `timeWindowId` from the server-side store | Required |
| GET | `/api/debug-store` | Returns selected time-window ID and all available time windows (debug endpoint) | Required |

### Session / CSV Data

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/csv-data` | Returns paginated session rows from the selected time window. Prefers `bcookie_summary` file; falls back to raw PWA logs. Supports filtering by `bCookie`, `fulltext`, `hasApiErrors`, `hasPurchases`; and pagination via `page`, `limit`, `allData` | Required |

### Per-Log-Type APIs

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/proxy-logs` | Returns proxy-layer log rows for a given `timeWindowId`, optionally filtered by `bCookie` | Required |
| GET | `/api/lazlo-logs` | Returns Lazlo backend log rows for a given `timeWindowId`, optionally filtered by `bCookie` | Required |
| POST | `/api/lazlo-logs` | Returns Lazlo log rows filtered by a list of `requestIds` (supplied in request body) and optional `bCookie` | Required |
| GET | `/api/orders-logs` | Returns orders-service log rows for a given `timeWindowId`, optionally filtered by `bCookie` | Required |

### Metrics / Analytics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/conversion-rate` | Calculates View-to-Attempt, Attempt-to-Success, and View-to-Success conversion rates from PWA logs for a given `timeWindowId` | Required |
| GET | `/api/platform-distribution` | Calculates device platform distribution (by unique bCookie) from PWA logs for a given `timeWindowId` | Required |

## Request/Response Patterns

### Common headers

All requests to protected routes must carry a valid NextAuth session cookie (set by the browser after sign-in). Security headers are applied by middleware to all responses: `Content-Security-Policy`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `X-XSS-Protection: 1; mode=block`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy`.

### Error format

All error responses use a consistent JSON envelope:

```json
{
  "success": false,
  "message": "Human-readable error description",
  "data": []
}
```

HTTP status codes used: `400` (missing required parameter), `404` (resource not found), `500` (internal server error).

### Pagination

The `/api/csv-data` endpoint supports cursor-based pagination via query parameters:

| Parameter | Type | Default | Purpose |
|-----------|------|---------|---------|
| `page` | integer | 1 | Page number (1-based) |
| `limit` | integer | 20 | Rows per page |
| `allData` | boolean | false | When true, returns all rows without pagination |

Metadata returned in response:

```json
{
  "metadata": {
    "totalCount": 1234,
    "pagination": {
      "page": 1,
      "limit": 20,
      "totalPages": 62,
      "hasNextPage": true,
      "hasPrevPage": false
    }
  }
}
```

## Rate Limits

> No rate limiting configured. This is an internal tool accessed by a small number of engineers.

## Versioning

> No API versioning strategy is applied. All routes are unversioned. Breaking changes require coordinated UI and API updates within the same deployment.

## OpenAPI / Schema References

> No OpenAPI specification file exists in this repository. Types are defined in TypeScript interfaces in `src/lib/types/` and `src/app/api/*/route.ts` files.
