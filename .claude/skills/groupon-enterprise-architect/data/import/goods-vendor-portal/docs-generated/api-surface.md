---
service: "goods-vendor-portal"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, oauth2]
---

# API Surface

## Overview

The Goods Vendor Portal is a browser-based SPA and does not expose its own API to other services. Instead, it consumes the GPAPI backend through an Nginx-proxied gateway mounted at `/goods-gateway/*`. All routes under this prefix are forwarded by Nginx to the GPAPI service. The portal uses `ember-simple-auth` for session management; authenticated routes require a valid session before the proxy will forward requests.

## Endpoints

### Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/goods-gateway/auth/login` | Authenticates merchant credentials and establishes session | None (public) |
| POST | `/goods-gateway/auth/logout` | Terminates active merchant session | Session |
| GET | `/goods-gateway/auth/session` | Retrieves current session state | Session |

### Vendor Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/goods-gateway/vendors` | Lists vendors accessible to the authenticated user | Session |
| GET | `/goods-gateway/vendors/:id` | Retrieves a specific vendor record | Session |
| PUT | `/goods-gateway/vendors/:id` | Updates vendor profile details | Session |
| GET | `/goods-gateway/self-service` | Retrieves self-service profile data (addresses, contacts, banking) | Session |
| PUT | `/goods-gateway/self-service` | Submits self-service profile updates | Session |

### Product Catalog

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/goods-gateway/products` | Lists products for the vendor | Session |
| GET | `/goods-gateway/products/:id` | Retrieves a specific product | Session |
| POST | `/goods-gateway/products` | Creates a new product | Session |
| PUT | `/goods-gateway/products/:id` | Updates an existing product | Session |

### Deals and Promotions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/goods-gateway/deals` | Lists deals for the vendor | Session |
| GET | `/goods-gateway/deals/:id` | Retrieves a specific deal | Session |
| POST | `/goods-gateway/deals` | Creates a new deal | Session |
| PUT | `/goods-gateway/deals/:id` | Updates an existing deal | Session |
| GET | `/goods-gateway/promotions` | Lists active and historical promotions | Session |
| POST | `/goods-gateway/promotions` | Creates a new promotion | Session |

### Contracts and Co-op Agreements

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/goods-gateway/contracts` | Lists contracts for the vendor | Session |
| GET | `/goods-gateway/contracts/:id` | Retrieves contract detail | Session |
| GET | `/goods-gateway/co-op-agreements` | Lists co-op agreements | Session |
| GET | `/goods-gateway/co-op-agreements/:id` | Retrieves a specific co-op agreement | Session |

### Pricing

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/goods-gateway/pricing` | Retrieves pricing rules for vendor products | Session |
| PUT | `/goods-gateway/pricing/:id` | Updates pricing for a product or deal | Session |

### Insights and Analytics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/goods-gateway/insights` | Retrieves business performance metrics and reports | Session |

### Reviews

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/goods-gateway/reviews` | Lists customer reviews for vendor products | Session |

### Features

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/goods-gateway/features` | Retrieves feature flag states for the authenticated vendor | Session |

### Files

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/goods-gateway/files` | Uploads catalog or deal asset files | Session |
| GET | `/goods-gateway/files/:id` | Downloads a previously uploaded file | Session |

### Support

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/goods-gateway/support` | Submits a support request on behalf of the vendor | Session |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all POST/PUT requests
- `Accept: application/json` — expected on all requests
- Session cookie or bearer token forwarded by Nginx to GPAPI

### Error format

Error responses follow the GPAPI contract. The portal surfaces GPAPI error payloads to the user via Ember's error route and component-level error states. The standard shape is:

```json
{
  "errors": [
    { "status": "422", "title": "Unprocessable Entity", "detail": "..." }
  ]
}
```

### Pagination

List endpoints accept `page[number]` and `page[size]` query parameters following the JSON:API pagination convention delegated to GPAPI.

## Rate Limits

> No rate limiting configured at the portal layer. Rate limiting, if any, is enforced by GPAPI upstream.

## Versioning

No explicit API versioning at the portal gateway layer. The portal targets a single GPAPI version at a time; version upgrades are coordinated deployments between the portal and GPAPI teams.

## OpenAPI / Schema References

> No OpenAPI spec is published from this repository. The API contract is owned and documented by the GPAPI team.
