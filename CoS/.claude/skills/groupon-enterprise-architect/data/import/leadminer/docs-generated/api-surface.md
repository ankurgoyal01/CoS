---
service: "leadminer"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

Leadminer exposes a browser-oriented REST interface used by internal operators. All routes serve HTML views (Rails MVC) with supporting JSON endpoints for autocomplete and API lookups. The service is not a public API — it is an internal editorial tool protected by Control Room session authentication.

## Endpoints

### Places

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/p` | Search and list Place records | Session |
| GET | `/p/:id` | View a single Place record | Session |
| GET/POST | `/p/:id/edit` | Edit a Place record | Session |
| POST | `/p/merge` | Merge two or more Place records | Session |
| POST | `/p/defrank` | Defrank a Place record | Session |
| GET | `/p/autocomplete` | Type-ahead autocomplete for place search | Session |

### Merchants

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/m` | Search and list Merchant records | Session |
| GET | `/m/:id` | View a single Merchant record | Session |
| GET/POST | `/m/:id/edit` | Edit a Merchant record | Session |

### Input History

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/i` | Browse input history records for places and merchants | Session |

### API (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/business_categories` | List available business categories | Session |
| GET | `/api/services` | List available service types | Session |
| GET | `/api/geocode` | Resolve an address to geocoordinates | Session |

### Users

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/u` | List internal users | Session |
| GET/POST | `/u/:id` | View or edit an internal user | Session |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/heartbeat` | Health check — returns service liveness status | None |

## Request/Response Patterns

### Common headers

- Standard Rails session cookie for authenticated routes
- `Accept: text/html` for browser page requests
- `Accept: application/json` for API (`/api/*`) and autocomplete endpoints

### Error format

Rails standard error pages (HTML) for browser routes; JSON error objects for `/api/*` endpoints. Specific error shapes are not discoverable from the inventory.

### Pagination

Search result lists at `/p` and `/m` use `will_paginate` for page-based pagination. Page size and parameter names follow Rails `will_paginate` conventions (typically `?page=N`).

## Rate Limits

> No rate limiting configured.

## Versioning

No API versioning strategy. All routes are unversioned; this is an internal tool without external consumers.

## OpenAPI / Schema References

> No evidence found in codebase.
