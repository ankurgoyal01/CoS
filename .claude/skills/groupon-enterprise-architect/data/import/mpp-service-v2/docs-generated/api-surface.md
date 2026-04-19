---
service: "mpp-service-v2"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: []
---

# API Surface

## Overview

MPP Service V2 exposes a REST/JSON API under the `/mpp/v1/` prefix, grouped into three functional areas: place data retrieval, slug/redirect resolution, and sitemap generation. An additional set of admin endpoints under `/admin/index-sync/` provides operational control over the index synchronization job. The API is consumed by MBNXT, SEO tooling, and internal Groupon services that need canonical merchant place data. All endpoints return `application/json` except the sitemap, which returns `application/octet-stream`.

## Endpoints

### Place

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/mpp/v1/place/{location}/{name}` | Retrieves full place data by slug (location + name permalink). Returns `PlaceData`. Supports `locale`, `showRelatedPlaces`, `showPlaceAttributes`, `view`, `client_id`, `relatedPlacesLimit` query params. Returns 301 on redirect, 404 if not found. | None |
| `GET` | `/mpp/v1/place/{placeId}` | Retrieves short place data by UUID. Returns `PlaceData`. Returns 301 on redirect, 404 if not found. | None |
| `GET` | `/mpp/v1/places/{placeId}` | Retrieves place data by UUID with configurable view type (`short`, `map`, `full`). Returns `MapPlaceData` by default. Supports `locale`, `showRelatedPlaces`, `showPlaceAttributes`, `view`, `client_id`, `relatedPlacesLimit`. Returns 301 on redirect, 404 if not found. | None |
| `GET` | `/mpp/v1/places` | Retrieves multiple places by comma-separated UUIDs (max 100). Supports `view` parameter (`short`, `map`, `full`). Returns array of `MapPlaceData`. Returns 400 if too many IDs, 404 if not found. | None |

### Slug / Redirect

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/mpp/v1/mapping/slug/{location}/{name}` | Resolves slug to place redirect information. Returns `RedirectResponseDto` with `placeId` and `message`. Returns 301 on redirect, 404 if slug not found. | None |

### Index

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `PUT` | `/mpp/v1/index` | Sets indexed state for a batch of slugs (permalinks). Body: `IndexingRequest` (`slugs`, `indexed`). Returns count of updated slugs. | None |
| `GET` | `/mpp/v1/update/index/{placeId}` | Re-indexes a single place by UUID and returns count of updated slugs. Returns 404 if place not found. | None |

### Sitemap

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/mpp/v1/sitemap` | Returns sitemap file for a given domain (query param `domain`). Returns `application/octet-stream`. | None |
| `GET` | `/mpp/v1/sitemap/generate` | Triggers sitemap generation for the MPP service. | None |

### Admin — Index Sync

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/admin/index-sync/batch-size` | Returns current batch size for the index-sync job. | None |
| `POST` | `/admin/index-sync/batch-size` | Sets batch size (query param `size`). | None |
| `GET` | `/admin/index-sync/thread-count` | Returns current thread count for the index-sync job. | None |
| `POST` | `/admin/index-sync/thread-count` | Sets thread count (query param `count`). | None |
| `GET` | `/admin/index-sync/enabled` | Returns whether the index-sync job is enabled. | None |
| `POST` | `/admin/index-sync/enable` | Enables the index-sync job. | None |
| `POST` | `/admin/index-sync/disable` | Disables the index-sync job. | None |
| `GET` | `/admin/index-sync/health` | Returns health status of the index-sync job. | None |
| `GET` | `/admin/index-sync/status` | Returns recent sync job run statuses (query param `limit`, default 20). | None |
| `GET` | `/admin/index-sync/recent-changes` | Returns recent slug index changes (query param `limit` default 50, optional `reason`). | None |
| `GET` | `/admin/index-sync/test` | Runs a test index-sync cycle (query param `batchSize`, default 5). | None |
| `GET` | `/admin/index-sync/check-deals` | Checks deal presence for given place IDs (query params: `placeIds`, `locale`, `country`, `lat`, `lng`). | None |
| `GET` | `/admin/index-sync/check-any-deals` | Checks whether any deals exist for given place IDs. Same query params as `check-deals`. | None |
| `POST` | `/admin/index-sync/process-slugs` | Manually processes a list of slugs (query param `slugs`). | None |

## Request/Response Patterns

### Common headers

> No evidence found in codebase for required custom request headers. Standard HTTP headers (`Content-Type: application/json`, `Accept: application/json`) apply.

### Error format

Standard Dropwizard JAX-RS error responses. Known HTTP codes:
- `200` — Success
- `301` — Place or slug redirected to a new URL
- `400` — Bad request (e.g., too many place IDs)
- `404` — Slug or place not found

### Pagination

The `/mpp/v1/places` (bulk) endpoint accepts a comma-separated `ids` query parameter (max 100 UUIDs). No cursor-based or offset pagination is defined for these endpoints.

## Rate Limits

> No rate limiting configured. The service relies on upstream load balancing and Kubernetes HPA.

## Versioning

All production API paths are versioned with the `v1` prefix in the URL path (e.g., `/mpp/v1/place/{location}/{name}`). The service does not use header or query-parameter versioning.

## OpenAPI / Schema References

The OpenAPI 2.0 (Swagger) specification is located at:
- YAML: `doc/swagger/swagger.yaml`
- JSON: `doc/swagger/swagger.json`
- Config: `doc/swagger/config.yml`

The spec is registered in `.service.yml` via `open_api_schema_path: doc/swagger/swagger.yaml`.
