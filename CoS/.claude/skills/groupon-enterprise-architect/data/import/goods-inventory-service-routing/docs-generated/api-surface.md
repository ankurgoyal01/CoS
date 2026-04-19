---
service: "goods-inventory-service-routing"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-network]
---

# API Surface

## Overview

The API exposes a single JAX-RS resource at `/inventory/v1/products` that mirrors the upstream GIS API surface. Callers interact with this service exactly as they would with GIS directly — GISR transparently resolves which regional GIS instance to forward each request to and proxies the response back. All responses are UTF-8 encoded JSON.

## Endpoints

### Inventory Products

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/inventory/v1/products` | Retrieves inventory products by UUID(s); resolves the correct regional GIS and proxies the GET response | Internal network |
| `POST` | `/inventory/v1/products` | Creates or upserts one or more inventory products; routes to the correct regional GIS; persists shipping-region mapping on success | Internal network |
| `PUT` | `/inventory/v1/products/{uuid}` | Updates a single inventory product identified by UUID; routes to the correct regional GIS; updates shipping-region mapping on success | Internal network |

### Platform / Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/status` | JTier standard status endpoint (version, git SHA) | Internal network |
| `GET` | `/swagger` | Swagger UI (config in `doc/swagger/`) | Internal network |

## Request/Response Patterns

### Common headers

- `X-Request-Id` — passed through from caller to GIS (recommended for tracing)
- `Content-Type: application/json` — required on `POST` and `PUT` requests
- `X-HB-Region` — **injected by GISR** on outbound calls to GIS; not required from the caller

Headers `host` and `accept-encoding` are stripped before forwarding to GIS. All other request headers are propagated as-is.

### GET `/inventory/v1/products` — query parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ids` | `string` (comma-separated UUIDs) | Yes | One or more inventory product UUIDs to retrieve |

### POST `/inventory/v1/products` — request body

```json
{
  "inventoryProducts": [
    {
      "id": "<uuid>",
      "shippingRegions": ["US", "CA"]
    }
  ]
}
```

### PUT `/inventory/v1/products/{uuid}` — request body

```json
{
  "inventoryProduct": {
    "shippingRegions": ["GB", "DE"]
  }
}
```

### Error format

All errors return JSON with the following structure:

```json
{
  "httpCode": 400,
  "errors": [
    {
      "code": "MISSING_PRODUCT_ID",
      "message": "MISSING_PRODUCT_ID"
    }
  ]
}
```

Known error codes:

| Code | HTTP Status | Condition |
|------|-------------|-----------|
| `MISSING_PRODUCT_ID` | 400 | `ids` query parameter is empty on GET |
| `INVALID_PRODUCT_ID` | 400 | `ids` cannot be parsed as comma-separated UUIDs |
| `INVALID_REQUEST` | 400 | Request body cannot be parsed on POST or PUT |
| `MISSING_SHIPPING_REGIONS` | 400 | Product has no shipping regions and none are stored |
| `MIXED_SHIPPING_REGIONS` | 400 | Products in a batch span more than one geographic region |
| `NO_GIS_REGION_FOUND` | 400 | Shipping region does not match any configured GIS region |
| `INVENTORY_PRODUCT_NOT_FOUND` | 200 (empty) | No shipping-region record exists for the requested UUID(s); returns `EmptyInventoryProductsResponse` |
| `UNABLE_TO_REACH_GIS` | 500 | HTTP call to upstream GIS failed with an IOException |

### Pagination

> No evidence found in codebase. Pagination is not implemented at this layer; it is delegated to the upstream GIS.

## Rate Limits

> No rate limiting configured. Rate limiting is enforced at the Hybrid Boundary / API gateway layer.

## Versioning

API version `v1` is embedded in the URL path (`/inventory/v1/products`). This matches the upstream GIS endpoint path to which requests are proxied. No header-based versioning is in use.

## OpenAPI / Schema References

A Swagger configuration exists at `doc/swagger/swagger.yaml` and `doc/swagger/config.yml`. The Swagger resource package is `com.groupon.goods.logistics.goodsinventoryservicerouting.resources`. The Swagger UI is available at `/swagger` when the service is running.
