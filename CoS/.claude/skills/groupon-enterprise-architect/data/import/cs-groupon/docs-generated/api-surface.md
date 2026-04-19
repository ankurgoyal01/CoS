---
service: "cs-groupon"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, warden]
---

# API Surface

## Overview

cyclops exposes a versioned REST API under the `/api/v1`, `/api/v2`, and `/api/v3` path prefixes. The API is consumed by internal CS tools and integrations, providing programmatic access to order data, deal metadata, user profiles, and product information. All responses are JSON. Authentication is handled via session cookies backed by Warden middleware.

## Endpoints

### Orders

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/orders` | List orders for a customer or query | session |
| GET | `/api/v1/orders/:id` | Retrieve a single order by ID | session |
| POST | `/api/v1/orders/:id/refund` | Initiate a refund for an order | session |
| GET | `/api/v2/orders` | List orders (v2 schema) | session |
| GET | `/api/v2/orders/:id` | Retrieve a single order (v2 schema) | session |
| GET | `/api/v3/orders` | List orders (v3 schema) | session |
| GET | `/api/v3/orders/:id` | Retrieve a single order (v3 schema) | session |

### Users

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/users/:id` | Retrieve user profile by ID | session |
| GET | `/api/v2/users/:id` | Retrieve user profile (v2 schema) | session |
| GET | `/api/v3/users/:id` | Retrieve user profile (v3 schema) | session |

### Deals

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/deals/:id` | Retrieve deal metadata by ID | session |
| GET | `/api/v2/deals/:id` | Retrieve deal metadata (v2 schema) | session |

### Products

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/products/:id` | Retrieve product details by ID | session |
| GET | `/api/v2/products/:id` | Retrieve product details (v2 schema) | session |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all POST/PUT requests
- `Accept: application/json` — expected on all API requests
- Session cookie set by Warden on successful agent authentication

### Error format

> No evidence found for a documented standard error schema. Errors are expected to follow Rails default JSON error responses with an HTTP status code and a JSON body containing an `error` or `errors` key.

### Pagination

> No evidence found for a documented pagination scheme. Standard Rails-style `page` and `per_page` query parameters are common in this stack.

## Rate Limits

> No rate limiting configured.

## Versioning

The API uses URL path versioning (`/api/v1`, `/api/v2`, `/api/v3`). All three versions are active. Version selection is determined by the path prefix of the request. Older versions are maintained for backward compatibility with existing CS tool integrations.

## OpenAPI / Schema References

> No evidence found for an OpenAPI spec, proto files, or GraphQL schema in this repository.
