---
service: "itier-ttd-booking"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

`itier-ttd-booking` exposes a synchronous REST HTTP interface. Consumers are browser clients loading GLive checkout pages. The service returns server-rendered HTML for page routes and JSON for polling endpoints. All routes are served over HTTPS through the ITier application layer.

## Endpoints

### Booking Widget

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/live/checkout/booking/{dealId}` | Renders the GLive booking widget page for a given deal | Session |

### Reservation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/live/deals/{dealId}/reservation` | Renders the reservation spinner/loading page | Session |
| GET | `/live/deals/{dealId}/reservation/status.json` | Polls reservation status and returns current state as JSON | Session |

### Error

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/live/checkout/error` | Renders the booking error page | Session |

### TTD Pass Content

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ttd-pass-deals` | Serves TTD pass deal content and card responses | Session |

## Request/Response Patterns

### Common headers

- Standard ITier platform headers forwarded by `apiProxy` (e.g., `X-Forwarded-For`, session cookies)
- Responses for page routes: `Content-Type: text/html`
- Responses for status route: `Content-Type: application/json`

### Error format

- Page routes return an HTML error page via `/live/checkout/error` on unrecoverable failures.
- The status polling endpoint (`/live/deals/{dealId}/reservation/status.json`) returns a JSON body with a terminal error state when reservation creation or polling fails.

### Pagination

> Not applicable — all endpoints return single-resource responses.

## Rate Limits

> No rate limiting configured at the service level. Rate limiting, if any, is enforced upstream by `apiProxy` or the Akamai CDN layer.

## Versioning

No explicit API versioning strategy. Route paths use the `/live/` and `/ttd-pass-deals` prefixes as implicit version/domain namespaces. Breaking changes require coordinated frontend and service deployments.

## OpenAPI / Schema References

> No evidence of an OpenAPI spec, proto files, or GraphQL schema in the repository.
