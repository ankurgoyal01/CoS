---
service: "wishlist-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [consumer-id-query-param, bcookie, client-id-query-param]
---

# API Surface

## Overview

The Wishlist Service exposes a RESTful JSON API under the `/wishlists/v1/` path prefix. All endpoints identify the requesting user via the `consumerId` query parameter (UUID format). The API is consumed by GAPI-facing front-end apps (iTier wishlist app, deal page, layout service) and mobile apps. Callers may optionally provide an `X-Request-Id` header for tracing and a `clientId` parameter for client identification. The OpenAPI 2.0 spec lives at `doc/swagger/swagger.yaml`.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/heartbeat.txt` | Liveness heartbeat check | None |
| GET | `/grpn/status` | Service status and SHA check | None |

### Wishlist Lists

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wishlists/v1/lists` | Retrieve all wishlist lists for a given `consumerId`; supports pagination, sort, and deal/option filters | consumerId (required) |
| POST | `/wishlists/v1/lists` | Add a new item to a list identified by `listName` for a given `consumerId`; creates list if not present | consumerId (required) |
| GET | `/wishlists/v1/lists/find` | Find lists for a user containing a specific deal or option, with optional purchased/gifted filters | consumerId (optional) |
| GET | `/wishlists/v1/lists/query` | Retrieve a specific list by `listName` for a given `consumerId`; supports pagination, filters, channel, sort | consumerId (required) |
| GET | `/wishlists/v1/lists/{listId}` | Retrieve a specific list by `listId` for a given `consumerId`; supports pagination, channel, sort, filters | consumerId (required) |
| POST | `/wishlists/v1/lists/{listId}` | Add a new item to a list by `listId` for a given `consumerId` | consumerId (required) |
| DELETE | `/wishlists/v1/lists/{listId}/items` | Delete one or more items from a list by `listId`; item IDs provided in the request body | consumerId (optional) |

## Request/Response Patterns

### Common headers

- `X-Request-Id` (optional): Correlation ID for distributed tracing, accepted on all wishlist endpoints.

### Common query parameters

- `consumerId` (UUID, required on most endpoints): Identifies the user whose wishlist is being accessed.
- `bcookie` (string, optional): Last-seen browser cookie for user identification fallback.
- `clientId` (string, optional): Identifies the calling client for auditing.
- `locale` (string, optional): Locale context for list operations.

### Filtering parameters (on list read endpoints)

- `containsDeal` (UUID): Filter lists/items to those containing a specific deal.
- `containsOption` (UUID): Filter lists/items to those containing a specific deal option.
- `channel` (UUID): Filter items by channel ID.
- `purchased` (boolean): Filter to items marked as purchased.
- `gifted` (boolean): Filter to items marked as gifted.
- `fromDate` (string): Lower bound on item creation date.
- `sort` (string): Sort expression for ordering items.

### Add item request body

```json
{
  "dealId": "<uuid>",
  "optionId": "<uuid>"
}
```

### Delete items request body

```json
{
  "itemIds": ["<uuid>", "<uuid>"]
}
```

### Error format

> No standardized error response schema is documented in `doc/swagger/swagger.yaml`. Errors return HTTP status codes with Dropwizard default error bodies.

### Pagination

List retrieval endpoints (`GET /wishlists/v1/lists`, `GET /wishlists/v1/lists/{listId}`, `GET /wishlists/v1/lists/query`) support offset-based pagination via:

- `offset` (integer): Zero-based offset into the result set. Default: 0.
- `limit` (integer): Maximum number of items to return. Default page size: 100 (configured via `serviceConfig.maxItems`).

Responses include a `pagination` object with fields: `count`, `offset`, `total`.

## Rate Limits

> No rate limiting is configured at the service level. Rate control is enforced upstream by GAPI, which discards responses exceeding 40ms.

## Versioning

All wishlist endpoints are versioned under the `/wishlists/v1/` URL path prefix.

## OpenAPI / Schema References

OpenAPI 2.0 specification: `doc/swagger/swagger.yaml`
