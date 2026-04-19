---
service: "client-id"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-ogwall]
---

# API Surface

## Overview

Client ID Service exposes a dual-mode REST API: endpoints that return `text/html` for the internal management UI and endpoints that return `application/json` for machine consumers (API Proxy, API Lazlo). Versioned machine-readable API paths are prefixed with `/v2/` and `/v3/`. The service is access-controlled via an OGWall request filter (`OGWallRequestFilter`) that gates administrative operations to authorised internal users. The OpenAPI specification is available at `doc/swagger/swagger.yaml` in the repository.

## Endpoints

### Client Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/clients` | List all clients (HTML or JSON) | OGWall |
| `GET` | `/clients/new` | Render new-client creation form (`userId` required) | OGWall |
| `POST` | `/clients` | Submit new client record | OGWall |
| `GET` | `/clients/{id}` | Show client details (client, tokens, mobiles, owner) | OGWall |
| `GET` | `/clients/{id}/edit` | Render client edit form | OGWall |
| `POST` | `/clients/{id}` | Submit edited client record | OGWall |

### Token Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/tokens/new` | Render new-token form (`clientId` required) | OGWall |
| `POST` | `/tokens` | Submit new token | OGWall |
| `GET` | `/tokens/{id}/edit` | Render token edit form | OGWall |
| `POST` | `/tokens/{id}` | Submit edited token | OGWall |

### Service Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/services` | List all services (HTML or JSON) | OGWall |
| `GET` | `/services/new` | Render new-service form | OGWall |
| `POST` | `/services` | Submit new service | OGWall |
| `GET` | `/services/{serviceName}` | Show service details and its tokens | OGWall |
| `GET` | `/services/tokens/new` | Render new service-token form | OGWall |
| `POST` | `/services/tokens` | Submit new service token | OGWall |
| `GET` | `/services/tokens/{id}/edit` | Render service-token edit form | OGWall |
| `POST` | `/services/tokens/{id}` | Submit edited service token | OGWall |

### Mobile Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/mobiles/new` | Render new-mobile form (`clientId` required) | OGWall |
| `POST` | `/mobiles` | Submit new mobile record | OGWall |
| `GET` | `/mobiles/{id}/edit` | Render mobile edit form | OGWall |
| `POST` | `/mobiles/{id}` | Submit edited mobile record | OGWall |

### Schedule Management (Rate Limit Changes)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/schedules` | List all active schedules | OGWall |
| `GET` | `/schedules/new` | Render new schedule form (`tokenValue` required, `serviceName` optional) | OGWall |
| `POST` | `/schedules` | Submit new schedule | OGWall |
| `GET` | `/schedules/{id}/edit` | Render schedule edit form | OGWall |
| `POST` | `/schedules/{id}` | Submit edited schedule | OGWall |
| `POST` | `/schedules/{id}/disable` | Disable an active schedule | OGWall |

### Self-Service

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/self-service/newClientToken` | Render self-service client+token creation form | OGWall |
| `POST` | `/self-service/newClientToken` | Submit self-service client and token creation (triggers Jira ticket) | OGWall |

### User Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/users/new` | Render new admin user form | OGWall |
| `POST` | `/users/new` | Create new admin user | OGWall |

### Search (v1 — HTML + JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/search` | Search clients by field; `field` enum: `TOKEN_VALUE`, `EMAIL_ADDRESS`, `CLIENT_ROLE`, `UPDATED_AT`, `UNKNOWN` | OGWall |

### Machine-Readable Search (v2 — JSON only)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v2/search` | Search clients with filtering by `field`, `value`, `clientStatus` (`ACTIVE`, `SUSPENDED`, `EITHER`), `excludeRole`, `getAll` | Internal |
| `GET` | `/v2/search.json` | Same as `/v2/search` — explicit JSON alias | Internal |
| `GET` | `/v2/search/tokens` | Get token and client info filtered by `field`, `value`, `clientStatus`, `getAll` | Internal |
| `GET` | `/v2/search/tokens.json` | Same as `/v2/search/tokens` — explicit JSON alias | Internal |

### Service Sync (v3 — API Proxy sync endpoint)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v3/services/{serviceName}` | Get all clients and tokens for a named service; supports `updatedAfter` (timestamp), `updatedOnly` (boolean), `activeOnly` (boolean), `all` (boolean), `active` (boolean) | Internal |

### Utility

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/{path}` | Home page / index redirect | OGWall |

## Request/Response Patterns

### Common headers

- Requests that serve both HTML and JSON honour the `Accept` header; pass `Accept: application/json` to receive JSON responses from dual-mode endpoints.
- Self-service user creation uses `Content-Type: application/x-www-form-urlencoded`.

### Error format

The `ErrorView` schema returns structured error information. HTTP status codes follow standard REST conventions (200, 400, 404, 500).

### Pagination

> No evidence found of pagination parameters in the API surface documented in `swagger.yaml`.

## Rate Limits

> Not applicable — client-id is the authority that defines rate limits for other services; it does not apply rate limits to its own API surface.

## Versioning

URL path versioning is used for the machine-readable API. The management UI endpoints are unversioned. Currently active API versions:

- **v2** — `/v2/search`, `/v2/search/tokens` (JSON search API)
- **v3** — `/v3/services/{serviceName}` (service sync for API Proxy)
- **Unversioned** — HTML management UI endpoints

## OpenAPI / Schema References

- OpenAPI spec: `doc/swagger/swagger.yaml` (Swagger 2.0)
- JSON service discovery: `doc/service_discovery/resources.json`
