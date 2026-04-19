---
service: "mvrt"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, http]
auth_mechanisms: [okta, session]
---

# API Surface

## Overview

MVRT exposes an internal HTTP API consumed exclusively by its own browser-based frontend (Backbone.js SPA). All endpoints are served under the application root and require Okta authentication via the `itier-user-auth` middleware. The API is not a public or partner-facing interface — it is an internal tool API for EMEA merchant operations staff. There is no versioning strategy; the service is a monolithic ITier application.

## Endpoints

### Search and Redemption

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/` | Renders main search page (SPA shell); injects config and user context | Okta session |
| `POST` | `/bulkSearch` | Batch search vouchers by code type (customer code, security code, unit ID, SF ID, etc.); returns JSON results | Okta session |
| `POST` | `/unitSearch` | Search voucher units by a given code type; returns JSON results | Okta session |
| `POST` | `/redeemVouchers` | Redeems a batch of selected vouchers (normal or forced redemption); returns JSON redemption results | Okta session |
| `GET` | `/error` | Renders error page with message from query parameter | Okta session |

### Offline Export

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/createCodesList` | Uploads a paginated batch of codes to AWS S3 for offline processing staging | Okta session |
| `POST` | `/createJsonFile` | Finalises the offline job JSON request file (pulls codes from S3, writes local JSON); enqueues for background processing | Okta session |
| `GET` | `/downloadFile` | Downloads a completed offline report (XLSX or CSV) by filename from AWS S3 | Okta session |

### Assets

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/mvrt/assets/*` | Static assets (JS bundles, CSS, images) served by ITier | None |
| `GET` | `/mvrt/js/*` | Generated JavaScript bundles | None |
| `GET` | `<locale.js url>` | ITier i18n locale bundle | None |

## Request/Response Patterns

### Common headers

- Standard browser session cookies managed by `cookie-parser` and `itier-user-auth`
- CSRF protection via `csurf` middleware on all state-mutating POST endpoints
- Okta user context injected on each request as `req.oktaUser` (contains `email`, `username`, `firstName`, `lastName`, `groups`)

### Error format

JSON error responses follow the standard ITier/keldor error envelope. HTTP 500 redirects to `/error?message=<description>` for browser flows. JSON API consumers receive an error object with `message` and optional `description` fields from the upstream service.

### Pagination

Bulk search operations process codes in configurable chunk sizes defined in feature flags:
- `chunk_size.search.customer_code`: 25 per chunk
- `chunk_size.search.security_code`: 25 per chunk
- `chunk_size.search.unit_id`: 25 per chunk
- `chunk_size.search.merchant_id`: 1 per chunk
- `chunk_size.search.sf_id`: 1 per chunk
- `chunk_size.search.product_sf_id`: 1 per chunk
- `chunk_size.searchLimit`: 300,000 max codes for offline search
- Redemption chunk size: 15 per batch

## Rate Limits

> No rate limiting configured. MVRT is an internal tool with bounded user populations; rate control relies on upstream service capacity limits.

## Versioning

No URL or header versioning. Single version of the API is served. Changes are deployed via the standard ITier pipeline.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema present. The `@grpn/swagger-ui` devDependency is present but no spec file was found in the repository.
