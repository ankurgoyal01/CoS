---
service: "coupons-ui"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, http]
auth_mechanisms: [none, api-key]
---

# API Surface

## Overview

Coupons UI exposes a small set of HTTP endpoints via the Astro Node.js server (port 3000), fronted by nginx (port 8080). The primary surface is server-rendered HTML pages for coupon discovery. Two JSON API routes handle client-side redemption and redirect lookups at runtime, called from the browser by the Redemption Orchestrator Svelte component. A healthcheck route supports infrastructure probing. All routes are server-rendered (not pre-rendered) and return appropriate cache-control headers.

## Endpoints

### Page Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/coupons-ui/{country}/{merchant-permalink}` | Renders SSR merchant coupon page with active and expired offers | None |

> The base path is `/coupons-ui/` (configured in `astro.config.mjs`). nginx rewrites `/coupons/*` to `/coupons-ui/*` before proxying to Node.js.

### API Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/redemption/{offerId}` | Fetches redemption data for an offer from VoucherCloud API | None (API key forwarded server-side) |
| GET | `/api/redirect/{offerId}` | Fetches affiliate redirect URL for an offer from VoucherCloud API | None (API key forwarded server-side) |

### Operations Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Infrastructure health probe; responds `200 OK` with body `OK` | None |

## Request/Response Patterns

### Redemption endpoint query parameters

The `/api/redemption/{offerId}` route accepts the following query parameters:

| Parameter | Purpose |
|-----------|---------|
| `clientId` | Forwarded as `X-TrackingToken` to VoucherCloud API |
| `merchantName` | Logged and forwarded as context |
| `linkType` | Forwarded as `X-BloodhoundSource` to VoucherCloud API |
| `gclid` | Google Click ID; when present, sets `AffiliateLinkRequired=true` |

The `b` cookie value is read from the request and forwarded as `X-BloodhoundBCookie`.

### Common response headers

All responses include:
- `X-Request-Id`: UUID generated per request by the Request Context Factory
- `Cache-Control: no-store, no-cache, must-revalidate, private` (set by runtime middleware on all responses)

Static assets served by nginx carry:
- `Cache-Control: public, immutable` with a 1-year `Expires` header

### Error format

JSON API routes return structured error objects:

```json
{ "error": "Offer ID is required" }
{ "error": "Invalid offer ID" }
{ "error": "VoucherCloud API not available" }
{ "error": "Failed to retrieve redemption data" }
```

HTTP status codes used: `200`, `400`, `500`.

### Pagination

> Not applicable. API routes return single-object responses. Page content is fully rendered server-side.

## Rate Limits

> No rate limiting configured at the application layer. Upstream nginx does not apply rate limits in the committed configuration.

## Versioning

No explicit API versioning strategy. Routes are identified by path only; no version prefix or header versioning is applied.

## OpenAPI / Schema References

An OpenAPI schema path is declared in `.service.yml` at `doc/schema.yml`, but no schema file was found in the repository at time of documentation generation.
