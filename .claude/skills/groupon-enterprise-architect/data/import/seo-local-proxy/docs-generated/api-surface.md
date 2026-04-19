---
service: "seo-local-proxy"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [http]
auth_mechanisms: [none]
---

# API Surface

## Overview

SEO Local Proxy exposes a static file serving API via Nginx. There is no authentication on any endpoint — all responses serve publicly readable SEO files. Consumers are primarily search engine crawlers (Googlebot, Bingbot, etc.) routed through the `routing-service`. The Nginx server resolves the correct S3 path at request time using the `X-Forwarded-Host` header to determine country and brand, then proxies the file from the `continuumSeoLocalProxyS3Bucket`.

## Endpoints

### Public SEO File Endpoints

These are the paths exposed to the internet via `routing-service` routing. The `X-Forwarded-Host` header (set by `routing-service`) is required to resolve country and brand.

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/robots.txt` | Serves the robots.txt for the TLD matching `X-Forwarded-Host` | None |
| GET | `/sitemap.xml` | Serves the sitemap index XML for the TLD matching `X-Forwarded-Host` | None |
| GET | `/sitemaps/{filename}.xml.gz` | Serves an individual gzip-compressed sitemap file | None |

### Internal Health / Operational Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/nginx_status` | Nginx stub status (connection counts, requests) | None (internal) |
| GET | `/grpn/healthcheck` | Returns HTTP 200 — used by Kubernetes liveness checks | None (internal) |
| GET | `/heartbeat.txt` | Returns HTTP 200 — secondary health probe | None (internal) |

### Direct S3 Proxy Endpoints (internal service mesh)

These paths are accessible on the `seo-local-proxy` Hybrid Boundary endpoint (not directly from the internet) and serve files from S3 using the structured directory layout.

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/robots/{country}/{brand}/robots.txt` | Fetches robots.txt for a specific country and brand from S3 | None |
| GET | `/{country}/{brand}/sitemap.xml` | Fetches sitemap index for a specific country and brand from S3 | None |
| GET | `/{country}/{brand}/sitemap/{filename}.xml.gz` | Fetches individual sitemap file from S3 | None |

**Example paths (staging):**
- `https://seo-local-proxy.staging.service.us-central1.gcp.groupondev.com/robots/US/https/robots.txt`
- `https://seo-local-proxy.staging.service.us-central1.gcp.groupondev.com/US/https/sitemap.xml`
- `https://seo-local-proxy.staging.service.us-central1.gcp.groupondev.com/US/https/sitemap/*`

## Request/Response Patterns

### Common headers

- `X-Forwarded-Host`: Required for public endpoints. Set by `routing-service`. Used by Nginx to resolve `$country` and `$website` map variables.
- `X-Request-Id`: Passed through and logged by Nginx for tracing.
- `Cookie`: Stripped by Nginx before proxying upstream (no cookies forwarded to S3).

### Gzip response headers

For `/sitemaps/*.xml.gz` responses, Nginx adds the following headers:

- `Content-Encoding: gzip`
- `Content-Type: application/xml`
- `Accept-Ranges: bytes`

### Error format

> No structured error response format. Nginx returns standard HTTP error codes (404 if file not found in S3, 5xx on S3 connectivity failures). No JSON error envelope.

### Pagination

> Not applicable. Sitemaps are split into individual channel files (e.g., `browse0.xml.gz`, `browse1.xml.gz`) and listed in the sitemap index; pagination is implicit in the sitemap protocol.

## Rate Limits

> No rate limiting configured on the Nginx layer.

## Versioning

> No API versioning. File paths follow the S3 directory structure: `/{country}/{brand}/{type}`. Country codes use ISO 2-letter codes. Brand values are `https`, `livingsocial`, or `speedgroupon`.

## OpenAPI / Schema References

> No OpenAPI spec. The API surface is a static file proxy. Schema validation is disabled per `.service.yml` (`schema: disabled`).
