---
service: "online_booking_3rd_party"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, oauth2, token]
---

# API Surface

## Overview

The `online_booking_3rd_party` service exposes a versioned REST API (V3) consumed by other Booking Engine services and internal Groupon tools. The API manages the full lifecycle of merchant-to-provider mappings, services, authorizations, availability segments, and webhooks. It also provides smoke-test endpoints used for integration health verification.

## Endpoints

### Mappings

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v3/mappings` | List merchant-place-to-provider mappings | Token |
| POST | `/v3/mappings` | Create a new merchant-place mapping | Token |
| GET | `/v3/mappings/:id` | Retrieve a specific mapping | Token |
| PUT | `/v3/mappings/:id` | Update an existing mapping | Token |
| DELETE | `/v3/mappings/:id` | Remove a mapping | Token |

### Services

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v3/services` | List service mappings for a merchant place | Token |
| POST | `/v3/services` | Create a service mapping | Token |
| PUT | `/v3/services/:id` | Update a service mapping | Token |
| DELETE | `/v3/services/:id` | Delete a service mapping | Token |

### Authorization

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v3/authorization` | Retrieve provider authorization state for a place | Token |
| POST | `/v3/authorization` | Initiate or update provider authorization | Token |
| DELETE | `/v3/authorization` | Revoke provider authorization | Token |

### Availability

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v3/availability` | Query available slots for a mapped place/service | Token |
| GET | `/v3/segments` | List availability segments | Token |

### Webhooks (Inbound Push)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v3/webhooks/bookings` | Receive booking lifecycle push events from providers | API Key |
| POST | `/v3/webhooks/availability` | Receive availability update push events from providers | API Key |

### Smoke Tests

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v3/smoke_tests` | Verify end-to-end integration health of the service | Internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json`
- `Accept: application/json`
- `Authorization: Token <token>` or `X-API-Key: <key>` for webhook endpoints

### Error format

> No evidence found — standard Rails JSON error responses are expected (HTTP status code + JSON body with error message).

### Pagination

> No evidence found — pagination details not confirmed from inventory.

## Rate Limits

> No rate limiting configured.

## Versioning

All endpoints are prefixed with `/v3`, indicating URL-path versioning. V3 is the current active version.

## OpenAPI / Schema References

> No evidence found — no OpenAPI spec or schema file identified in this service's inventory.
