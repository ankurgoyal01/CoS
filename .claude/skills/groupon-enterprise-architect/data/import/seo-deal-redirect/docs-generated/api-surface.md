---
service: "seo-deal-redirect"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [mtls, client-certificate]
---

# API Surface

## Overview

SEO Deal Redirect does not expose an inbound HTTP API. It is a batch pipeline that acts as an API **client**, publishing redirect mappings to the `seo-deal-api` service via HTTPS PUT requests. All API interaction is outbound. Authentication uses mutual TLS (client certificates extracted from a PKCS12/JKS keystore stored in GCP Secret Manager).

## Endpoints Called (Outbound)

### SEO Deal API — Redirect Attribute Update

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `PUT` | `/seodeals/deals/{deal_uuid}/edits/attributes/redirectUrl?source=seo-deal-redirect` | Set or clear the `redirectUrl` attribute for an expired deal | mTLS (client certificate) |
| `PUT` | `/seodeals/deals/{deal_uuid}/edits/attributes?source=manual` | Manual override to set or null a `redirectUrl` for a specific deal | mTLS (client certificate) |
| `PUT` | `/seodeals/deals/{deal_uuid}/edits/attributes/redirectUrl?source=seo-deal-redirect-non-active-merchant` | Set redirect URL for non-active merchant deals | mTLS (client certificate) |

**Production base URL**: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com`

**Staging base URL** (via `api_host` config): `seo-deal-observer-staging-vip.snc1`

**Host header**: `seo-deal-api.production.service`

## Request/Response Patterns

### Common headers

```
Content-Type: application/json
Accept: application/json
Host: seo-deal-api.production.service
```

### Request body (set redirect)

```json
{ "redirectUrl": "https://www.groupon.com/deals/some-live-deal-permalink" }
```

### Request body (clear redirect)

```json
{ "redirectUrl": null }
```

### Success response

HTTP 200. The response body contains the updated deal's SEO data. The pipeline validates:
```
response.seoData.brands.groupon.attributes.redirectUrl == submitted live_deal_url
```

### Error format

Non-200 HTTP status codes are logged with `status`, `reason`, and response body text. The job continues processing remaining deals — individual failures do not abort the batch.

### Pagination

> Not applicable. The API upload job uses a collect-and-iterate pattern over the local DataFrame; no pagination is involved.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| api_upload job | 1,250 calls | 60 seconds |
| non_active_merchant_deals job | 1,250 calls (`redirect_api_calls_per_period`) | 60 seconds (`redirect_api_period_seconds`) |

Rate limiting is enforced client-side using the `ratelimit` library (`@limits(calls=1250, period=60)` decorator with `@sleep_and_retry`).

## Versioning

> No evidence found of API versioning on the outbound endpoint. The path `/seodeals/deals/{uuid}/edits/attributes/redirectUrl` is used directly with no version segment.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema are present in this repository. The SEO Deal API contract is owned by the `seo-deal-api` service.
