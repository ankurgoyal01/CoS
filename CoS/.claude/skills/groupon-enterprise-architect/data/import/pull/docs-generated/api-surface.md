---
service: "pull"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, cookie]
---

# API Surface

## Overview

Pull exposes a set of server-rendered HTTP GET endpoints that return fully composed HTML pages for Groupon consumer discovery experiences. Each endpoint receives a browser or mobile web request, orchestrates data from upstream services, and responds with an HTML document plus client-side hydration data. Pull is a consumer-facing SSR service, not a machine-to-machine API — responses are HTML, not JSON.

## Endpoints

### Discovery Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Homepage — renders personalized deal cards and featured content | Optional (session cookie) |
| GET | `/browse` | Browse — renders category and deal listing pages | Optional (session cookie) |
| GET | `/search` | Search — renders keyword search results with facets | Optional (session cookie) |
| GET | `/local` | Local — renders geographically scoped deal listing pages | Optional (session cookie) |
| GET | `/goods` | Goods — renders physical goods listing pages | Optional (session cookie) |
| GET | `/gifting` | Gifting — renders gifting-focused deal listing pages | Optional (session cookie) |

## Request/Response Patterns

### Common headers

- `Cookie` — carries session token for signed-in user context (wishlist, personalization)
- `Accept-Language` — locale resolution for division and content targeting
- `X-Forwarded-For` / `X-Real-IP` — geographic location resolution via GeoPlaces
- `User-Agent` — desktop vs. touch variant selection

### Error format

Pull is an SSR application. On upstream dependency failure, the service renders a degraded or error page HTML response rather than a structured JSON error body. HTTP 5xx status codes are returned for unrecoverable server-side errors.

### Pagination

Browse, search, and local pages support query parameter-based pagination. Specific parameter names are governed by the `itier-routing` and Relevance API conventions (e.g., `page`, `start`, `limit`). No cursor-based pagination is used.

## Rate Limits

> No rate limiting configured at the Pull application layer. Rate limiting is applied upstream by the I-Tier infrastructure and edge/CDN layer.

## Versioning

No versioning strategy is applied at the URL path level. Pull serves a single current version of each page. API contract evolution is managed via feature flags (`itier-feature-flags`) and Birdcage experiment configuration rather than URL versioning.

## OpenAPI / Schema References

> No evidence found. Pull does not expose a machine-readable API schema — it is an SSR HTML-rendering service. See [Integrations](integrations.md) for upstream API contracts Pull depends on.
