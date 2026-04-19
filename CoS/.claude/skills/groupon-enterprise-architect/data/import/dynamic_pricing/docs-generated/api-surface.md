---
service: "dynamic_pricing"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

The Pricing Service exposes a versioned REST API under the `/pricing_service/v2.0/` base path. Consumers use it to read current and future prices, submit retail price updates, manage program prices in bulk, query price history, and administer price rules. All endpoints are accessible through the `continuumDynamicPricingNginx` proxy layer, which routes requests to read/write pricing pods.

## Endpoints

### Current Price

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/pricing_service/v2.0/product/{id}/current_price` | Retrieve current price summary for a single product | Internal |
| PUT | `/pricing_service/v2.0/product/{id}/current_price` | Update the current price for a product | Internal |

### Retail Price

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/pricing_service/v2.0/product/{id}/retail_price` | Retrieve the retail price for a product | Internal |
| PUT | `/pricing_service/v2.0/product/{id}/retail_price` | Update the retail price for a product | Internal |

### Program Price

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/pricing_service/v2.0/program_price` | Bulk create program prices with validation | Internal |
| DELETE | `/pricing_service/v2.0/program_price` | Delete program prices | Internal |

### Price History

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/pricing_service/v2.0/history/quote_id/{id}` | Retrieve price history records by quote ID | Internal |

### Price Rules

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/pricing_service/v2.0/price_rule` | Retrieve price rules for a product | Internal |
| POST | `/pricing_service/v2.0/price_rule` | Create a new price rule | Internal |
| PUT | `/pricing_service/v2.0/price_rule/{id}` | Update an existing price rule | Internal |
| DELETE | `/pricing_service/v2.0/price_rule/{id}` | Delete a price rule | Internal |

### Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/heartbeat.txt` | Kubernetes liveness/readiness health check (served by NGINX) | None |

## Request/Response Patterns

### Common headers

- Internal service-to-service requests are routed via the `apiProxy` and `continuumDynamicPricingNginx` layers.
- Standard Continuum internal auth headers are expected on requests originating from the API proxy.

### Error format

> No evidence found for a standardized error response schema in the available architecture inventory. Error handling is managed within the RESTEasy servlet layer.

### Pagination

> No evidence found for pagination patterns on current endpoints. Bulk operations (e.g., program price creation) accept batched request payloads.

## Rate Limits

> No rate limiting configured. Traffic shaping is handled upstream by the `apiProxy` and NGINX routing layer.

## Versioning

The API uses URL path versioning. The current version is `v2.0`, embedded in all endpoint paths under `/pricing_service/v2.0/`.

## OpenAPI / Schema References

> No evidence found for an OpenAPI spec, proto files, or schema registry entry in the available inventory. Schema definitions are embedded in Java RESTEasy servlet classes.
