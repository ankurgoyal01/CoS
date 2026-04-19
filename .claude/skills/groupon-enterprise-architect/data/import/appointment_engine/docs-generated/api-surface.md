---
service: "appointment_engine"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, session]
---

# API Surface

## Overview

The appointment engine exposes two versioned REST API namespaces: V2 (legacy, reservation-request-centric) and V3 (current, full appointment lifecycle management). V3 adds state transition actions (confirm, decline, reschedule, attend, miss) and richer entity models (tickets, contact attempts, option flags, voucher status). Smoke test endpoints provide basic health verification. All endpoints return JSON.

## Endpoints

### V2 — Reservation Requests

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/reservation_requests` | List reservation requests | API key / session |
| POST | `/v2/reservation_requests` | Create a new reservation request | API key / session |
| GET | `/v2/reservation_requests/:id` | Fetch a single reservation request | API key / session |
| PUT | `/v2/reservation_requests/:id` | Update a reservation request | API key / session |
| DELETE | `/v2/reservation_requests/:id` | Cancel / delete a reservation request | API key / session |

### V2 — Reservations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/reservations` | List confirmed reservations | API key / session |
| GET | `/v2/reservations/:id` | Fetch a single reservation | API key / session |

### V2 — Appointments Parameters

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/appointments_parameters` | Fetch appointment configuration options | API key / session |

### V3 — Reservations (Full Lifecycle)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v3/reservations` | List reservations (paginated via kaminari) | API key / session |
| POST | `/v3/reservations` | Create a new reservation | API key / session |
| GET | `/v3/reservations/:id` | Fetch a single reservation | API key / session |
| PUT | `/v3/reservations/:id` | Update a reservation | API key / session |
| DELETE | `/v3/reservations/:id` | Cancel a reservation | API key / session |
| POST | `/v3/reservations/:id/confirm` | Confirm an appointment (merchant action) | API key / session |
| POST | `/v3/reservations/:id/decline` | Decline an appointment (merchant action) | API key / session |
| POST | `/v3/reservations/:id/reschedule` | Reschedule an appointment | API key / session |
| POST | `/v3/reservations/:id/attend` | Mark appointment as attended | API key / session |
| POST | `/v3/reservations/:id/miss` | Mark appointment as missed/no-show | API key / session |

### V3 — Supporting Entities

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v3/reservations/:id/voucher_status` | Get voucher redemption status for appointment | API key / session |
| GET/PUT | `/v3/reservations/:id/option_flags` | Read or update per-appointment option flags | API key / session |
| GET/POST | `/v3/reservations/:id/contact_attempts` | List or record consumer/merchant contact attempts | API key / session |
| GET | `/v3/reservations/:id/tickets` | List appointment tickets | API key / session |

### Smoke Tests / Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/smoke_test` | Basic health check / smoke test endpoint | None (internal) |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST/PUT requests
- `Accept: application/json` — expected by all endpoints
- `Authorization` — API key or session token for authenticated endpoints
- `X-Groupon-Client-Id` — internal client identifier

### Error format

> No evidence found in codebase for exact error response schema. Standard Rails API JSON error responses expected: `{ "errors": [...] }` or `{ "error": "message" }` with appropriate HTTP status codes (400, 404, 422, 500).

### Pagination

List endpoints use kaminari-based pagination. Expected query parameters:

- `page` — page number (1-indexed)
- `per_page` — records per page

## Rate Limits

> No rate limiting configured at the application layer.

## Versioning

API versioning is URL path-based:
- `/v2/*` — legacy reservation request API (V2)
- `/v3/*` — current full-lifecycle appointment API (V3)

Both versions are actively maintained. V3 is the preferred API for all new integrations.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec or schema files found in the service repository.
