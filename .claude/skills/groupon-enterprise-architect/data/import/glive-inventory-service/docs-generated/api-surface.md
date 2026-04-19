---
service: "glive-inventory-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, session]
---

# API Surface

## Overview

GLive Inventory Service exposes a set of JSON-based REST APIs organized across multiple versioned namespaces. The primary consumers are the Groupon Website (for customer-facing inventory and availability queries), the GLive Inventory Admin UI (for operational management), and internal Continuum services. Varnish HTTP cache sits in front of the service to cache high-traffic availability and inventory responses. The API controllers are defined in the `continuumGliveInventoryService_httpApi` component and validated against schema objects in `continuumGliveInventoryService_schemas`.

## Endpoints

### Status / Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/status` | Service health check and readiness probe | None |

### GLive v1 API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/glive/v1/products` | List ticket products with filtering and pagination | API key |
| GET | `/glive/v1/products/:id` | Get a specific ticket product by ID | API key |
| POST | `/glive/v1/products` | Create a new ticket product | API key |
| PUT | `/glive/v1/products/:id` | Update an existing ticket product | API key |
| DELETE | `/glive/v1/products/:id` | Delete a ticket product | API key |
| GET | `/glive/v1/products/:id/events` | List events for a ticket product | API key |
| POST | `/glive/v1/products/:id/events` | Create events for a ticket product | API key |
| PUT | `/glive/v1/events/:id` | Update an event | API key |
| GET | `/glive/v1/reservations` | List reservations | API key |
| POST | `/glive/v1/reservations` | Create a new reservation | API key |
| PUT | `/glive/v1/reservations/:id` | Update a reservation | API key |
| DELETE | `/glive/v1/reservations/:id` | Cancel/release a reservation | API key |

### GLive v2 API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/glive/v2/products` | List ticket products (v2 schema) | API key |
| GET | `/glive/v2/products/:id` | Get a specific ticket product (v2 schema) | API key |
| POST | `/glive/v2/products` | Create a ticket product (v2 schema) | API key |
| PUT | `/glive/v2/products/:id` | Update a ticket product (v2 schema) | API key |
| GET | `/glive/v2/events` | List events (v2 schema) | API key |
| POST | `/glive/v2/reservations` | Create a reservation (v2 schema) | API key |

### Inventory v1 API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/inventory/v1/availability` | Query ticket availability for a product/event | API key |
| GET | `/inventory/v1/availability/:product_id` | Get availability for a specific product | API key |

### Warehouse API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/warehouse/products` | Warehouse-level product inventory query | API key |
| GET | `/warehouse/events` | Warehouse-level event inventory query | API key |

### Alerts API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/alerts` | Retrieve system alerts and notifications | API key |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` -- all request and response bodies are JSON
- `Accept: application/json` -- expected on all requests
- API key header or parameter for authentication (service-to-service)
- Standard Groupon request tracing headers for observability

### Error format

Errors follow a standard JSON envelope:

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Human-readable error description",
    "details": []
  }
}
```

HTTP status codes follow REST conventions: 400 for validation errors, 401/403 for auth failures, 404 for missing resources, 422 for unprocessable entities, 500 for server errors.

### Pagination

List endpoints support offset-based pagination via `page` and `per_page` query parameters. Responses include pagination metadata in the response body or headers.

## Rate Limits

Rate limiting is managed at the Varnish and infrastructure level rather than within the application. Varnish caches availability and inventory responses to reduce backend load.

> Application-level rate limiting is not configured within the service. Traffic management is handled by the Varnish HTTP cache layer (`continuumGliveInventoryVarnish`) and upstream load balancers.

## Versioning

API versioning uses URL path segments. Two major versions are maintained:

- **v1**: Original GLive API namespace (`/glive/v1/...`)
- **v2**: Updated API namespace with revised schemas (`/glive/v2/...`)
- **inventory/v1**: Dedicated availability query namespace (`/inventory/v1/...`)

Both v1 and v2 are active. Schema objects under `continuumGliveInventoryService_schemas` define the request/response contracts for each version.

## OpenAPI / Schema References

Schema definitions are maintained as Ruby schema objects in `app/schemas/` within the service codebase. These define and validate JSON request and response structures for the public APIs. No standalone OpenAPI specification file is published; the schema objects serve as the authoritative contract definition.
