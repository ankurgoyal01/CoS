---
service: "travel-browse"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, cookie]
---

# API Surface

## Overview

travel-browse exposes HTTP endpoints that serve Getaways browse, hotel detail, search results, and SEO landing page content. All endpoints are rendered server-side and return HTML for browser consumption. Routes are defined via `itier-routing` on top of Express and dispatched through the `requestRouting` component of `continuumGetawaysBrowseWebApp`.

## Endpoints

### Getaways Browse Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/travel/:geo_slug/hotels` | Renders the Getaways hotel browse page for a given geographic location | Session (cookie) |

### Hotel Detail and Inventory

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/hotels/:dealId/inventory` | Returns market-rate hotel inventory and availability for a specific deal | Session (cookie) |

### Search Results

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/travel/search` | Renders Getaways search results page for a given search query and geo context | Session (cookie) |

### SEO Landing Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/getaways/:seo_slug` | Renders SEO-optimized Getaways landing pages with LPAPI content and deal listings | None (public) |

## Request/Response Patterns

### Common headers

- `Accept-Language` — used for i18n locale resolution
- `Cookie` — carries session context consumed by `userAuthService` and `subscriptionsApi`
- `User-Agent` — influences CDN caching behaviour and device-type rendering

### Error format

> No standardised error response schema is evidenced in the architecture model. Error handling follows standard Express middleware patterns; HTTP 4xx/5xx responses return HTML error pages for browser requests.

### Pagination

> Not applicable at this endpoint layer — browse and search pages use cursor-based or offset pagination controlled by upstream RAPI query parameters.

## Rate Limits

> No rate limiting configured at the application layer. Rate limiting is enforced upstream at the CDN/load-balancer edge.

## Versioning

URL path versioning is not used. The service is accessed through route prefixes determined by the Continuum routing layer. There is no explicit API version header or query-parameter versioning scheme.

## OpenAPI / Schema References

> No evidence found. No OpenAPI spec, proto files, or GraphQL schema are present in the repository. Endpoint contracts are defined implicitly through itier-routing route declarations.
