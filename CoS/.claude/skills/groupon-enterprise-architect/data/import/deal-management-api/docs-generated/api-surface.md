---
service: "deal-management-api"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, internal-service-token]
---

# API Surface

## Overview

DMAPI exposes a versioned REST API (v1 through v3) consumed by internal Groupon tools, merchant portals, and service-to-service integrations. The API covers the full deal lifecycle — creation, retrieval, update, deletion, and lifecycle transitions (publish, unpublish, pause, approve) — as well as supporting resources such as merchants, places, inventory products, contract data, and operational metadata. All endpoints communicate over HTTPS using JSON payloads. API clients are registered and rate-limited via the `/clients` resource.

## Endpoints

### Deals (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/deals` | List deals with filtering | API key / service token |
| POST | `/v1/deals` | Create a new deal (sync) | API key / service token |
| GET | `/v1/deals/:id` | Retrieve a deal by ID | API key / service token |
| PUT | `/v1/deals/:id` | Update a deal | API key / service token |
| DELETE | `/v1/deals/:id` | Delete a deal | API key / service token |
| POST | `/v1/deals/:id/publish` | Publish a deal | API key / service token |
| POST | `/v1/deals/:id/unpublish` | Unpublish a deal | API key / service token |
| POST | `/v1/deals/:id/pause` | Pause a deal | API key / service token |
| POST | `/v1/deals/:id/approve` | Submit deal for approval | API key / service token |

### Deals (v2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/deals` | List deals (v2 contract) | API key / service token |
| POST | `/v2/deals` | Create a deal (async, enqueues background job) | API key / service token |
| GET | `/v2/deals/:id` | Retrieve deal (v2 contract) | API key / service token |
| PUT | `/v2/deals/:id` | Update deal (v2 contract) | API key / service token |

### Deals (v3)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v3/deals` | List deals (v3 contract) | API key / service token |
| POST | `/v3/deals` | Create a deal (v3 contract) | API key / service token |
| GET | `/v3/deals/:id` | Retrieve deal (v3 contract) | API key / service token |
| PUT | `/v3/deals/:id` | Update deal (v3 contract) | API key / service token |

### Merchants (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/merchants` | List merchants | API key / service token |
| GET | `/v1/merchants/:id` | Retrieve a merchant by ID | API key / service token |

### Places (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/places` | List places | API key / service token |
| GET | `/v1/places/:id` | Retrieve a place by ID | API key / service token |

### Inventory Products (v2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/inventory_products` | List inventory products for a deal | API key / service token |
| POST | `/v2/inventory_products` | Create or associate inventory product | API key / service token |
| PUT | `/v2/inventory_products/:id` | Update inventory product pricing/config | API key / service token |

### Contract Data Service (v2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/contract_data_service/contracts` | List contracts | API key / service token |
| GET | `/v2/contract_data_service/contracts/:id` | Retrieve contract | API key / service token |
| POST | `/v2/contract_data_service/contract_parties` | Create contract party | API key / service token |
| PUT | `/v2/contract_data_service/contract_parties/:id` | Update contract party | API key / service token |
| DELETE | `/v2/contract_data_service/contract_parties/:id` | Remove contract party | API key / service token |

### Operational

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/clients` | List registered API clients and rate limit configs | Admin token |
| POST | `/clients` | Register a new API client | Admin token |
| PUT | `/clients/:id` | Update client rate limit configuration | Admin token |
| GET | `/write_requests` | Query tracked write operation log | API key / service token |
| GET | `/history` | Retrieve deal change history | API key / service token |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all write requests
- `Accept: application/json` — expected on all requests
- `Authorization` — bearer token or API key depending on client registration

### Error format

Errors are returned as JSON with a top-level `errors` array. Each error object includes a `code`, `message`, and optionally a `field` for validation failures. HTTP status codes follow REST conventions (400 for client errors, 422 for validation errors, 404 for not found, 500 for server errors).

### Pagination

List endpoints support offset-based pagination via `page` and `per_page` query parameters. Responses include metadata fields indicating total record count and current page.

## Rate Limits

Rate limit configuration is managed per registered client via the `/clients` resource. Clients must be pre-registered before making API calls.

| Tier | Limit | Window |
|------|-------|--------|
| Registered client | Configured per client | Configurable per client |

> Specific numeric limits are configured per client in the database and are not globally fixed.

## Versioning

DMAPI uses URL path versioning. The version prefix (`/v1`, `/v2`, `/v3`) is part of the resource path. Newer versions represent evolved request/response contracts; older versions are maintained for backward compatibility with existing consumers.

## OpenAPI / Schema References

> No OpenAPI spec or schema file was identified in the inventory. Contact the dms-dev team for current contract definitions.
