---
service: "voucher-inventory-jtier"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [hybrid-boundary, client-id]
---

# API Surface

## Overview

The Voucher Inventory JTier API exposes a REST interface for fetching inventory product data (pricing, availability, unit counts) and managing acquisition methods. Consumers query inventory products by passing a list of product IDs; the API assembles a response enriched with dynamic pricing and availability segments. The API is versioned under `/inventory/v1/`. At peak it serves approximately 800K RPM with a p99 latency target of 20ms. The Swagger/OpenAPI schema is available at `doc/swagger/openapi.json` and published from staging at `http://voucher-inventory-japp-read-vip.snc1/swagger.json`.

## Endpoints

### Inventory Products

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/inventory/v1/products` | Retrieve inventory product data (pricing, availability, unit counts) for one or more product IDs | Hybrid Boundary / Client ID |

**Key query parameters for `GET /inventory/v1/products`:**

| Parameter | Location | Required | Description |
|-----------|----------|----------|-------------|
| `ids` | query | yes | Comma-separated list of inventory product IDs |
| `activateDynamicPricing` | query | no | Activates dynamic pricing enrichment |
| `availableSegmentsStartAt` | query | no | Start of availability window |
| `availableSegmentsEndAt` | query | no | End of availability window |

**Required headers for `GET /inventory/v1/products`:**

| Header | Required | Description |
|--------|----------|-------------|
| `Accept-Language` | yes | Preferred locale list |
| `X-Country-Code` | yes | Country code for the request |
| `X-Request-Id` | yes | Unique request identifier |
| `X-Brand` | no | Brand context |
| `X-Consumer-Id` | no | Authenticated consumer ID |
| `X-Forwarded-For` | no | Originating client IP |

### Acquisition Methods

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/inventory/v1/acquisition_method` | Create one or more acquisition method records | Hybrid Boundary / Client ID |

**Key body parameters for `POST /inventory/v1/acquisition_method`:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `clientId` | string | no | Client identifier |
| `ids` | array of UUID strings | yes | Acquisition method UUIDs to create |

### Status / Admin

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/status` | Service health and deployed commit SHA | None |
| `GET` | `/quartz` | Quartz scheduler admin endpoint | Internal |

## Request/Response Patterns

### Common headers

All requests to inventory product endpoints must include `Accept-Language`, `X-Country-Code`, and `X-Request-Id`. The following headers are propagated to downstream services (Pricing, Calendar) when present:

- `X-Request-Id`
- `X-Forwarded-For`
- `Accept-Language`
- `X-Client-Roles`
- `X-Remote-User-Agent`
- `X-Country-Code`
- `X-Consumer-Id`
- `X-Brand`
- `Cookie`

### Error format

Standard Dropwizard/JTier JSON error responses. HTTP status codes follow REST conventions (400 for bad request, 403 for authentication/authorization failures, 503 for overload/unavailability).

### Pagination

> No evidence found in codebase. The `GET /inventory/v1/products` endpoint accepts a list of IDs in a single request; no cursor or page-based pagination is defined.

## Rate Limits

> No rate limiting configured at the application layer. Capacity is managed through horizontal pod scaling (HPA) and Hybrid Boundary upstream routing.

## Versioning

The API uses URL path versioning under `/inventory/v1/`. No additional API version headers are defined.

## OpenAPI / Schema References

- OpenAPI JSON schema: `doc/swagger/openapi.json`
- Swagger config: `doc/swagger/config.yml` (resource package: `com.groupon.inventoryservice.voucher.resources`)
- Service discovery schema: `doc/service_discovery/resources.json`
- Live staging schema: `http://voucher-inventory-japp-read-vip.snc1/swagger.json`
