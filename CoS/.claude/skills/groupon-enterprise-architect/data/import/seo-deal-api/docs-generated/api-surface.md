---
service: "seo-deal-api"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [mtls, api-key]
---

# API Surface

## Overview

SEO Deal API exposes a REST API under the `/seodeals/` path prefix, serving SEO deal data retrieval, attribute management, redirect management, URL removal workflows, and IndexNow submission. The primary consumers are `seo-admin-ui` (admin console), `seo-deal-redirect` (automated redirect pipeline), and `ingestion-jtier` (deal ingestion pipeline). Base URLs: `http://seo-deal-api.staging.service` (staging) and `http://seo-deal-api.production.service` (production). The full internal GCP URL is `https://seo-deal-api.production.service.us-central1.gcp.groupondev.com`.

## Endpoints

### Deal Data

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/seodeals/deals/{dealId}` | Retrieves SEO data for a deal by UUID | Internal |
| PUT | `/seodeals/deals/{dealId}/edits/canonical` | Updates the canonical URL for a deal | Internal (query: `brand`, `source`) |
| PUT | `/seodeals/deals/{dealId}/edits/attributes` | Updates SEO attributes for a deal | Internal (query: `source`) |
| PUT | `/seodeals/deals/{dealId}/edits/attributes/redirectUrl` | Sets or clears the redirect URL for a deal | Internal (query: `source`), mTLS for redirect pipeline |
| PUT | `/seodeals/deals/{dealId}/edits/noindex` | Disables SEO indexing for a deal | Internal |

### Redirect Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/seodeals/deals/expired-deals-redirect` | Bulk-updates redirect mappings for expired deals | Internal |
| GET | `/seodeals/redirects/processed` | Retrieves paginated processed redirect history | Internal (query: `startDate`, `endDate`, `page`, `pageSize`, `changedBy`, `redirectFrom`) |
| POST | `/seodeals/test-redirect` | Tests a redirect from a given URL to a target URL | Internal (body: `fromUrl`, `toUrl`) |
| POST | `/seodeals/cancel-redirect` | Cancels the redirect for a deal by permalink | Internal (body: `permalink`, `username`) |

### URL Removal

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/url-removal/request` | Creates URL removal requests | Internal (body: `user`, URLs) |
| GET | `/url-removal/search` | Searches URL removal requests | Internal (query: `limit`, `offset`, `requestedBy`, `status`) |
| POST | `/url-removal/approve` | Approves URL removal requests | Internal |
| POST | `/url-removal/reject` | Rejects URL removal requests | Internal |
| PATCH | `/url-removal/requests/{requestId}` | Updates status of a URL removal request | Internal (body: `requestStatus`, `observation`, `user`) |

### IndexNow

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/index-now/request` | Submits a list of URLs to IndexNow for indexing | Internal (body: `urls`) |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all POST/PUT/PATCH requests
- `Accept: application/json` — expected by all clients
- `Host: seo-deal-api.production.service` — set by the seo-deal-redirect pipeline

### Error format

Responses follow a consistent envelope pattern based on evidence from consumer code:
```json
{
  "error": true | false,
  "data": { ... },
  "msg": "human-readable error message"
}
```
HTTP status codes 400, 404, and 500 are returned for bad input, not-found, and server errors respectively.

### Pagination

The `/seodeals/redirects/processed` endpoint supports cursor-based pagination via `page` (page number, default 1) and `pageSize` (items per page, default 50) query parameters.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| `seo-deal-redirect` pipeline (production) | 1250 calls | 60 seconds |
| `seo-deal-redirect` pipeline (test/legacy) | 400 calls | 60 seconds |

> Rate limits above are enforced client-side by the `seo-deal-redirect` pipeline using the `ratelimit` Python library. No server-side rate limiting configuration was found in the available source evidence.

## Versioning

No URL path versioning is used. The API uses a flat `/seodeals/` prefix for deal endpoints without version segments. The `canonical` sub-resource at `continuumDealCatalogService` uses `/deal_catalog/v2/` versioning in that service's own API; the seo-deal-api does not version its own endpoints.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema were found in the seo-deal-api repository source. The `seo-admin-ui` repository contains a partial OpenAPI definition at `modules/seo-deals/open-api.js` documenting the admin UI proxy routes.
