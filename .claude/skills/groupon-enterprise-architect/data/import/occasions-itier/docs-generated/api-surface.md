---
service: "occasions-itier"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, cookie]
---

# API Surface

## Overview

occasions-itier exposes an HTTP interface consumed primarily by browser clients navigating Groupon's occasion-based deal pages. The API serves both full-page HTML responses for initial navigation and JSON fragments for AJAX-based deal pagination and card loading. Administrative cache control endpoints are also exposed for operator use.

## Endpoints

### Occasion Browsing Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/occasions` | Renders the main occasions landing page listing available occasion categories | Optional (itier-user-auth) |
| GET | `/occasion/:occasion` | Renders a single occasion deal browsing page for the given occasion slug | Optional (itier-user-auth) |
| GET | `/collection/:occasion` | Renders a curated collection page for the given occasion slug | Optional (itier-user-auth) |
| GET | `/:permalink_base` | Resolves and renders an occasion page via permalink slug | Optional (itier-user-auth) |

### Deal Pagination (AJAX)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/occasion/:occasion/deals/start/:offset` | Returns the next page of deal cards for an occasion starting at `offset` | Optional (itier-user-auth) |
| GET | `/occasion/deals-json` | Returns deal JSON for client-side rendering | Optional (itier-user-auth) |

### Embedded Cards

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/occasion/embedded-cards-loader` | Returns pre-rendered HTML card markup for lazy embedding | Optional (itier-user-auth) |

### Cache Control (Operator)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cachecontrol` | Displays current cache state and available controls | Operator / internal |
| POST | `/cachecontrol` | Triggers manual cache invalidation for campaign/deal data | Operator / internal |

## Request/Response Patterns

### Common headers
- `Accept-Language` — used by itier-divisions to determine locale/division
- `X-Forwarded-For` / `X-Real-IP` — used for geo-resolution via GeoDetails API
- Standard session cookies managed by `itier-user-auth`

### Error format
> No evidence found in codebase. I-Tier framework typically returns HTTP status codes with HTML error pages for browser-facing routes and JSON error objects for AJAX routes.

### Pagination
Deal pagination uses a URL-segment offset pattern: `/occasion/:occasion/deals/start/:offset` where `:offset` is a zero-based integer indicating the starting deal index within the current occasion's result set.

## Rate Limits

> No rate limiting configured.

## Versioning

No explicit API versioning. Routes are path-based with no version prefix. The service is consumed directly by browser navigation and AJAX calls; clients do not negotiate a version.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema detected in the service inventory.
