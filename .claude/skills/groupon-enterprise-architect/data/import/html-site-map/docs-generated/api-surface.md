---
service: "html-site-map"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: ["mtls"]
---

# API Surface

## Overview

html-site-map exposes a synchronous HTTP API that returns server-rendered HTML pages. All three routes serve human-readable sitemap pages intended for consumption by end-users and web crawlers. The API is accessed via the Hybrid Boundary at `https://html-site-map.production.service` (production) and `https://html-site-map.staging.service` (staging). mTLS (`mtlsInterceptor: true`) is enforced at the Hybrid Boundary layer for service-to-service calls; public user traffic arrives via the Routing Service.

## Endpoints

### Sitemap Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/sitemap` | Returns the top-level HTML sitemap home page listing all states and regions | mTLS (HB) |
| GET | `/sitemap/{regionSlug}` | Returns the cities/divisions sitemap page for a given region (e.g. `/sitemap/california`) | mTLS (HB) |
| GET | `/sitemap/{regionSlug}/{citySlug}` | Returns the deal categories sitemap page for a given city (e.g. `/sitemap/california/los-angeles`) | mTLS (HB) |

### Path Parameters

| Parameter | Used In | Type | Description |
|-----------|---------|------|-------------|
| `regionSlug` | `/sitemap/{regionSlug}`, `/sitemap/{regionSlug}/{citySlug}` | string | URL-safe slug identifying a US state or geographic region (e.g. `california`) |
| `citySlug` | `/sitemap/{regionSlug}/{citySlug}` | string | URL-safe slug identifying a city or metro area (e.g. `los-angeles`) |

## Request/Response Patterns

### Common headers

- `Accept: text/html` — all routes return `text/html` responses
- Standard Groupon platform headers are forwarded by the Routing Service and Hybrid Boundary (locale, device type)

### Error format

- HTTP `404` — rendered as a custom HTML 404 page (`modules/error/views/404.js`) with top category links; triggered when LPAPI returns a non-200 status for an unknown region or city slug
- HTTP `503` — returned by the LPAPI client adapter (`handleResponse`) when LPAPI is unreachable
- HTTP `500` — default fallback when LPAPI returns an unexpected error without a status code

### Pagination

> Not applicable — each sitemap page returns a complete list of links in a single HTML response. No pagination is used.

## Rate Limits

> No rate limiting configured at the application level. Rate limiting, if any, is enforced upstream by the Routing Service or Hybrid Boundary infrastructure.

## Versioning

No API versioning is applied. The service exposes a single version of each route. The OpenAPI spec version field reflects the git commit SHA of the last spec update (`41de781d2abf5bdc894a9e50ee5b3d28`), not a semantic API version.

## OpenAPI / Schema References

- OpenAPI 3.0 spec: `doc/openapi.yml` in the service repository
- Service Portal: https://service-portal.groupondev.com/services/html-site-map
- Contact: seo-dev@groupon.com
