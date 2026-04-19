---
service: "consumer-data"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

The Consumer Data Service exposes a REST API under the `/v1` path prefix. Consumers use it to retrieve and update consumer profiles, manage physical locations associated with a consumer, and manage consumer preferences. All data is persisted in MySQL and changes trigger async events on MessageBus. The service also exposes infrastructure health endpoints.

## Endpoints

### Consumer Profile

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/consumers/:id` | Retrieve a consumer profile by ID | API key |
| PUT | `/v1/consumers/:id` | Update a consumer profile by ID | API key |

### Locations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/locations` | List locations for a consumer | API key |
| POST | `/v1/locations` | Create a new location for a consumer | API key |
| PUT | `/v1/locations` | Update an existing location | API key |
| DELETE | `/v1/locations` | Delete a location | API key |

### Preferences

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/preferences` | Retrieve consumer preferences | API key |
| POST | `/v1/preferences` | Create a consumer preference | API key |
| PUT | `/v1/preferences` | Update a consumer preference | API key |
| DELETE | `/v1/preferences` | Delete a consumer preference | API key |

### Infrastructure

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/status` | Returns service status for load-balancer health checks | None |
| GET | `/heartbeat` | Returns shallow liveness indicator | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all write requests
- `Accept: application/json` — expected on all requests
- API client credentials passed via header or query parameter (mechanism managed by `api_clients` table)

### Error format

> No evidence found in codebase for a standardised error response envelope. Follow Continuum platform conventions (JSON body with `error` key).

### Pagination

> No evidence found in codebase for pagination parameters on list endpoints.

## Rate Limits

> No rate limiting configured.

## Versioning

URL path versioning is used. All active endpoints are under `/v1`. The `api_clients` table manages authorized client registrations.

## OpenAPI / Schema References

> No evidence found in codebase for an OpenAPI spec or schema file in the repository.
