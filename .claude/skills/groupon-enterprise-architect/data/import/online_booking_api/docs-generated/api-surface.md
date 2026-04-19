---
service: "online_booking_api"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [hmac]
---

# API Surface

## Overview

The Online Booking API exposes a JSON REST API in two active versions (`v2`, `v3`) and one deprecated CS namespace (`v2/cs`). Consumers use it to manage reservations and reservation requests, query availability, configure merchant and place booking settings, and log CS contact attempts. The v3 endpoints are the current standard; v2 endpoints remain for backwards compatibility. Several endpoints are deprecated (returning HTTP 410 Gone or no-op) and are pending removal once downstream clients are migrated.

Authentication on protected endpoints uses a Zendesk HMAC scheme — the caller must supply a `client_id` query parameter matching the configured Zendesk client ID and an `Authorization` header containing an HMAC-SHA1 signature and nonce derived from the request verb, URL, query string, and body hash.

## Endpoints

### Reservations (v3)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v3/reservations` | List reservations; filterable by `user_id`, `order_id`, `order_ids`, `voucher_id`, `voucher_ids`, `scope`, `reservation_request_id`; supports `limit`/`offset` pagination | Required |
| `POST` | `/v3/reservations` | Create a reservation for an option; accepts `option_id`, `slot_id`, `possible_segments` or `possible_times`, `user_id`, `order_id`, `voucher_id`, `agenda_id`, `definition_version`, `class_attributes` | Required |
| `GET` | `/v3/reservations/{id}` | Get a single reservation; optional flags `include_voucher`, `include_salesforce_id`, `include_requests` | Required |
| `PATCH` | `/v3/reservations/{id}` | Update reservation status (`requested`, `user_declined`, `confirmed`, `no_merchant_response`, `merchant_declined`, `user_attended`, `user_missed`); accepts `initial_time`, `possible_segments`, `possible_times`, `quantity`, `slot_id` | Required |

### Reservation Requests (v3)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v3/reservation_requests` | List reservation requests for a merchant/calendar; filterable by `merchant_id`, `calendar_id`, `from`, `until`, `statuses`, `merchant_seen`; supports pagination via `page`/`per_page`; enriches with deals, users, calendar data in parallel | Required |
| `PATCH` | `/v3/reservation_requests/{id}` | Update a reservation request — mark as merchant-seen, extend `cancels_at`, confirm (with `initial_time`, `quantity`), or decline | Required |

### Reservation Requests (v2 — legacy)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `PATCH` | `/v2/reservation_requests/{id}` | Legacy update of reservation request status (`confirmed` or `merchant_declined`) or `merchant_seen` flag | None |

### Availability (v3)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v3/options/{id}/availability` | Return available time segments for an option in a given time window (`initial_time`, `final_time` as Unix timestamps, `quantity`); optional `agenda_id` and `format` (timestamp or iso8601) | None |

### Options (v3)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v3/options/{id}/local_booking_settings` | Return aggregated booking engine settings for an option: timezone, engine type, duration, tentative window, additional attributes, option flags, and place/country data | Required |
| `GET` | `/v3/options/{id}/next_reachable_hour` | Return the next reachable (bookable) hour for an option's place; accepts optional `min_lead_time` | Required |
| `GET` | `/v3/options/{option_id}/flags` | Return option booking flags (`active`, `g3` status) | None |
| `PATCH` | `/v3/options/{option_id}/flags` | Set option G3 flags — **deprecated**, returns 204 No Content | None |

### Places (v3)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v3/merchants/{merchant_id}/places/{id}` | Return combined notification and appointment settings for a place | Required |
| `PATCH` | `/v3/merchants/{merchant_id}/places/{id}` | Update notification and/or appointment settings for a place; supports both PUT and PATCH semantics via `patch` flag | Required |
| `GET` | `/v3/merchants/{merchant_id}/places/{place_id}/next_opening_closing_hour` | Return next/current opening and closing hour for a place; optional `min_lead_time` | Required |
| `GET` | `/v3/merchants/{merchant_id}/places/{id}/metrics` | Return booking performance metrics for a place; requires `viewtype` (`internal` or `external`) | Required |

### Override Windows (v3)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v3/merchants/{merchant_id}/places/{place_id}/override_windows` | List availability override windows for a place; optional `start_datetime`/`end_datetime` filter | Required |
| `POST` | `/v3/merchants/{merchant_id}/places/{place_id}/override_windows` | Create one or more override windows for a place; each requires `start_datetime`, `end_datetime`, `origin`, `capacity` | Required |
| `DELETE` | `/v3/override_windows/{id}` | Delete an override window by ID | Required |

### Contact Attempts (v3)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v3/contact_attempts` | Log a CS agent contact attempt against reservations/requests; requires `contact_method`, `contact_type`, `contact_success`, `target`, `notification_source`, `request_uuids`; optional Zendesk ticket metadata | Required |

### Tickets (v3 — deprecated)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v3/tickets/solved` | Log a Zendesk ticket solve — **deprecated**, returns 204 No Content | Required |

### Merchant Settings (v3 — deprecated)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v3/merchants/merchant_id/settings` | List merchant settings — **deprecated**, returns 410 Gone | None |
| `PUT` | `/v3/merchants/{merchant_id}/settings` | Update merchant settings — **deprecated**, returns 410 Gone | None |

### Calendars (v3 — deprecated)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v3/merchants/merchant_id/calendars` | Create calendar — **deprecated**, returns 410 Gone | None |

### Capacity Segments (v3 — deprecated)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v3/calendars/id/capacity` | List capacity segments — **deprecated**, returns 410 Gone | None |

### CS Parameters (v2 — deprecated)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v2/merchants/{merchant_id}/cs/parameters` | List merchant CS parameters — **deprecated**, returns empty object | Required |
| `PUT` | `/v2/merchants/{merchant_id}/cs/parameters` | Update merchant CS parameters — **deprecated**, no-op | Required |
| `PATCH` | `/v2/merchants/{merchant_id}/cs/parameters` | Patch merchant CS parameters — **deprecated**, no-op | Required |

## Request/Response Patterns

### Common headers

- `Authorization` — HMAC authentication header (format: `signature="...",nonce="..."`)
- `UserId` — caller's user UUID, logged on reservation confirm/decline operations
- `ClientId` — caller's client identifier, logged on confirm/decline operations
- `If-Modified-Since` — passed through to `continuumAppointmentsEngine` on reservation request listings; `Last-Modified` is propagated back in the response

### Error format

Errors are returned as JSON:

```json
{
  "exception": "Error message string",
  "response": {
    "code": 400,
    "body": ""
  }
}
```

Validation errors return HTTP 400. Downstream timeouts return HTTP 408. Downstream errors are proxied with their original status codes.

### Pagination

- **Reservations** (`GET /v3/reservations`): offset-based via `limit` and `offset` query parameters. `Link` header is returned and rewritten to point to `/v3/reservations`.
- **Reservation Requests** (`GET /v3/reservation_requests`): page-based via `page` and `per_page` query parameters. `X-Total`, `X-Per-Page`, and `Link` headers are returned and rewritten.

## Rate Limits

No rate limiting configured within this service.

## Versioning

URL-path versioning with prefixes `/v2/` and `/v3/`. The v3 namespace is the current standard for all new features. The v2 namespace is maintained for backwards compatibility only.

## OpenAPI / Schema References

An OpenAPI schema file is referenced in `.service.yml` as `open_api_schema_path: swagger.json`. ServiceDiscovery inline annotations in each controller file serve as the authoritative endpoint contract documentation.
