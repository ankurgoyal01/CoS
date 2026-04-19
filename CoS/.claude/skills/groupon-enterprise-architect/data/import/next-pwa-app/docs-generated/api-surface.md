---
service: "next-pwa-app"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["graphql", "rest"]
auth_mechanisms: ["session", "jwt", "itier-user-auth"]
---

# API Surface

## Overview

The primary API surface of next-pwa-app is a GraphQL endpoint (`/api/graphql`) that serves both the web application and mobile clients. The GraphQL layer is built on Apollo Server, running as a Next.js API route. Additionally, the application exposes several REST-style Next.js API routes for specialized concerns such as proxying legacy endpoints, health checks, authentication callbacks, and metrics.

## Endpoints

### GraphQL API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/graphql` | Primary GraphQL endpoint for all data queries and mutations | Session / JWT (itier-user-auth) |

The GraphQL schema covers the full consumer commerce surface:

- **Queries**: deals, deal feeds, search, browse, homepage, categories, cart, orders, groupons, wishlists, user account, coupons, gifts, getaways, hotels, geo details, autocomplete, suggestions, reviews/UGC, landing pages, merchant pages, merchandising, sitemaps, in-app messages, wolfhound pages, membership, breakdown, barcodes, shipments, sponsored content, popular footer, config, experiments/features, geo-places, map data, reels, recently viewed
- **Mutations**: cart operations, order creation, user updates, wishlist management, gifting, consent, email subscriptions, feedback, push notification registration, recaptcha verification, JIRA form submission

### REST / Proxy API Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/grpn/healthcheck` | Health check endpoint | None |
| GET | `/api/grpn/helloworld` | Smoke test endpoint | None |
| GET | `/api/grpn/config` | Runtime configuration | None |
| GET | `/api/grpn/versions` | Version information | None |
| GET/POST | `/api/auth/*` | Authentication callbacks | Session |
| GET/POST | `/api/cart/*` | Cart API proxy | Session |
| GET/POST | `/api/proxy/*` | Legacy service proxies (checkout, deal, mygroupons, occasion, voucher, wolfhound) | Session |
| POST | `/api/v2/logs` | Client-side log ingestion | None |
| POST | `/api/v2/metric` | Client-side metric reporting | None |
| GET | `/api/maps/*` | Map tile proxy | None |
| GET | `/api/canRenderMyGroupon` | Feature availability check | Session |

### URL Rewrites (transparent to consumers)

| Source | Destination | Purpose |
|--------|-------------|---------|
| `/mobilenextapi/:path*` | `/api/:path*` | Mobile API compatibility |
| `/grpn/:path*` | `/api/grpn/:path*` | Internal API namespace |
| `/mystuff` | `/mygroupons` | Legacy URL support |
| `/checkout/cart/:path*` | `/checkout/cart` | Checkout URL normalization |

## Request/Response Patterns

### Common headers
- `x-grpn-nonce`: CSP nonce for security
- `x-forwarded-for`: Client IP propagation
- `sec-fetch-dest`: Used for conditional preconnect header injection
- Standard ITier headers propagated by `itier-client-platform`

### Error format
GraphQL errors follow the standard Apollo Server error shape:
```json
{
  "errors": [
    {
      "message": "...",
      "locations": [...],
      "path": [...],
      "extensions": { "code": "..." }
    }
  ]
}
```

### Pagination
Pagination patterns vary by resolver. Deal feeds and browse queries use cursor-based and offset-based pagination depending on the upstream data source (Relevance API uses offset, Booster uses cursors).

## Rate Limits

> No application-level rate limiting is configured within next-pwa-app. Rate limiting is handled upstream by Akamai CDN and the ITier service mesh.

## Versioning

The GraphQL API is unversioned -- schema evolution follows additive-only changes. Deprecated fields are marked with the `@deprecated` directive. REST proxy routes use path-based versioning where applicable (e.g., `/api/v2/`).

## OpenAPI / Schema References

- GraphQL schema sources: `libs/gql-server/src/resolvers/` (resolver modules), `libs/gql-server/src/datasources/` (data source implementations)
- Schema configuration: `graphql.config.yaml` at repository root
- Code generation configs: `codegen.ts`, `codegen-web.ts`, `codegen-mobile.ts`, `codegen-api.ts`, `codegen-core.ts`, `codegen-mobile-core.ts`
