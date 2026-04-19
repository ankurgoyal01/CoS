---
service: "place-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [client-id]
---

# API Surface

## Overview

The M3 Place Service exposes a REST HTTP API over JSON. All functional endpoints require a `client_id` query parameter identifying the calling application. The service provides two major versioned API paths (`/v2.0/` and `/v3.0/`), plus write endpoints under `/placewriteservice/`, a Google place lookup endpoint, a defrank (normalization) endpoint, a source metadata endpoint, and a status/health endpoint. The v2.0 place search endpoints are available for NA only; v3.0 endpoints are available for both NA and EMEA.

## Endpoints

### Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/status/**` | Health check — returns OK when the application is up | none |
| GET | `/placereadservice/v2.0/status` | Kubernetes readiness/liveness probe endpoint | none |

### Place Read (v2.0 — NA only)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2.0/places/` | Search places using optional filter parameters | `client_id` (required) |
| GET | `/v2.0/places/{id}` | Retrieve a single place by ID | `client_id` (required) |
| GET | `/v2.0/places/autocomplete` | Autocomplete place name by prefix | `client_id` (required) |
| GET | `/v2.0/places/count` | Count places matching filter criteria | `client_id` (required) |
| GET | `/v2.0/places/proxy/` | Deprecated — search places (legacy proxy path) | `client_id` (required) |

### Place Read (v3.0 — NA and EMEA)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v3.0/places/{id}` | Retrieve a single place by ID | `client_id` (required) |
| GET | `/v3.0/places/count` | Count places matching filter criteria | `client_id` (required) |
| GET | `/v3.0/places` | Search places using optional filter parameters | `client_id` (required) |

### Place Write

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/placewriteservice/v3.0/places` | Create a new place record | `client_id` (required) |
| PUT | `/placewriteservice/v3.0/places/{id}` | Update an existing place record | `client_id` (required) |
| POST | `/placewriteservice/v3.0/places/{id}/merge` | Merge two place records | `client_id` (required) |
| GET | `/placewriteservice/v3.0/places/{id}/history` | Retrieve place change history | `client_id` (required) |

### Google Place Lookup

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2.0/places/{id}/googleplace` | Look up Google Places candidates for a given M3 place | `client_id` (required) |

### Defrank (Normalization)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/defrank` | Normalize and defrank place data | `client_id` (required) |

### Source Metadata

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2.0/sources` | List available place data sources | `client_id` (required) |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST/PUT bodies
- `client_id` — passed as a query parameter on all functional requests; identifies the calling application
- `Cache-Control: no-cache` — supported to bypass Redis cache on read requests

### Common query parameters (place search and count)

| Parameter | Type | Description |
|-----------|------|-------------|
| `client_id` | string | Required. Identifies the calling application |
| `view_type` | enum | `external` (default) or `internal` — controls field visibility in response |
| `limit` | integer | Max results to return (default: 25, max: 1000) |
| `offset` | integer | Result offset for pagination (default: 0) |
| `name` | string | Filter by place name |
| `country` / `countries` | string / array | Filter by country code(s) |
| `postcodes` | array | Filter by postal codes |
| `localities` | array | Filter by locality names |
| `latitude` + `longitude` + `radius` | number + number + integer | Geo-radius filter (radius in meters, default: 1000) |
| `status` | string | `open`, `closed`, or `uncertain` |
| `visibility` | string | `visible` (default) or `hidden` |
| `sort_by` | string | Sort by `name`, `locality`, `region`, `country`, `status`, or `offers` |
| `sort_direction` | string | `ASC` (default) or `DESC` |
| `brand_ids` | array | Filter by brand IDs |
| `category_ids` | array | Filter by category IDs |
| `place_type` | string | Filter by place type |
| `has_brand` | boolean | Filter to places with or without a brand |
| `partial_match` | boolean | Enable partial name match (default: exact match) |
| `fuzziness` | float | Fuzzy name matching (0.0–1.0) |
| `response_view` | string | Limit response fields, e.g., `deal`, `gdt`, `essence` |
| `query` | string | Full-text search across all place fields |
| `phone_number` | string | Filter by phone number |
| `service_ids` | array | Filter by services offered IDs |

### Error format

Standard HTTP status codes. Error conditions return:
- `401 Unauthorized` — missing or invalid credentials
- `403 Forbidden` — insufficient permissions for `client_id`
- `404 Not Found` — place not found by ID
- `500 Internal Server Error` — application/persistence failure

### Pagination

Offset-based pagination: use `limit` (max 1000, default 25) and `offset` (default 0) query parameters on search and list endpoints.

## Rate Limits

> No rate limiting configured at the application layer. Traffic management is handled by the Kubernetes HPA and upstream load balancer.

## Versioning

URL path versioning: `/v2.0/` for legacy NA-only endpoints, `/v3.0/` for current endpoints supporting both NA and EMEA. `/placewriteservice/v3.0/` for write operations.

## OpenAPI / Schema References

OpenAPI 2.0 (Swagger) specification: `doc/swagger.json`

Service host: `place-service.snc1` (on-prem), `m3-placeread.production.service.us-central1.gcp.groupondev.com` (cloud US), `m3-placeread.production.service.eu-west-1.aws.groupondev.com` (cloud EU)
