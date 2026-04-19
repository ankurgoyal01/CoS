---
service: "bhuvan"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: ["client_id"]
---

# API Surface

## Overview

Bhuvan exposes a versioned REST API over HTTP (port 8080). All endpoints return `application/json`. Consumers identify themselves with a `client_id` query parameter validated against the registered GeoClient registry. The API is grouped into five functional areas: geo places (divisions, localities, neighborhoods, postal codes, timezones), geo details (geocode/reverse-geocode, autocomplete, address normalization, timezone), taxonomy management (places, sources, place types, indexes, relationship types), index management (rebuild), and internal operations (cache, clients, heartbeat).

## Endpoints

### Divisions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1.0/divisions` | List divisions with optional name/permalink/country/status/lat-lng/IP filters | client_id |
| GET | `/v1.0/divisions/{divisionId}` | Get division by UUID | client_id |
| GET | `/v1.0/divisions/nearby` | Get divisions within radius of lat/lng or IP address | client_id (required) |
| GET | `/v1.0/divisions/count` | Count divisions matching filters | client_id |
| GET | `/v1.1/divisions` | List divisions (v1.1 — adds redirect and fallback params, paginated response) | client_id (required) |
| GET | `/v1.1/divisions/{divisionId}` | Get division by UUID (v1.1) | client_id (required) |
| GET | `/v1.1/divisions/nearby` | Get nearby divisions (v1.1, paginated) | client_id (required) |
| GET | `/v1.2/divisions` | List divisions (v1.2) | client_id (required) |
| GET | `/v1.2/divisions/{divisionId}` | Get division by UUID (v1.2) | client_id (required) |
| GET | `/v1.2/divisions/nearby` | Get nearby divisions (v1.2) | client_id (required) |
| GET | `/v1.2/divisions/best` | Get best-match division for lat/lng, IP, or country default | client_id (required) |
| GET | `/v1.3/divisions` | List divisions (v1.3 — adds customer_visible filter) | client_id (required) |
| GET | `/v1.3/divisions/{divisionId}` | Get division by UUID (v1.3) | client_id (required) |
| GET | `/v1.3/divisions/nearby` | Get nearby divisions (v1.3) | client_id (required) |

### Localities

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1.0/localities` | List/search localities by lat/lng, IP, name, country | client_id (required) |
| GET | `/v1.0/localities/{localityId}` | Get locality by UUID | client_id (required) |

### Neighborhoods

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1.0/neighborhoods` | Search neighborhoods by lat/lng or IP, with optional related entity inclusion | client_id (required) |

### Postal Codes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1.0/postalcodes` | Search postal codes by country, zip, lat/lng, IP | client_id (required) |
| GET | `/v1.0/postalcodes/{postalcodeId}` | Get postal code by UUID | client_id (required) |
| GET | `/v1.1/postalcodes` | Search postal codes (v1.1) | client_id (required) |

### Taxonomy: Places

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/places` | List/search places with bounding box, source facets, label, index filters | - |
| GET | `/places/{id}` | Get place by UUID | - |
| POST | `/places/getPlaces` | Batch lookup of places by UUID list | - |
| GET | `/places/locate` | Reverse geocode: find place(s) containing lat/lng | - |
| POST | `/places/locate` | Batch reverse geocode: find places for list of lat/lng coordinates | - |
| GET | `/places/count` | Count places matching query params | - |

### Taxonomy: Indexes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/indexes` | Paginated list of index definitions | - |
| POST | `/indexes` | Create a new index definition | - |
| GET | `/indexes/{id}` | Get index by UUID or name | - |
| PUT | `/indexes/{id}` | Update an existing index definition | - |
| POST | `/indexes/rebuild` | Rebuild spatial/search index by name (expensive, use with caution) | - |

### Taxonomy: Sources

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/sources` | Paginated list of sources | - |
| POST | `/sources` | Create a new source | - |
| GET | `/sources/{id}` | Get source by UUID | - |
| PUT | `/sources/{id}` | Update a source | - |
| DELETE | `/sources/{id}` | Delete a source | - |

### Taxonomy: Place Types

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/placeTypes` | List place types, filterable by source_uuid or type | - |
| POST | `/placeTypes` | Create a new place type | - |
| GET | `/placeTypes/{id}` | Get place type by UUID | - |
| PUT | `/placeTypes/{id}` | Update a place type | - |
| DELETE | `/placeTypes/{id}` | Delete a place type | - |

### Taxonomy: Relationship Types

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/relationshipTypes` | List all relationship types | - |
| POST | `/relationshipTypes` | Create a relationship type | - |

### Internal / Ops

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Dropwizard readiness/liveness health check | - |
| GET | `/grpn/status` | Service status with commit SHA (`commitId`) | - |

## Request/Response Patterns

### Common headers
- `Content-Type: application/json` required on POST/PUT bodies.

### Error format
Standard error responses use `ClientError` (4xx) and `ServerError` (5xx) JSON schemas. Both contain an error message and HTTP status code. Common codes:
- `400 Bad Request` — invalid parameters
- `401 Unauthorized` — missing or invalid credentials
- `403 Forbidden` — insufficient permissions
- `410 Gone` — resource no longer available
- `429 Too Many Requests` — rate limit exceeded
- `500/502/503/504` — server-side errors

### Pagination
- v1.0 division endpoints use `offset` (default 0) and `limit` (default 25, max 1000) query parameters and return a plain JSON array.
- v1.1+ division endpoints return a `PaginatedEntities` response envelope.
- Taxonomy `/places` and `/sources` endpoints use cursor-style `start` (int64) and `rows` parameters.

## Rate Limits

> No rate limiting configured in the codebase. The `429 Too Many Requests` error is defined in the OpenAPI schema but upstream rate limiting is handled at the API gateway / infrastructure level.

## Versioning

URL path versioning is used for geo entity endpoints: `/v1.0/`, `/v1.1/`, `/v1.2/`, `/v1.3/`. Taxonomy endpoints (`/places`, `/sources`, `/placeTypes`, `/indexes`, `/relationshipTypes`) are unversioned. Consumers should target the highest available version for new integrations.

## OpenAPI / Schema References

- Full OpenAPI 3.0 spec: `doc/openapi.yml`
- Swagger JSON: `doc/swagger/swagger.json`
- Swagger YAML: `doc/swagger/swagger.yaml`
- Live schema (staging): `https://bhuvan.staging.service.us-west-1.aws.groupondev.com/swagger`
