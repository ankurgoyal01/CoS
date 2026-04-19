---
service: "pricing-control-center-ui"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest", "html"]
auth_mechanisms: ["cookie-token"]
---

# API Surface

## Overview

The service exposes an internal HTTP interface consumed by browser clients (internal operators) and, for data routes, by in-page JavaScript fetch calls. All routes require a valid `authn_token` cookie issued by Doorman SSO — routes guard against missing or empty tokens by redirecting to `/doorman`. Page routes return `text/html`; data endpoints return `application/json` or `text/csv`. The OpenAPI spec is located at `doc/openapi.yml`.

Production base URL: `https://pricing-control-center-ui.production.service`
Staging base URL: `https://pricing-control-center-ui.staging.service`
Public DNS (production): `https://control-center.groupondev.com`
Public DNS (staging): `https://control-center--staging.groupondev.com`

## Endpoints

### Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/doorman` | Initiates Doorman SSO redirect for authentication | None (public entry point) |
| POST | `/post-user-auth-token` | Receives Doorman auth token callback; writes `authn_token` cookie; redirects to home | None (CSRF exempt — listed in `ignoredPaths`) |

### Home

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Renders the home page dashboard | `authn_token` cookie |
| GET | `/v1.0/identity` | Fetches user identity (email, firstName, lastName, role, channels) from jtier; writes `user` cookie | `authn_token` cookie |

### Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/search-box-jtier` | Renders the product search input page | `authn_token` cookie, `user` cookie |
| GET | `/search-result` | Renders search result page for a given `inventory_product_id` query parameter | `authn_token` cookie, `user` cookie |

### Sales — Manual (ILS Upload)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/manual-sale-new` | Renders the manual sale creation / CSV upload page | `authn_token` cookie, `user` cookie |
| POST | `/manual-sale-post/upload-proxy` | Proxies multipart CSV upload to jtier `/ils_upload` endpoint | `authn_token` cookie |

### Sales — Custom

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/custom-sale-new` | Renders the custom sale creation form | `authn_token` cookie, `user` cookie |
| POST | `/custom-sale-post` | Submits new custom sale (`saleName`, `startDate`, `endDate`, `startTimezone`, `endTimezone`) to jtier `/custom-sales` | `authn_token` cookie |

### Sale Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/sale-uploader` | Renders the sale list / uploader page | `authn_token` cookie, `user` cookie |
| GET | `/sale-uploader-show` | Renders the sale detail view for a given `sale_id` query parameter | `authn_token` cookie, `user` cookie |
| GET | `/sale-csv-download` | Streams CSV download of original sale data for a given `sale_id` | `authn_token` cookie |

### Error

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/error` | Renders the error page; accepts optional `errorCode` query parameter | None |

## Request/Response Patterns

### Common headers

- `authn-token`: Doorman-issued token forwarded in all downstream calls to `pricing-control-center-jtier`. Set as a cookie on the browser client (`authn_token`), extracted server-side, and forwarded as the `authn-token` request header.
- `user`: JSON-serialised user object cookie containing `email`, `firstName`, `lastName`, `role`, and `channels` fields. Set for 6-hour sessions.

### Error format

Errors are surfaced via a redirect to `/error?errorCode=<code>` for page routes. Data routes return JSON error objects propagated from the downstream jtier client.

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL versioning strategy is applied at the UI layer. The single internal version of the API is reflected in `doc/openapi.yml` (version field: `9c73d06bf5b08321bc06818d2d4ded9b`).

## OpenAPI / Schema References

OpenAPI 3.0 specification: `doc/openapi.yml`
