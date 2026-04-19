---
service: "goods-inventory-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: ["internal-service-auth"]
---

# API Surface

## Overview

Goods Inventory Service exposes a RESTful HTTP/JSON API consumed by checkout services, internal platform APIs, and operational tools. The API provides endpoints for inventory product management, availability checks, reservation lifecycle, inventory unit operations, vendor tax configuration, postal code management, and admin message rules. All endpoints follow standard Groupon internal API conventions.

## Endpoints

### Inventory Products

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/inventory-products` | List inventory products with filtering and pagination | Internal |
| GET | `/inventory-products/:id` | Retrieve a single inventory product by ID | Internal |
| POST | `/inventory-products` | Create a new inventory product | Internal |
| PUT | `/inventory-products/:id` | Update an existing inventory product | Internal |
| GET | `/inventory-products/:id/availability` | Check real-time availability for a product | Internal |

### Availability

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/availability` | Bulk availability check for multiple products | Internal |
| GET | `/availability/:productId` | Single product availability with shipping options | Internal |

### Reservations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/reservations` | Create a new reservation for inventory units during checkout | Internal |
| GET | `/reservations/:id` | Retrieve reservation details | Internal |
| PUT | `/reservations/:id/confirm` | Confirm a reservation (transition to order) | Internal |
| PUT | `/reservations/:id/cancel` | Cancel an active reservation | Internal |
| DELETE | `/reservations/:id` | Release a reservation and return units to available pool | Internal |

### Inventory Units

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/inventory-units` | List inventory units with status filtering | Internal |
| GET | `/inventory-units/:id` | Retrieve a single inventory unit | Internal |
| PUT | `/inventory-units/:id` | Update inventory unit status or metadata | Internal |
| POST | `/inventory-units/reverse-fulfill` | Trigger reverse fulfillment (cancellation) for exported units | Internal |

### Vendor Tax

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/vendor-tax` | List vendor tax configurations | Internal |
| POST | `/vendor-tax` | Create or update vendor tax configuration | Internal |
| GET | `/vendor-tax/:id` | Retrieve vendor tax configuration by ID | Internal |

### Postal Codes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/postal-codes` | List supported postal codes for shipping | Internal |
| POST | `/postal-codes` | Add or update postal code entries | Internal |

### Admin Message Rules

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/admin/message-rules` | List localized message rules | Internal |
| POST | `/admin/message-rules` | Create or update message rules | Internal |
| DELETE | `/admin/message-rules/:id` | Delete a message rule | Internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` -- all requests and responses use JSON
- `Accept: application/json`
- Standard Groupon internal tracing headers for request correlation

### Error format

Errors follow standard Groupon error response format:

```json
{
  "error": {
    "code": "INVENTORY_UNAVAILABLE",
    "message": "Requested quantity exceeds available inventory",
    "details": {}
  }
}
```

### Pagination

List endpoints support offset-based pagination via query parameters:

- `offset` -- starting position (default: 0)
- `limit` -- page size (default varies by endpoint)
- Response includes `total` count for client-side pagination

## Rate Limits

No explicit rate limiting configured at the service level. Rate limiting is handled by upstream API gateway infrastructure.

## Versioning

No explicit API versioning strategy. The API evolves in a backward-compatible manner. Breaking changes are coordinated across consuming services.

## OpenAPI / Schema References

API models and DTOs are defined in the `api.json`, `api.request`, and `api.response` Java packages. No standalone OpenAPI specification file is published from this repository.
