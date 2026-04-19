---
service: "my_appointments_client"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, html]
auth_mechanisms: [x-auth-token, csrf, session-cookie]
---

# API Surface

## Overview

My Appointments Client exposes two categories of HTTP surface: page-rendering routes that return HTML for mobile webview contexts, and JSON REST API routes under `/mobile-reservation/api/` consumed by the Preact booking widget frontend. All requests are served on port `8000`. Authentication for protected API endpoints is carried via the `x-auth-token` header. CSRF protection is enforced on mutation endpoints via the `csurf` middleware using an HTTP-only cookie.

## Endpoints

### Page Routes (HTML)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mobile-reservation` | Mobile loader page — renders the booking widget shell without layout | None |
| GET | `/mobile-reservation/touch` | Mobile reservations touch page | None |
| GET | `/mobile-reservation/main` | Mobile reservations main webview page (full booking flow) | None |
| GET | `/mobile-reservation/events` | Returns iCalendar (`.ics`) file for a reservation event | None |
| GET | `/users/:userId/reservations` | Redirects (301) authenticated users to My Groupons page | Session |

### JS API Routes (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mobile-reservation/next/jsapi-script-url` | Returns widget script URL, CSS URL, CSRF token, feature-flag payload, and user login state | None |

### Reservation REST API (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mobile-reservation/api/reservations` | List reservations for an order (query: `orderId` required, `voucherId`, `reservationRequestId` optional) | `x-auth-token` |
| POST | `/mobile-reservation/api/reservations` | Create a new reservation (body: `possibleSegments`, `orderId`, `voucherId`, `optionId`, `userId`, `agendaId`) | CSRF |
| GET | `/mobile-reservation/api/reservations/:reservationId` | Retrieve a specific reservation by ID | `x-auth-token` |
| PUT | `/mobile-reservation/api/reservations/:reservationId` | Update (reschedule) an existing reservation (body: `possibleSegments`, `agendaId`) | `x-auth-token` + CSRF |
| POST | `/mobile-reservation/api/reservations/:reservationId/cancel` | Cancel a specific reservation | `x-auth-token` + CSRF |

### Availability and Settings REST API (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mobile-reservation/api/options/:optionId/availability` | Get available time segments for an option (query: `initialTime`, `finalTime` required; `agendaId` optional) | None |
| GET | `/mobile-reservation/api/options/:optionId/settings` | Get booking settings for an option (query: `agendaId` optional) | None |

### Deal, Groupon, Order, and User REST API (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mobile-reservation/api/deals/:dealId` | Retrieve deal details by ID (query: `available_segments_start_at`, `available_segments_end_at` optional) | None |
| GET | `/mobile-reservation/api/groupons/:grouponId` | Retrieve groupon (voucher) details by ID | `x-auth-token` |
| GET | `/mobile-reservation/api/orders/:orderId/status` | Retrieve order status by ID | `x-auth-token` |
| GET | `/mobile-reservation/users/:userId/orders/:orderId/status` | Retrieve order status (legacy mobile path) | Session |
| GET | `/mobile-reservation/api/user` | Retrieve authenticated user details from access token | `x-auth-token` |

### Utility REST API (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/mobile-reservation/api/param` | Encrypt URL parameters for secure deep-linking | CSRF |
| POST | `/mobile-reservation/api/logger` | Log frontend errors from the booking widget | None |

## Request/Response Patterns

### Common headers

- `x-auth-token` — Groupon user access token, required for authenticated endpoints
- `Content-Type: application/json` — required for POST/PUT JSON bodies
- `X-CSRF-Token` — CSRF token required for mutation requests (sourced from `/mobile-reservation/next/jsapi-script-url`)

### Error format

Standard HTTP status codes are used. Responses on error return an HTTP status code (400, 401, 403, 404) with a JSON body. Specific response schemas are not fully defined in the OpenAPI spec (marked FIXME in source).

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

No explicit API versioning is applied. Endpoints follow a flat URL structure under `/mobile-reservation/`. The JS API controller supports implicit versioning of widget assets via fingerprinted Webpack bundle filenames (e.g., `jsapi.js` with a content hash).

## OpenAPI / Schema References

OpenAPI 3.0 specification: `doc/openapi.yml` in the repository root. Served via `@grpn/swagger-ui` in development mode.
