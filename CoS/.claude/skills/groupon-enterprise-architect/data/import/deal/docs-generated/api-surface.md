---
service: "deal"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

The deal service exposes HTTP endpoints consumed by browsers, mobile clients, and the Akamai CDN. The primary endpoint renders the full deal detail page as server-side HTML. Static assets are served from a dedicated assets path. Internal AJAX interactions (e.g., wishlist mutations, buy button state) are handled via a namespaced POST API path. All endpoints operate under the `/deals` path prefix.

## Endpoints

### Deal Page Rendering

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals/:deal-permalink` | Renders the full deal detail page (SSR HTML) including prices, merchant info, availability, and booking UI | Session (consumer-facing) |
| GET | `/deals/assets/:file` | Serves Webpack-bundled static assets (JS, CSS, images) for the deal page | None (public static) |

### Internal AJAX API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/deals/api/*` | Internal AJAX endpoint namespace for deal page interactions (e.g., wishlist add/remove, dynamic data refresh) | Session (consumer-facing) |

### Wishlist Page

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals/wishlist` | Renders the consumer wishlist page (controller: wishlist_page) | Session (consumer-facing) |

### AMP Variant

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals/:deal-permalink/amp` | Renders the AMP (Accelerated Mobile Pages) variant of the deal page | None (public) |

## Request/Response Patterns

### Common headers

- `Accept-Language` — used for locale/region resolution
- `User-Agent` — used for device-type detection (mobile vs. desktop rendering path)
- `Cookie` — carries consumer session for auth and personalization
- `X-Forwarded-For` — passed by Akamai/load balancer for geo-routing

### Error format

> No evidence found in codebase. Error responses follow standard itier-server conventions; HTTP 4xx/5xx status codes with HTML error pages for browser clients.

### Pagination

> Not applicable. The deal page renders a single deal per request; no paginated endpoints.

## Rate Limits

> No rate limiting configured at the application layer. Rate limiting is handled upstream by the Akamai CDN and load balancer layer.

## Versioning

The deal page API does not use explicit API versioning. The endpoint path is stable (`/deals/:deal-permalink`). The internal AJAX namespace (`/deals/api/*`) uses sub-paths for individual operations but no version prefix.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema published from this service repository.
