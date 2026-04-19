---
service: "alligator"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: []
---

# API Surface

## Overview

Alligator exposes a REST HTTP API on port 8080. Consumers pass deck or card identification parameters (deck UUID, client UUID, card permalink) along with request context (locale, geo coordinates, platform, user identifiers) and receive assembled, decorated card payloads. Three versioned controller families exist: an unversioned Cardatron controller, a V2 controller adding real-time single-card decoration, and a V5 controller adding deck configuration with experiment bucketing. There is no authentication enforced at the API layer; callers are expected to operate within the internal network.

## Endpoints

### Cardatron Controller (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cardatron/cards` | Retrieve all cards on a deck for a given deck UUID or card permalink | None |

### Cardatron V2 Controller

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/cardatron/cards/decorate` | Real-time decoration of a single card against its template | None |

### Cardatron V5 Controller

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v5/cardatron/cards/deckconfig` | Return the set of possible card configurations for a deck given deck UUID, brand, locale, and user UUID | None |
| GET | `/v5/cardatron/cards/decorate` | Real-time decoration of a single card (V5 variant; adds `platform` parameter) | None |

### Cache / Debug / Operations Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cache/cachevalues` | Print all values in a named in-memory cache (`cardDecks`, `cards`, `templates`, `clients`, `polygons`, `permalinks`) | None |
| GET | `/debug/card/{uuid}` | Combined response: Alligator cache state and live Cardatron response for a card UUID | None |
| GET | `/debug/card/{uuid}/alligator` | Current state of a deal in the Alligator Redis cache | None |
| GET | `/debug/card/{uuid}/cardatron` | Live response from Cardatron for a card UUID | None |
| GET | `/heartbeat` | Liveness and readiness probe endpoint | None |
| GET | `/status.json` | Service status endpoint (used by service discovery on port 8080) | None |

## Request/Response Patterns

### Common headers

| Header | Description | Required |
|--------|-------------|----------|
| `x-brand` | Brand identifier (e.g., `groupon`, `livingsocial`). Takes precedence over the `brand` query parameter. | Required on V2 and V5; optional on V1 |

### Common query parameters (card retrieval)

| Parameter | Description | Required |
|-----------|-------------|----------|
| `deck_id` | Desired deck UUID | Conditional |
| `deck_client_id` | Client UUID matching the deck or permalink | Conditional |
| `card_permalink` | Unique link identifying which deck to serve; dependent on `deck_client_id` and brand | Conditional |
| `locale` | Country-language code, e.g., `en_US` | Required on V2 and V5 |
| `country` | Country code, e.g., `US` | No |
| `platform` | Platform identifier, e.g., `mobile`, `web`, `iphonecon`, `touch` | No (V1/V2); No (V5 deckconfig, but used to resolve `deck_client_id`) |
| `cll` | Calculated latitude/longitude | No |
| `ell` | Expressed latitude/longitude | No |
| `consumer_id` | Signed-in user UUID (c cookie) | No |
| `visitor_id` | Visiting user UUID (b cookie) | No (V1/V2); Required (V5 deckconfig) |
| `current_deal` | UUID of the deal currently being viewed | No |
| `current_item` | Item reference, format `deals:<UUID>` | No |
| `query` | User-input search query | No |
| `division` | Valid geographic division | No |
| `place_id` | UUID for a place (currently unused) | No |
| `client_version_id` | Client version override; parsed to first minor version (e.g., `10.1.2` becomes `10.1`) | No |
| `variants` | Experiment variant bucket override string | No |
| `schedule_override` | Overrides current date/time to return scheduled cards (V1 only) | No |
| `secure_assets` | Whether to return HTTPS asset URLs; defaults to `true` | No |
| `filterByLocation` | Filter response cards by card geo location (V5 deckconfig only) | No |
| `activeOnly` | Return only cards in the active window or scheduled for today (V5 deckconfig only) | No |
| `debug_mode` | Enable debug info in response; do not use in production or automated queries | No |
| `offset` | Pagination offset (V1 only) | No |
| `limit` | Pagination limit (V1 only) | No |
| `brand` | Brand identifier, e.g., `groupon`, `livingsocial`; overridden by `x-brand` header | No |

### Error format

Standard Spring MVC error responses. HTTP status codes used:

| Code | Meaning |
|------|---------|
| `200` | Success |
| `401` | Unauthorized |
| `403` | Forbidden |
| `404` | Not Found (deck or card not found in cache or upstream) |
| `406` | Invalid parameters (V2 and V5 endpoints) |
| `500` | Internal server error (V2 and V5 endpoints) |

### Pagination

The V1 `/cardatron/cards` endpoint supports `offset` and `limit` query parameters. The response body includes a `PaginationDTO` object with `count` and `offset` fields, and a top-level `total` integer indicating total available cards.

## Rate Limits

> No rate limiting configured.

## Versioning

URL path versioning strategy:
- `/cardatron/cards` — v1 (unversioned path)
- `/v2/cardatron/cards/...` — V2 endpoints
- `/v5/cardatron/cards/...` — V5 endpoints

The `client_version_id` query parameter additionally allows overriding deck template selection to a specific client version.

## OpenAPI / Schema References

OpenAPI 3.0.3 specification is generated at build time via `mvn -DskipDocker verify` and written to:
- `doc/swagger/openapi.yaml`
- `doc/swagger/openapi.json`

The spec path is also declared in `.service.yml` as `open_api_schema_path: doc/swagger/openapi.yaml`.
