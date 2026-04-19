---
service: "deckard"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service]
---

# API Surface

## Overview

Deckard exposes a single REST HTTP endpoint consumed exclusively by `continuumApiLazloService` (API Lazlo). The API returns a paginated, filtered, and sorted list of inventory unit identifier pairs (`inventoryServiceId` + `unitId`) for a given consumer. It does not return decorated display data — that is handled downstream by API Lazlo. The service listens on port `8001` and uses a URL versioning strategy (`/v1/`).

## Endpoints

### Inventory Units

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/inventory_units` | Returns filtered, sorted, paginated inventory unit identifiers for a consumer | Internal service (no external auth) |
| `GET` | `/grpn/healthcheck` | Standard Groupon health check endpoint | None |

### GET /v1/inventory_units — Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `consumer_id` | string (UUID) | Yes | The consumer whose inventory units are requested (PII class 3) |
| `offset` | integer | Yes | Number of units to skip for pagination |
| `limit` | integer (max 100) | Yes | Maximum number of units to return |
| `sort` | string | No | Sort criteria in format `FIELD:asc\|desc[,FIELD:asc\|desc]`. Valid fields: `inventory_service_id`, `expires_at`, `purchased_at` |
| `filter` | string | No | Filter expression using the Deckard filter grammar (see below) |
| `lat` | number | No | Consumer latitude (for location-based features) |
| `lng` | number | No | Consumer longitude (for location-based features) |
| `partition` | string | No | Partition identifier for multi-partition queries |

### GET /v1/inventory_units — Response

```json
{
  "inventoryUnits": [
    { "inventoryServiceId": "getaways", "unitId": "<UUID>" }
  ],
  "pagination": {
    "count": 42,
    "offset": 0
  },
  "errors": {
    "inventoryServices": ["tpis"],
    "units": [],
    "giftedUnits": {
      "failureType": "none",
      "units": []
    },
    "merchantPartial": false
  }
}
```

## Request/Response Patterns

### Common headers

- Standard Groupon internal service headers forwarded by the Lazlo framework (`gHeadersRequestFilter`)
- Locale filtering applied via `lazloLocaleFilter`

### Error format

Partial results are supported: if one or more inventory services fail to respond, the service returns a best-effort list with failed services listed in `errors.inventoryServices`. A `merchantPartial` flag indicates whether merchant-level filtering may be incomplete. Full failure of all inventory services results in an empty `inventoryUnits` array.

### Pagination

Offset-based pagination. Clients supply `offset` (skip count) and `limit` (page size, maximum 100). The response includes `pagination.count` (total matching units) and `pagination.offset` (current offset). The internal maximum before pagination is applied is 500 units (configured in `config/pagination.json`).

## Filter Grammar

Deckard accepts a structured filter expression with the following grammar:

```
filter : disj
disj   : conj ('OR' conj)*
conj   : term ('AND' term)*
term   : NOT assertion | assertion
assertion : field | field 'EQUALS' value
```

**Boolean-domain filter fields** (shorthand `field` implies `field EQUALS true`):

| Field | Meaning |
|-------|---------|
| `available` | Not redeemed and not expired |
| `redeemed` | Merchant-redeemed or recipient-redeemed |
| `expired` | Past `expiresAt` and not redeemed |
| `gifted_to` | Unit was received as a gift |
| `gifted_by` | Unit was sent as a gift |
| `retained_value` | Unit has retained value |
| `refunded` | Unit was refunded (fulfillment reversed) |

**String-domain filter field**:

| Field | Values |
|-------|--------|
| `inventory_service` | `getaways`, `mrgetaways`, `glive`, `goods`, `clo`, `vis`, `tpis` |

> Note: `inventory_service` supports only a single value per filter expression; OR-combined values do not match any units.

## Rate Limits

> No rate limiting configured. The service is protected by internal network controls and Lazlo's per-client connection pool limits (`maxPoolSize`, `maxWaitQueueSize`). SLA: 99.9% availability at 250 rps peak with a 6-second timeout.

## Versioning

URL path versioning: all endpoints are prefixed with `/v1/`. The Swagger/OpenAPI spec is at `doc/swagger/swagger.json`.

## OpenAPI / Schema References

- Swagger 2.0 specification: `doc/swagger/swagger.json`
- Service discovery resources: `doc/service_discovery/resources.json`
- Service Portal: `https://services.groupondev.com/services/deckard`
