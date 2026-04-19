---
service: "goods-stores-api"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [token, api-key]
---

# API Surface

## Overview

Goods Stores API exposes a versioned REST API (v1, v2, v3) mounted via Grape under Rails. Consumers include GPAPI clients, merchant tooling, and internal Groupon services. The API covers the full lifecycle of goods domain resources: products, options, merchants, contracts, attachments, search, and tax details. All requests are authenticated and authorized through the `continuumGoodsStoresApi_auth` component using GPAPI token validation and role/feature-flag checks.

## Endpoints

### V1 Endpoints (Legacy)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/merchants` | List merchants | Token |
| GET | `/v1/merchants/:id` | Fetch merchant details | Token |
| GET | `/v1/products` | List goods products | Token |
| GET | `/v1/products/:id` | Fetch product details | Token |
| GET | `/v1/inventory` | Read inventory records | Token |
| GET | `/v1/tokens` | Token validation helper | Token |
| GET | `/v1/taxonomy` | Fetch taxonomy categories | Token |
| GET | `/v1/attachments` | List attachments | Token |

### V2 Endpoints (Primary)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/products` | List goods products with filters | Token |
| POST | `/v2/products` | Create a goods product | Token |
| GET | `/v2/products/:id` | Fetch product details | Token |
| PUT | `/v2/products/:id` | Update product | Token |
| DELETE | `/v2/products/:id` | Delete product | Token |
| GET | `/v2/products/:id/options` | List options for a product | Token |
| POST | `/v2/products/:id/options` | Create option for a product | Token |
| PUT | `/v2/products/:id/options/:option_id` | Update product option | Token |
| DELETE | `/v2/products/:id/options/:option_id` | Delete product option | Token |
| GET | `/v2/contracts` | List contracts | Token |
| POST | `/v2/contracts` | Create contract | Token |
| GET | `/v2/contracts/:id` | Fetch contract details | Token |
| PUT | `/v2/contracts/:id` | Update contract | Token |
| GET | `/v2/merchants` | List merchants | Token |
| POST | `/v2/merchants` | Create merchant | Token |
| GET | `/v2/merchants/:id` | Fetch merchant details | Token |
| PUT | `/v2/merchants/:id` | Update merchant | Token |
| GET | `/v2/merchants/:id/tax` | Fetch merchant Avalara tax details | Token |
| PUT | `/v2/merchants/:id/tax` | Update merchant Avalara tax details | Token |
| POST | `/v2/attachments` | Upload attachment or image | Token |
| DELETE | `/v2/attachments/:id` | Delete attachment | Token |
| GET | `/v2/search/products` | Elasticsearch-backed product search | Token |
| GET | `/v2/search/agreements` | Elasticsearch-backed agreement search | Token |
| GET | `/v2/vendors` | List vendors | Token |
| GET | `/v2/roles` | List roles | Token |

### V3 Endpoints (GMPA / Deals)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v3/brands` | List brands | Token |
| POST | `/v3/brands` | Create brand | Token |
| GET | `/v3/deals` | List deal instances | Token |
| POST | `/v3/deals` | Create deal instance | Token |
| GET | `/v3/deals/:id` | Fetch deal instance | Token |
| PUT | `/v3/deals/:id` | Update deal instance | Token |

### Status / Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/status` | Application status check | None |
| GET | `/heartbeat` | Liveness probe | None |

## Request/Response Patterns

### Common headers

- `Authorization: Token <token>` — GPAPI token for all authenticated endpoints
- `Content-Type: application/json` — Required for POST/PUT requests
- `Accept: application/json` — Standard JSON response format

### Error format

Errors are returned as JSON objects with an `error` or `errors` key:

```json
{ "error": "Unauthorized" }
{ "errors": ["Name can't be blank", "Price must be greater than 0"] }
```

HTTP status codes follow REST conventions: 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 422 Unprocessable Entity, 500 Internal Server Error.

### Pagination

List endpoints support `page` and `per_page` query parameters. Responses include pagination metadata in the response envelope.

## Rate Limits

> No rate limiting configured at the application layer. Infrastructure-level throttling may apply via upstream load balancers or API gateway.

## Versioning

API versioning is path-based: `/v1/`, `/v2/`, `/v3/`. All three versions are simultaneously mounted by the `continuumGoodsStoresApi_grapeApp` Grape router. V1 is legacy; V2 is the primary interface; V3 adds GMPA/Deals management endpoints.

## OpenAPI / Schema References

> No OpenAPI spec file was identified in the repository inventory. API contracts are defined via Grape DSL endpoint declarations within the service.
