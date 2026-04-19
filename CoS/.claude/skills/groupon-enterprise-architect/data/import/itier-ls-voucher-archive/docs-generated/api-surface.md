---
service: "itier-ls-voucher-archive"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest, http]
auth_mechanisms: [session, csrf]
---

# API Surface

## Overview

itier-ls-voucher-archive exposes HTTP routes under the `/ls_voucher_archive/` path prefix serving three consumer audiences: end-users viewing vouchers, CSR agents performing service operations, and merchants searching and exporting voucher data. All routes are server-rendered via Preact and Express. CSRF protection is applied to mutating CSR and merchant routes via `csurf`. User identity is established by `itier-user-auth` session middleware.

## Endpoints

### Consumer Voucher Views

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ls_voucher_archive/:voucherId` | Render voucher detail page for a consumer | Session (itier-user-auth) |
| GET | `/ls_voucher_archive/:voucherId/print` | Render printable PDF voucher view | Session (itier-user-auth) |

### CSR Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ls_voucher_archive/csrs/:voucherId` | Render CSR voucher detail view | Session (itier-user-auth) |
| POST | `/ls_voucher_archive/csrs/:voucherId/refund` | Submit refund request for a voucher | Session + CSRF token (csurf) |

### Merchant Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ls_voucher_archive/merchants/search` | Render merchant voucher search page | Session (itier-user-auth) |
| POST | `/ls_voucher_archive/merchants/search` | Execute voucher search and render results | Session + CSRF token (csurf) |
| GET | `/ls_voucher_archive/merchants/export` | Export voucher search results as CSV | Session (itier-user-auth) |

## Request/Response Patterns

### Common headers

- `Cookie`: Session cookie consumed by `itier-user-auth` for identity
- `X-CSRF-Token`: Required for CSR refund and merchant search POST routes; validated by `csurf`
- `Accept-Language`: Used for locale/localization selection

### Error format

Server-rendered error pages are returned for 4xx and 5xx conditions. Specific error shape is determined by the `itier-server` error handler. JSON error responses are not the primary pattern — this is a server-rendered web application.

### Pagination

Merchant voucher search results use page-based pagination; page parameters are passed as query strings on GET requests.

## Rate Limits

No rate limiting configured at the application layer. Rate limiting may be applied upstream by Akamai CDN or the API Proxy.

## Versioning

No API versioning strategy. Route paths are fixed under `/ls_voucher_archive/`. This service does not expose a versioned API — it is a server-rendered web application.

## OpenAPI / Schema References

No OpenAPI spec, proto files, or GraphQL schema found. This service renders HTML views and does not expose a machine-readable API contract.
