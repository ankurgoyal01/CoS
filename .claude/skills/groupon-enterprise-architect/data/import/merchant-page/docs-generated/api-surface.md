---
service: "merchant-page"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, mtls]
---

# API Surface

## Overview

The merchant-page service exposes four HTTP GET endpoints. The primary endpoint (`/biz/{citySlug}/{merchantSlug}`) returns a complete server-rendered HTML page for merchant discovery. Three secondary endpoints serve AJAX fragments consumed by the hydrated browser client: deal cards rendered as HTML, paginated UGC reviews as JSON, and a signed map image redirect. All endpoints are accessed via the Hybrid Boundary under the base URLs `https://merchant-page.production.service` (production) and `https://merchant-page.staging.service` (staging).

The service relies on mTLS (`useCommonMTLS: true`) for service-to-service authentication at the Hybrid Boundary layer. No API key or OAuth 2.0 authentication is applied to inbound requests from the public web.

## Endpoints

### Merchant Place Page

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/biz/{citySlug}/{merchantSlug}` | Renders the full server-side merchant place page HTML | None (public) |

**Path parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `citySlug` | Yes | URL-friendly city identifier (e.g., `chicago`) |
| `merchantSlug` | Yes | URL-friendly merchant identifier (e.g., `my-restaurant`) |

**Response:** `200 text/html` — full Preact-rendered HTML page including JSON-LD structured data, hydration payload, and remote layout chrome. Returns `302` redirect when a single deal proxy applies (`proxy_deal` flag). Returns `500` on upstream data failure.

### RAPI Deal Cards Fragment

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/merchant-page/rapi/{city}/{permalink}` | Fetches related deals from Relevance API and returns rendered card HTML | None (internal AJAX) |

**Path parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `city` | Yes | City slug for context |
| `permalink` | Yes | Merchant permalink for context |

**Query parameters:**

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `placeId` | Yes | string | Merchant place ID (used as exclusion filter) |
| `merchantName` | Yes | string | Merchant name for card title localisation |
| `categoryUrl` | Yes | string | Category URL for deal search filter |
| `titleKey` | Yes | string | i18n key for card section title |
| `lat` | Yes | number | Latitude for geo-filtered card search |
| `lon` | Yes | number | Longitude for geo-filtered card search |
| `lazyLoad` | No | boolean | Whether images should be lazy-loaded |
| `sort` | No | string | Sort order for returned deal cards |

**Response:** `200 application/json` — `{ html: "<rendered card html>" }` or `{}` with appropriate status code if no cards are found.

### Reviews Fragment

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/merchant-page/reviews` | Fetches paginated merchant review data from UGC service | None (internal AJAX) |

**Query parameters:**

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `merchantId` | No | string | Merchant identifier for review lookup |
| `offset` | No | number | Pagination offset |
| `limit` | No | number | Number of reviews to return |
| `orderBy` | No | string | Review sort order |

**Response:** `200 application/json` — review data including related aspects.

### Map Image Signing

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/merchant-page/maps/image` | Generates a signed static map image URL and redirects to it | None (internal AJAX) |

**Query parameters:**

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `size` | Yes | string | Map dimensions (e.g., `320x200`) |
| `markers` | No | string | JSON-encoded array of map marker objects |
| `provider` | No | string | Map provider (`maptiler` default) |

**Response:** `302 redirect` to signed map tile URL via `gims`.

## Request/Response Patterns

### Common headers

- `X-Country`: Required for EMEA requests to identify the country context (set by the Routing Service or Hybrid Boundary).
- `Cookie`: Session cookie (`c` or `b`) is read client-side to supply `visitorId` to the RAPI deal card query.

### Error format

- HTML endpoints return a status code integer (`statusCode` field in the action response), which itier-server converts to the appropriate HTTP response (e.g., `404`, `500`).
- JSON endpoints return `{}` with the upstream status code when upstream services return no data.

### Pagination

The `/merchant-page/reviews` endpoint accepts `offset` and `limit` query parameters passed directly to the UGC service. No cursor-based pagination is implemented in this service.

## Rate Limits

> No rate limiting is configured within this service. Rate limiting is managed at the Hybrid Boundary and Routing Service layers.

## Versioning

No URL versioning strategy is applied. The API is unversioned; breaking changes are coordinated with consumers. The OpenAPI spec carries a content-hash version (`c538d5457d1e18b570322ad1dd7f79be`).

## OpenAPI / Schema References

- OpenAPI 3.0 specification: `doc/openapi.yml` (in the service repository)
- BAST conformance date: 7/20/2023
