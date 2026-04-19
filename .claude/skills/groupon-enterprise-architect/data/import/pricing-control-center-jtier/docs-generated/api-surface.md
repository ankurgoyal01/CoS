---
service: "pricing-control-center-jtier"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [doorman-token, user-email-header, role-header]
---

# API Surface

## Overview

The service exposes a REST API (JAX-RS / Dropwizard) consumed by the Control Center UI and internal tooling. Endpoints are grouped into sales lifecycle management, Custom ILS, flux model queries, product search, file upload/download, user and identity management, Quartz scheduler management, and task interruption. Authentication is enforced by an `AuthenticationFilter` that validates a Doorman `authn-token` header and checks the caller's role against allowed-role annotations. The `user-email` request header identifies the acting user for audit and SOX purposes.

## Endpoints

### Sales Lifecycle

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/sales` | List all sales | None |
| GET | `/sales/{id}` | Retrieve a specific sale by UUID | None |
| POST | `/sales/{id}/schedule` | Transition sale to `SCHEDULING_PENDING` and trigger scheduling | IMTL or SUPER |
| POST | `/sales/{id}/unschedule` | Transition sale to `UNSCHEDULING_PENDING` and trigger unscheduling | IMTL or SUPER |
| POST | `/sales/{id}/cancel` | Cancel a `NEW` sale and all its products | IMTL or SUPER |
| GET | `/sales/{id}/progress` | Get scheduling progress counts for a sale | None |
| POST | `/sales/{id}/retry` | Manually trigger retry for a stuck sale (async) | None |
| GET | `/sales/{id}/exclusion_reasons` | Get exclusion reason summary for failed products | None |
| GET | `/sales/get-sales-in-timerange` | Query ILS sales by time range, channel, and status | None (PermitAll) |
| POST | `/sales/{id}/status/{status}` | Manually override sale status for recovery | IMTL or SUPER |

### ILS File Upload

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/ils_upload` | Upload a CSV file to create a manual ILS sale with products | SUPER or IMTL |

### Custom ILS

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/custom-sales` | Create a Custom ILS sale (triggers deal options fetch) | IM, IMTL, or SUPER |
| GET | `/custom-sales/{id}` | Retrieve a Custom ILS sale with flux run details | None |

### Custom ILS Flux Model

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/customILSFluxModel` | Retrieve flux models available for a given start date | None |

### Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/search/{inventoryProductId}` | Find all sales containing a specific inventory product | SUPER, IMTL, IM, or SEARCH |

### Download

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/download/original/{id}` | Download the original uploaded CSV for a sale | SUPER, IMTL, or IM |

### Price History

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/pricehistory` | Retrieve price history for a product from the Pricing Service | None |

### Quartz Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/quartz` | List all Quartz triggers and their states | None |
| GET | `/quartz/error-state` | List all Quartz triggers in ERROR state | None |
| POST | `/quartz/{trigger}/state/{state}` | Manually set a Quartz trigger state | None |

### Task Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/tasks/interrupt` | Interrupt all running tasks (emergency stop) | None |

### User Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/user` | Create or update a Control Center user | SUPER |
| GET | `/user` | Get info for the requesting user | SUPER, IM, or IMTL |
| GET | `/user/{emailId}` | Get info for a specific user by email | SUPER, IM, or IMTL |

### Identity (v1.0)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1.0/identity` | Validate Doorman token and Control Center user presence | Doorman token |
| GET | `/v1.0/users` | List all Control Center users | SUPER |
| POST | `/v1.0/roles` | Add a role to a user | SUPER |
| PUT | `/v1.0/roles` | Update a user's role | SUPER |
| DELETE | `/v1.0/roles` | Remove a role from a user | SUPER |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Heartbeat health check | None |

## Request/Response Patterns

### Common headers

- `authn-token` — Doorman authentication token; required for role-restricted endpoints
- `user-email` — Email of the acting user; required for state-mutation endpoints (schedule, unschedule, cancel, status override, ILS upload, user upsert)
- `role` — Optional user role override; used by SUPER on unschedule to bypass cutoff window
- `channel` — Optional channel filter; used on `/sales/get-sales-in-timerange`
- `status` — Optional sale status filter; used on `/sales/get-sales-in-timerange`
- `Content-Type: application/json` — Required for JSON body endpoints
- `Content-Type: multipart/form-data` — Required for `/ils_upload`

### Error format

Standard HTTP status codes are returned. Error bodies follow the Dropwizard default JSON error format: `{ "code": <int>, "message": "<string>" }`. Validation errors return `400 Bad Request`; authorization failures return `401 Unauthorized` or `403 Forbidden`; missing resources return `404 Not Found`; role conflicts return `409 Conflict`.

### Pagination

The `/search/{inventoryProductId}` endpoint supports offset-based pagination via `from` (default: 0) and `to` (default: 99) query parameters.

## Rate Limits

No rate limiting configured.

## Versioning

Most endpoints are unversioned. The identity and role management endpoints use a `/v1.0/` URL prefix path version.

## OpenAPI / Schema References

OpenAPI 2.0 (Swagger) specification is available at `doc/swagger/swagger.yaml` in the service repository. Swagger UI configuration is at `doc/swagger/config.yml`.
