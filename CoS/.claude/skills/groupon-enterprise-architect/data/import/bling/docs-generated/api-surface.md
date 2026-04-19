---
service: "bling"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [oauth2]
---

# API Surface

## Overview

bling is a client-side SPA and does not expose its own API surface. It acts solely as a consumer of the Accounting Service API and the File Sharing Service API. All API calls originate from the browser and are proxied through `blingNginx` to the appropriate backend service. The following documents the API routes that bling consumes through the Nginx proxy.

## Endpoints

### Accounting Service — Invoices (proxied via Nginx to Accounting Service)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/invoices` | List invoices with filtering | OAuth2 (Okta) |
| GET | `/api/v1/invoices/:id` | Retrieve invoice detail | OAuth2 (Okta) |
| PATCH | `/api/v1/invoices/:id` | Update invoice status (approve/reject) | OAuth2 (Okta) |
| GET | `/api/v2/invoices` | List invoices (v2 schema) | OAuth2 (Okta) |
| GET | `/api/v3/invoices` | List invoices (v3 schema) | OAuth2 (Okta) |

### Accounting Service — Contracts (proxied)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/contracts` | List contracts | OAuth2 (Okta) |
| GET | `/api/v1/contracts/:id` | Retrieve contract detail | OAuth2 (Okta) |
| GET | `/api/v1/contracts/:id/line_items` | List contract line items | OAuth2 (Okta) |
| PATCH | `/api/v1/contracts/:id` | Update contract | OAuth2 (Okta) |

### Accounting Service — Payments (proxied)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/payments` | List payments | OAuth2 (Okta) |
| POST | `/api/v1/payments` | Create payment | OAuth2 (Okta) |
| GET | `/api/v2/payments` | List payments (v2 schema) | OAuth2 (Okta) |

### Accounting Service — Batches (proxied)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/batches` | List payment batches | OAuth2 (Okta) |
| POST | `/api/v1/batches` | Create payment batch | OAuth2 (Okta) |
| GET | `/api/v1/batches/:id` | Retrieve batch detail | OAuth2 (Okta) |

### Accounting Service — Paysource Files (proxied)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/paysource-files` | List paysource files | OAuth2 (Okta) |
| POST | `/api/v1/paysource-files` | Upload paysource file | OAuth2 (Okta) |
| GET | `/api/v1/paysource-files/:id` | Retrieve paysource file detail | OAuth2 (Okta) |

### Accounting Service — Users, Search, System Errors (proxied)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/users` | List finance users | OAuth2 (Okta) |
| GET | `/api/v1/search` | Cross-entity batch search | OAuth2 (Okta) |
| GET | `/api/v1/system-errors` | List system errors for review | OAuth2 (Okta) |

### File Sharing Service (proxied)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/file-sharing-service/files` | List files for accounting records | OAuth2 (Okta) |
| GET | `/file-sharing-service/files/:id` | Download a specific file | OAuth2 (Okta) |
| POST | `/file-sharing-service/files` | Upload a file | OAuth2 (Okta) |

## Request/Response Patterns

### Common headers

- `Authorization: Bearer <okta_token>` — injected by the Hybrid Boundary OAuth proxy for all proxied API calls
- `Content-Type: application/json` — used for all write requests
- `Accept: application/json` — expected on all data requests

### Error format

Errors are returned by the Accounting Service backend and surfaced in the bling UI. HTTP status codes are used semantically; error bodies are JSON objects with message fields.

### Pagination

> No evidence found in codebase. Standard query parameter pagination (page, per_page) assumed for Accounting Service list endpoints based on API v1–v3 patterns.

## Rate Limits

> No rate limiting configured at the bling Nginx proxy layer. Rate limits, if any, are enforced by the Accounting Service backend.

## Versioning

bling consumes Accounting Service API versions v1, v2, and v3 concurrently. The version used for each resource type is determined by the Accounting Service's API roadmap. URL path versioning (`/api/v1/`, `/api/v2/`, `/api/v3/`) is used.

## OpenAPI / Schema References

> No evidence found in codebase. bling is a consumer application; schema definitions are owned by the Accounting Service. No OpenAPI spec file has been identified in the bling inventory.
