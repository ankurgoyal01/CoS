---
service: "taxonomyV2"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [jtier-auth-bundle]
---

# API Surface

## Overview

Taxonomy V2 exposes a REST JSON API consumed by internal Groupon services that need to resolve category hierarchies, look up categories by attribute or UUID, browse relationship graphs, and trigger taxonomy content snapshot deployments. All endpoints produce `application/json;charset=UTF-8`. The service operates at ~77K rpm with Tier 1 criticality. The OpenAPI spec is at `doc/swagger/swagger.yaml` in the source repository.

## Endpoints

### Categories

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/categories` | Search all categories by attribute name, value, and optional locale | JTier auth |
| GET | `/categories/root` | Fetch root categories for a given taxonomy GUID | JTier auth |
| POST | `/categories/search` | Batch-fetch categories by a list of UUIDs (1–30 UUIDs) | JTier auth |
| GET | `/categories/{guid}` | Fetch single category details by UUID | JTier auth |
| GET | `/categories/{guid}/relationships` | Fetch all relationships for a given category UUID | JTier auth |

### Taxonomies

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/taxonomies` | List all taxonomies with details and root category UUIDs | JTier auth |
| GET | `/taxonomies/count` | Return the total count of available taxonomies | JTier auth |
| GET | `/taxonomies/{guid}` | Fetch a single taxonomy by UUID | JTier auth |
| GET | `/taxonomies/{guid}/flat` | Fetch flat hierarchy of all categories in a taxonomy (supports `If-Modified-Since` header) | JTier auth |
| GET | `/taxonomies/{guid}/search/categories` | Search categories within a taxonomy by name | JTier auth |

### Snapshots

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| PUT | `/snapshots/activate` | Activate a full taxonomy snapshot by UUID (triggers cache invalidation + Varnish BAN) | JTier auth |
| GET | `/snapshots/activate` | Internal snapshot activation trigger (multi-colo support) | JTier auth |
| GET | `/snapshots/live/last_updated` | Return the timestamp of the last live content update | JTier auth |

### Partial Snapshots

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| PUT | `/partialsnapshots/testactivate` | Activate a partial snapshot in the test environment by UUID | JTier auth |
| PUT | `/partialsnapshots/liveactivate` | Activate a partial snapshot in the live environment by UUID | JTier auth |

### Relations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/relationship_types` | List all available relationship types | JTier auth |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json;charset=UTF-8` — required on `POST`/`PUT` request bodies
- `If-Modified-Since` — supported on `GET /taxonomies/{guid}/flat` to enable conditional response (returns 304 if content unchanged, or 406 if date is unparseable)

### Error format

All errors return a JSON object with a single `message` field:

```json
{
  "message": "Not Found!"
}
```

Standard HTTP status codes used:
- `200` — Success
- `404` — Resource not found
- `406` — Unparseable date in `If-Modified-Since` header
- `500` — Internal Server Error

### Pagination

> No evidence found in codebase. The batch category search endpoint (`POST /categories/search`) accepts 1–30 UUID items per request as an implicit limit.

## SLA Latency Reference

| Endpoint | p99 (ms) | p95 (ms) | Throughput (rpm) |
|----------|----------|----------|-----------------|
| GET `/categories/{guid}` | 20 | 10 | 42,000 |
| GET `/categories/{guid}/relationships` | 20 | 10 | 5,000 |
| GET `/taxonomies/{guid}/flat` (with `If-Modified-Since`) | 20 | 10 | 2,000 |
| GET `/taxonomies/{guid}/flat` (without header) | 10,000 | 6,000 | 200 |
| PUT `/snapshots/activate` | 1,000 | 500 | 5 |
| GET `/taxonomies/{guid}/search/categories` | 1,000 | 500 | 50 |
| GET `/categories/root` | 500 | 100 | 50 |
| GET `/taxonomies` | 500 | 100 | 50 |
| GET `/snapshots/live/last_updated` | 20 | 10 | 50 |

*Source: `doc/owners_manual.md` SLA table.*

## Rate Limits

> No rate limiting configured. Traffic is governed by downstream consumer patterns and the upstream Varnish cache layer.

## Versioning

API is versioned by service version (`2.0.x`). The version is embedded in the Swagger info block (`version: "2.0.local-SNAPSHOT"`) and does not use URL path versioning. Consumers are expected to track the service version via release notes.

## OpenAPI / Schema References

- OpenAPI spec: `doc/swagger/swagger.yaml` (source repo)
- Swagger JSON: `doc/swagger/swagger.json` (source repo)
- Swagger UI (staging): `http://taxonomyv2-app-staging-vip.snc1/swagger`
- Service discovery schema: `doc/service_discovery/resources.json`
