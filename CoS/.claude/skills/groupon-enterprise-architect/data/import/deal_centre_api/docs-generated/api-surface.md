---
service: "deal_centre_api"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

Deal Centre API exposes a REST/JSON API over HTTPS consumed by Deal Centre UI and internal Groupon tooling. The API covers three major capability areas: merchant deal management (creating and updating deals, options, and products), buyer deal browsing and purchase workflows, and product catalog administration. All endpoints follow Spring MVC conventions with JSON request/response bodies.

## Endpoints

### Deal Management (Merchant Workflows)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals` | List deals for the authenticated merchant | Session |
| GET | `/deals/{dealId}` | Retrieve a single deal by ID | Session |
| POST | `/deals` | Create a new deal | Session |
| PUT | `/deals/{dealId}` | Update an existing deal | Session |
| DELETE | `/deals/{dealId}` | Remove a deal | Session |
| GET | `/deals/{dealId}/options` | List options for a deal | Session |
| POST | `/deals/{dealId}/options` | Create a deal option | Session |
| PUT | `/deals/{dealId}/options/{optionId}` | Update a deal option | Session |

### Product Catalog (Admin / Merchant Workflows)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/catalog/products` | List catalog products | Session |
| GET | `/catalog/products/{productId}` | Retrieve a catalog product | Session |
| POST | `/catalog/products` | Create a catalog product | Session |
| PUT | `/catalog/products/{productId}` | Update a catalog product | Session |
| DELETE | `/catalog/products/{productId}` | Remove a catalog product | Session |

### Buyer Workflows

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/buyer/deals` | Browse available deals for buyers | Session |
| GET | `/buyer/deals/{dealId}` | Retrieve deal detail for buyer view | Session |

### Health and Diagnostics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/actuator/health` | Spring Actuator health check | None |
| GET | `/actuator/info` | Application info | None |
| GET | `/actuator/metrics` | Application metrics | None |

> Note: Exact endpoint paths are inferred from component responsibilities (`dca_apiControllers`) and standard Spring Boot / Deal Centre conventions. Refer to the OpenAPI spec in the service repository for authoritative path definitions.

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all write requests
- `Accept: application/json` — standard on all requests
- Session cookie or internal auth header for authenticated endpoints

### Error format

Standard Spring Boot error response shape:

```json
{
  "timestamp": "2026-03-02T00:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "...",
  "path": "/deals"
}
```

### Pagination

> No evidence found for a specific pagination scheme. Likely uses page/size query parameters consistent with Spring Data conventions.

## Rate Limits

> No rate limiting configured in the active architecture model.

## Versioning

> No evidence found for explicit API versioning. Endpoints do not carry a version prefix in the modeled architecture. Versioning strategy to be confirmed with the service owner.

## OpenAPI / Schema References

> OpenAPI specification lives in the deal_centre_api service repository. Not present in this architecture import folder.
