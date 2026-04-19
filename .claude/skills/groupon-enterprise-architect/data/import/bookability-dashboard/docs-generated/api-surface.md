---
service: "bookability-dashboard"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [cookie, oauth2]
---

# API Surface

## Overview

The Bookability Dashboard is a browser-only SPA and does not expose any server-side API to external consumers. All API calls originate from the browser client and are directed to `continuumPartnerService` via `apiProxy`. The base URL for all Partner Service calls is resolved at runtime from `window._env_.API_URL` (defaulting to `/bookability/dashboard/api`), with requests routed through the proxy at `/bookability/dashboard/api/partner-service/`.

This document describes the API surface the dashboard **consumes** from `continuumPartnerService`.

## Endpoints

### Partner Configuration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/partner_configurations?monitoring=true&clientId=tpis` | Fetch all active partner configurations dynamically (names, acquisition method IDs) | Cookie (session) |

### Merchant Data

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v2/partners/{partner}/merchants?clientId=tpis` | Fetch merchant list by platform name (e.g., `square`, `mindbody`, `booker`) | Cookie (session) |
| `GET` | `/v1/partners/{partnerId}/connectivity_status?clientId=tpis` | Fetch deal connectivity status records for a partner by acquisition method ID | Cookie (session) |
| `GET` | `/v1/partners/merchant_products?acquisitionMethodIds=...&clientId=tpis` | Fetch merchant product mappings (deal titles, inventory product IDs, status) | Cookie (session) |

### Health Check

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/groupon/simulator/logs?acquisitionMethodIds=...&logTypes=deal.health.check&clientId=tpis&page=N&size=5000` | Fetch paginated deal health check logs with optional time range filters | Cookie (session) |
| `PUT` | `/v1/deals/health-check/trigger?inventoryProductIds=...&acquisitionMethodId=...&clientId=tpis` | Trigger on-demand health checks for one or more inventory product IDs | Cookie (session) |
| `PUT` | `/v1/deals/health-check/fix?inventoryProductId=...&acquisitionMethodId=...&checkType=...&clientId=tpis` | Trigger a fix for a specific health check type (`isBookable`, `calendarServiceCorrect`, `clientLinks`, `checkoutFields`) | Cookie (session) |

### Reports

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/groupon/simulator/dashboard-reports?acquisitionMethodIds=...&clientId=tpis` | Fetch aggregated time-to-bookability metrics (total, success, failed) per platform | Cookie (session) |

### Investigation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/deals/investigation?clientId=tpis` | Create or update a deal investigation record (acknowledge, categorize, or resolve) | Cookie (session) |
| `GET` | `/v1/deals/investigation/{dealId}?clientId=tpis` | Fetch investigation history for a specific deal | Cookie (session) |

### User Identity

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v2/merchant_oauth/internal/me?clientId=tpis` | Fetch authenticated internal user identity and role | Cookie (session) |
| `GET` | `/v1/users/internal?clientId=tpis` | Fetch list of internal users for investigation assignment | Cookie (session) |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json`
- `credentials: include` — all requests use `credentials: "include"` to send session cookies automatically
- `Authorization: OAuth {token}` — appended when an `ApiContext.token` is available

### Error format

Errors are returned as JSON objects with an optional shape:

```json
{
  "error": {
    "httpCode": 401,
    "message": "Unauthorized"
  }
}
```

- HTTP 401: triggers login flow (`user` set to `null` in AppContext)
- HTTP 503: sets `isDown: true` in AppContext, rendering a service-unavailable state
- HTTP 204: treated as a successful empty response

### Cookie retry

The `fetchWithCookieRetry` utility handles HTTP 431 (Request Header Fields Too Large) errors by clearing oversized cookies and retrying the request automatically.

### Pagination

Health check log requests use page-based pagination:

- `page` (integer, 0-based)
- `size` (integer, default `5000`)
- Pages are fetched in parallel batches of up to 15 pages (`PARALLEL_BATCH_SIZE = 15`)
- Fetching stops when a page returns fewer records than the page size

## Rate Limits

> No rate limiting is configured at the dashboard layer. Rate limiting, if any, is enforced by `continuumPartnerService`.

## Versioning

Partner Service endpoints use URL path versioning (`/v1/`, `/v2/`). The dashboard targets specific versions per endpoint as documented above.

## OpenAPI / Schema References

> No OpenAPI spec or schema file exists within this repository. API contracts are defined by `continuumPartnerService`.
