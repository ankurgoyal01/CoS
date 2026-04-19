---
service: "glive-gia"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, ogwall]
---

# API Surface

## Overview

GIA exposes a Rails-based HTTP API consumed primarily by its own admin UI (browser-based) and potentially by internal tooling. All endpoints are authenticated via OGWall (Groupon's internal auth service) and use Pundit policies for role-based authorization. The API manages the full lifecycle of live event deals, including their attached events, invoices, ticketing provider settings, and redemption codes. Responses are in JSON or HTML depending on request format.

## Endpoints

### Deals

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals` | List deals with filtering | OGWall session |
| POST | `/deals` | Create a new deal (multi-step via wicked wizard) | OGWall session |
| GET | `/deals/:id` | Retrieve deal details | OGWall session |
| PUT/PATCH | `/deals/:id` | Update deal attributes | OGWall session |
| DELETE | `/deals/:id` | Delete a deal | OGWall session |
| PUT/PATCH | `/deals/:id/transition` | Trigger deal state transition (e.g., draft -> published) | OGWall session |

### Events

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals/:id/events` | List events for a deal | OGWall session |
| POST | `/deals/:id/events` | Create an event on a deal | OGWall session |
| GET | `/deals/:id/events/:event_id` | Retrieve event details | OGWall session |
| PUT/PATCH | `/deals/:id/events/:event_id` | Update an event | OGWall session |
| DELETE | `/deals/:id/events/:event_id` | Delete an event | OGWall session |
| PUT/PATCH | `/deals/:id/events/bulk_update` | Bulk update multiple events | OGWall session |

### Invoices

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals/:id/invoices` | List invoices for a deal | OGWall session |
| POST | `/deals/:id/invoices` | Create an invoice for a deal | OGWall session |
| GET | `/deals/:id/invoices/:invoice_id` | Retrieve invoice details | OGWall session |
| PUT/PATCH | `/deals/:id/invoices/:invoice_id` | Update invoice | OGWall session |

### Ticketing Provider Settings

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/PUT | `/deals/:id/ticketmaster_settings` | Read or update Ticketmaster integration settings for a deal | OGWall session |
| GET/PUT | `/deals/:id/provenue_settings` | Read or update Provenue integration settings for a deal | OGWall session |
| GET/PUT | `/deals/:id/axs_settings` | Read or update AXS integration settings for a deal | OGWall session |

### Redemption Codes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals/:id/redemption_codes` | List redemption codes for a deal | OGWall session |
| POST | `/deals/:id/redemption_codes` | Add redemption codes to a deal | OGWall session |

### Users

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/users` | List GIA admin users | OGWall session |
| POST | `/users` | Create a GIA user | OGWall session |
| GET | `/users/:id` | Retrieve user details | OGWall session |
| PUT/PATCH | `/users/:id` | Update user role or attributes | OGWall session |
| DELETE | `/users/:id` | Remove a GIA user | OGWall session |

### Reports

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchant_report` | Generate or download merchant payment report | OGWall session |

## Request/Response Patterns

### Common headers

- `Accept: application/json` or `Accept: text/html` — determines response format
- `X-CSRF-Token` — required for all state-mutating requests (Rails CSRF protection)
- Session cookie managed by OGWall SSO

### Error format

Standard Rails error responses: HTTP 4xx/5xx with JSON body `{ "error": "<message>" }` for API requests, or HTML error pages for browser requests.

### Pagination

> No evidence found for an explicit pagination implementation. List endpoints may use Rails default scoping.

## Rate Limits

> No rate limiting configured. GIA is an internal admin tool; access is controlled by authentication and authorization rather than rate limits.

## Versioning

No API versioning strategy in use. All endpoints are unversioned Rails routes. This is an internal admin application not intended for external API consumers.

## OpenAPI / Schema References

> No evidence found for an OpenAPI spec, proto files, or schema definition in the inventory.
