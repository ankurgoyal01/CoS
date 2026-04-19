---
service: "merchant-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

The M3 Merchant Service exposes a REST/JSON API mounted under the context path `/merchantservice`. All requests require a `client_id` query parameter that is validated against an allowlist. The service serves three API versions simultaneously: v2.1 (primary CRUD and feature management), v2.2 (MMUD sync), and v3 (where applicable). GET endpoints at `/merchantservice/v2.1/merchants/{id}` are the highest-volume paths, handling up to 2.5 million requests per minute in US production.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchantservice/v2.1/merchants/heartbeat` | Liveness and readiness probe; returns `ok` | `client_id` param |
| GET | `/merchantservice/v2.2/merchants/heartbeat` | MMUD controller heartbeat | `client_id` param |

### Merchants (v2.0 / v2.1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchantservice/v2.0/merchants` | List all merchants (paginated) | `client_id` param |
| GET | `/merchantservice/v2.1/merchants` | List merchants with filtering and sorting | `client_id` param |
| GET | `/merchantservice/v2.1/merchants/{id}` | Retrieve single merchant by M3 UUID | `client_id` param |
| GET | `/merchantservice/v2.1/merchants/count` | Return total merchant count | `client_id` param |
| POST | `/merchantservice/v2.1/merchants` | Create a new merchant record | `client_id` param |
| PUT | `/merchantservice/v2.1/merchants/{id}` | Update an existing merchant record | `client_id` param |
| POST | `/merchantservice/v2.1/merchants/{id}/writeup` | Create merchant writeup | `client_id` param |
| PUT | `/merchantservice/v2.1/merchants/{id}/writeup` | Update merchant writeup | `client_id` param |

### MMUD Sync (v2.2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/merchantservice/v2.2/merchants/**` | Create or update merchant via MMUD flow (orchestrates UMAPI sync) | `client_id` param (restricted allowlist) |
| PUT | `/merchantservice/v2.2/merchants/{id}` | Update merchant via MMUD flow | `client_id` param (restricted allowlist) |

### Merchant Features (v2.1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchantservice/v2.1/merchants/{merchantId}/features` | List all boolean feature flags for a merchant | `client_id` param |
| GET | `/merchantservice/v2.1/merchants/{merchantId}/features/{name}` | Get a single feature flag by name | `client_id` param |
| POST | `/merchantservice/v2.1/merchants/{merchantId}/features` | Create or update feature flags (batch) | `client_id` param |
| POST | `/merchantservice/v2.1/merchants/sf/{salesforceAccountId}/features` | Create or update feature flags by Salesforce Account ID | `client_id` param |
| DELETE | `/merchantservice/v2.1/merchants/{merchantId}/features/{name}` | Delete a named feature flag | `client_id` param |

### Merchant Configurations (v2.1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchantservice/v2.1/merchants/{merchantId}/configurations` | List all configurations for a merchant | `client_id` param |
| GET | `/merchantservice/v2.1/merchants/{merchantId}/configurations/{configurationId}` | Get a single configuration by UUID | `client_id` param |
| GET | `/merchantservice/v2.1/merchants/{merchantId}/configurations/compact` | Get compact configuration map | `client_id` param |
| POST | `/merchantservice/v2.1/merchants/{merchantId}/configurations` | Create or update configurations (batch) | `client_id` param |
| DELETE | `/merchantservice/v2.1/merchants/{merchantId}/configurations/{configurationId}` | Delete a configuration by UUID | `client_id` param |

### Global Configurations (v2.1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchantservice/v2.1/merchants/configurations` | List all global service configurations | `client_id` param |
| GET | `/merchantservice/v2.1/merchants/configurations/{id}` | Get a global configuration by UUID | `client_id` param |
| POST | `/merchantservice/v2.1/merchants/configurations` | Save one or more global configurations | `client_id` param |

### Account Contacts (v2.1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchantservice/v2.1/account_contacts/{id}` | Retrieve account contact by Salesforce User ID | `client_id` param |
| POST | `/merchantservice/v2.1/account_contacts` | Create a new account contact | `client_id` param |
| PUT | `/merchantservice/v2.1/account_contacts/{id}` | Update an account contact by Salesforce User ID | `client_id` param |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST/PUT requests
- `Accept: application/json` — recommended for all requests

### Auth

All endpoints require a `?client_id=<value>` query parameter. The MMUD controller (`v2.2`) additionally validates the client against a restricted `Authority` allowlist and maps the client to a `source_id`. Requests with an unknown or missing `client_id` return HTTP 403 Forbidden with body `{"error_details": "client_id invalid"}`.

### Error format

```json
{ "error_details": "<message>" }
```

Standard HTTP status codes are used: 200 OK, 201 Created, 204 No Content, 400 Bad Request, 403 Forbidden, 404 Not Found, 500 Internal Server Error.

### Pagination

List endpoints support `client_id` and sorting query parameters (`sort_column`, `sort_order`). The `/merchants` list endpoint returns a paginated JSON array.

## Rate Limits

No rate limiting configured at the application layer. Rate limiting is enforced externally at the load balancer / Hybrid Boundary layer.

## Performance SLA (from `owners_manual.md`)

**US-CENTRAL1 (p99 latency / throughput):**

| Method | Endpoint | p99 (ms) | Throughput (rpm) |
|--------|----------|----------|-----------------|
| GET | `merchants/` | 20 | 40K |
| GET | `merchants/{id}` | 20 | 2.5M |
| GET | `merchants/count` | 20 | 20 |
| POST | `merchants/` | 100 | 20 |
| PUT | `merchants/` | 100 | 300 |
| POST | `merchants/{id}/writeup` | 200 | 20 |
| PUT | `merchants/{id}/writeup` | 200 | 50 |

## Versioning

API versioning is embedded in the URL path (`/v2.0/`, `/v2.1/`, `/v2.2/`). Multiple versions run concurrently in the same deployment. The MMUD sync API is exclusively at `/v2.2/`.

## OpenAPI / Schema References

OpenAPI 2.0 (Swagger) spec: `doc/swagger.json` in the service repository. Referenced in `.service.yml` at `open_api_schema_path: doc/swagger.json`.
