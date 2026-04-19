---
service: "coupons-itier-global"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

`coupons-itier-global` exposes REST endpoints for coupon browsing pages and affiliate redirect resolution. Page endpoints return server-side rendered HTML for consumer-facing coupon discovery. Redirect endpoints resolve merchant and offer URLs and issue HTTP redirects to affiliate destinations. A GraphQL explorer endpoint is available for development introspection.

## Endpoints

### Redirect Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/redirect/merchant/{id}` | Resolves and redirects to a merchant affiliate URL | None (public) |
| GET | `/redirect/offers/{id}` | Resolves and redirects to a specific coupon offer affiliate URL | None (public) |

### Page Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/coupons` | Renders the main coupons discovery landing page | None (public) |
| GET | `/category/{category}` | Renders a coupons listing page filtered by category | None (public) |

### Development Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/graphiql` | GraphQL explorer for GAPI introspection | Development only |

## Request/Response Patterns

### Common headers

- `Accept-Language` — used to determine the country/locale for coupon content delivery across 11 supported countries
- `User-Agent` — passed through to downstream data sources where applicable

### Error format

> No evidence found in the architecture model. Standard I-Tier error responses are expected (HTTP status codes with HTML error pages for page routes).

### Pagination

> No evidence found. Category and listing pages are expected to use page-based navigation consistent with the I-Tier platform pattern.

## Rate Limits

> No rate limiting configured. Rate limiting is handled upstream by Akamai CDN.

## Versioning

No explicit API versioning. Routes are unversioned path-based endpoints managed within the I-Tier platform routing layer.

## OpenAPI / Schema References

> No OpenAPI spec or GraphQL schema files identified in the architecture inventory. GAPI schema is owned by the `@grpn/graphql-gapi` library.
