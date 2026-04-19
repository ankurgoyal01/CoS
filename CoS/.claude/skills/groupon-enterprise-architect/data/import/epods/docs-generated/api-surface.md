---
service: "epods"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, internal-service-auth]
---

# API Surface

## Overview

EPODS exposes a REST API used by internal Groupon services (Booking Tool, Orders, and other Continuum consumers) to create, cancel, and retrieve partner-backed bookings, query availability, and look up merchant, product, unit, and segment data. It also accepts inbound partner webhooks on a separate `/webhook/*` path tree. All paths are versioned under `/v1/`.

## Endpoints

### Booking

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/booking` | Create a booking with the target partner system | Internal service auth |
| DELETE | `/v1/booking/{id}` | Cancel an existing booking with the partner system | Internal service auth |
| GET | `/v1/booking/{id}` | Retrieve booking status and details from the partner system | Internal service auth |

### Availability

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/availability` | Query available slots/times for a given deal or product | Internal service auth |

### Merchant

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/merchant/{id}` | Retrieve Groupon-mapped merchant details from the partner system | Internal service auth |

### Product

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/product/{id}` | Retrieve Groupon-mapped product details from the partner system | Internal service auth |

### Segment

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/segment/{id}` | Retrieve segment (booking category) mapping data | Internal service auth |

### Unit

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/unit/{id}` | Retrieve unit (purchasable item) mapping data | Internal service auth |

### Partner Webhooks

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/webhook/*` | Receive inbound event notifications from partner systems (e.g., MindBody booking changes, Square/Shopify order updates) | Partner API key / HMAC signature |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all POST requests
- `Accept: application/json` — expected on all responses
- Authorization headers: internal service-to-service tokens on inbound requests from Groupon consumers; partner-specific HMAC or API key validation on `/webhook/*` paths

### Error format

Standard Dropwizard JSON error envelope:

```json
{
  "code": 400,
  "message": "Descriptive error message"
}
```

HTTP status codes follow REST conventions: `200 OK`, `201 Created`, `400 Bad Request`, `404 Not Found`, `500 Internal Server Error`.

### Pagination

> No evidence found of a pagination scheme on the current API surface. Availability results are bounded by query parameters (date range, deal ID).

## Rate Limits

> No rate limiting configured on EPODS endpoints. Rate limiting for outbound calls to partner APIs is managed per-partner via `failsafe` retry/circuit-breaker policies.

## Versioning

All public API endpoints are versioned via URL path prefix (`/v1/`). Webhook paths use `/webhook/*` without an explicit version; partner-specific routing is determined by path suffix and request payload.

## OpenAPI / Schema References

> No evidence found of a committed OpenAPI spec or proto files in the architecture model. Refer to the service repository's `src/main/resources/` or Swagger annotations for generated API documentation.
