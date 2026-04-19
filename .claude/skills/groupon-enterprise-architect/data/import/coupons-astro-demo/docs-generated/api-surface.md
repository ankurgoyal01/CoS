---
service: "coupons-astro-demo"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [http]
auth_mechanisms: []
---

# API Surface

## Overview

`coupons-astro-demo` serves HTML pages over HTTP. It is not a REST or GraphQL API — its "API surface" is its set of routable server-side rendered pages. Browser clients and search crawlers issue standard `GET` requests and receive fully rendered HTML. There are no JSON API endpoints, no authentication requirements, and no machine-readable contracts exposed to other services.

## Endpoints

### Page Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/` | Home page — landing page listing example merchant links | None |
| `GET` | `/coupons/[merchantPermalink]` | Merchant coupons page — SSR page with offers, adverts, sidebar data for the given merchant permalink | None |

### Implicit Platform Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/404` | Not-found redirect target — the coupons route handler redirects here when a merchant permalink resolves to no data in Redis | None |

> The application listens on port `4321` (container-internal) and is mapped to port `8080` on the Kubernetes service (`httpPort: 8080` in `.meta/deployment/cloud/components/app/common.yml`). An admin port `8081` is also declared.

## Request/Response Patterns

### Common headers

- Standard HTTP browser headers (`Accept`, `User-Agent`, `Accept-Language`) are forwarded through the Node.js adapter.
- No custom request headers are required by the application.

### Error format

- A missing merchant (Redis cache miss) results in an HTTP redirect to `/404` via `Astro.redirect('/404')`.
- No structured JSON error body is produced; this is an HTML application.

### Pagination

> Not applicable — offer listings are returned in full from Redis and rendered server-side without pagination.

## Rate Limits

> No rate limiting configured in the application layer. Rate limiting, if any, is expected to be applied at the load balancer or ingress level outside this service.

## Versioning

No URL-level API versioning strategy is applied. Cache key versioning is used internally on Redis keys (e.g., suffix `:v4`, `:v3`) to allow cache format migrations without breaking running instances.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema are present in this repository.
