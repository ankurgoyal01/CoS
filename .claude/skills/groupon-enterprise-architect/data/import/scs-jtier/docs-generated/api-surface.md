---
service: "scs-jtier"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [bcookie, consumer-id]
---

# API Surface

## Overview

scs-jtier exposes a RESTful HTTP API under the `/api/v2/cart` path prefix. All endpoints are consumed by the upstream GAPI/Lazlo gateway, which is responsible for authenticating the consumer before forwarding requests. Callers identify a cart session using the `b` header (bCookie). Authenticated users may additionally pass a `consumer_id` to associate the cart with their account. All responses are `application/json`.

The OpenAPI specification is located at `doc/swagger/swagger.yaml` in the repository.

## Endpoints

### Cart Read Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v2/cart` | Retrieve full cart contents for a user | bCookie (header `b`, required); `consumer_id` (query, optional — Lazlo authenticates) |
| `GET` | `/api/v2/cart/size` | Retrieve number of items in the cart | bCookie (header `b`, required); `consumer_id` (query, optional — Lazlo authenticates) |

### Cart Mutation Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `PUT` | `/api/v2/cart/add_items` | Add item(s) to the cart; updates quantity if the item already exists | bCookie (header `b`, required); `consumer_id` in body (optional — Lazlo authenticates) |
| `PUT` | `/api/v2/cart/update_items` | Update item quantity in the cart; inserts if the item does not exist | bCookie (header `b`, required); `consumer_id` in body (optional — Lazlo authenticates) |
| `PUT` | `/api/v2/cart/remove_items` | Remove item(s) from the cart by `option_uuid` | bCookie (header `b`, required); `consumer_id` in body (optional — Lazlo authenticates) |
| `PUT` | `/api/v2/cart/checkout_cart` | Mark the cart as checked out (deactivate) | bCookie (header `b`, required); `consumer_id` in body (optional — Lazlo authenticates) |

## Request/Response Patterns

### Common headers

All endpoints require the following request headers:

| Header | Required | Description |
|--------|----------|-------------|
| `b` | Yes | bCookie — anonymous session identifier (personal data class 4) |
| `ACCEPT-LANGUAGE` | Yes | Locale/language preference for the request |
| `X-Country-Code` | Yes | Country code used to scope cart data |

### Add/Update Items request body

```json
{
  "cart_data": {
    "items": [
      {
        "deal_uuid": "<uuid>",
        "option_uuid": "<uuid>",
        "quantity": 1,
        "booking_attributes": {
          "booking_id": "<string>",
          "check_in": "<date>",
          "check_out": "<date>",
          "child_ages": "<string>",
          "number_adults": "<string>",
          "quote_id": "<string>",
          "rate_code": "<string>",
          "room_code": "<string>"
        },
        "extra_attributes": {}
      }
    ]
  },
  "consumer_id": "<uuid>",
  "disable_auto_update": false
}
```

`booking_attributes` is applicable for TPIS/GLive/Getaways/MrGetaways deals. `extra_attributes` is a freeform `Map<String,String>` for any additional frontend data.

### Remove Items request body

```json
{
  "cart_data": {
    "items": [
      { "option_uuid": "<uuid>" }
    ]
  },
  "consumer_id": "<uuid>",
  "disable_auto_update": false
}
```

### Checkout Cart request body

```json
{
  "consumer_id": "<uuid>"
}
```

### `disable_auto_update` flag

When set to `true`, the service skips automatic removal or quantity adjustment of unavailable items during the add/update/remove operation.

### Error format

> No standardized error response schema is documented in the OpenAPI spec. The default Dropwizard/JTier error format applies.

### Pagination

> Not applicable — cart data is scoped per user and not paginated.

## Rate Limits

> No rate limiting configured at the service level. Rate limiting is handled by the upstream GAPI/Lazlo gateway.

## Versioning

URL path versioning is used. All endpoints are under `/api/v2/`. The current API version is `v2`.

## OpenAPI / Schema References

- OpenAPI 2.0 (Swagger) specification: `doc/swagger/swagger.yaml`
- JSON format: `doc/swagger/swagger.json`
- Service discovery resource manifest: `doc/service_discovery/resources.json`
