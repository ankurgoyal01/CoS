---
service: "suggest"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [none]
---

# API Surface

## Overview

The Suggest API exposes three functional endpoint groups over HTTP REST on port 8080. The primary consumer is the MBNXT search client, which calls `GET /suggestions` for typeahead results and `POST /query-preprocessing` for query enrichment. Admin endpoints provide health and version information for platform orchestration. All responses are JSON. The OpenAPI spec is available at `doc/openapi.json`.

## Endpoints

### Suggestions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/suggestions` | Returns ranked query suggestions and category suggestions for a partial search query, given user coordinates | None |

**Query parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `query` | string | yes | — | Partial search string typed by the user |
| `lat` | float | yes | — | User latitude |
| `lon` | float | yes | — | User longitude |
| `query_limit` | integer | no | `10` | Maximum number of query suggestions to return |
| `category_limit` | integer | no | `10` | Maximum number of category suggestions to return |
| `query_preprocessing_enabled` | boolean | no | `false` | When `true`, applies typo correction and locality detection before suggestion lookup |
| `debug_mode` | boolean | no | `false` | When `true`, includes per-step timing and ranking debug information in the response |
| `exclude_adult_content` | boolean | no | `false` | When `true`, filters out adult-content suggestions |

**Response (`200 OK`):**

```json
{
  "did_you_mean": "string",
  "suggestions": [
    { "value": "string", "type": "query | category" }
  ],
  "debug": null
}
```

### Query Preprocessing

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/query-preprocessing` | Preprocesses a raw query: typo correction, locality detection, radius prediction, adult detection, category detection | None |

**Request body:**

```json
{
  "query": "string",
  "lat": 0.0,
  "lon": 0.0,
  "features": "typo_fix,locality_detection,radius_prediction,adult_detection,category_detection"
}
```

The `features` field is a comma-separated list of preprocessing features to apply. Omitting it defaults to `typo_fix` and `locality_detection`. Features individually configurable and may be disabled server-side via `QueryPreprocessing.disabled_features` config.

**Response (`200 OK`):**

```json
{
  "search_query": "string",
  "locality_detection": {
    "locality": {
      "name": "string",
      "state": "string",
      "division": { "permalink": "string" },
      "coordinates": { "lat": 0.0, "lon": 0.0 }
    }
  },
  "predicted_radius_km": 40,
  "is_adult_query": false,
  "best_search_terms": [
    {
      "value": "string",
      "category_detection": [{ "category_uuid": "string" }],
      "merchant_detection": [{ "merchant_name": "string" }]
    }
  ]
}
```

### Admin

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/healthcheck` | Returns `{"status": "ok"}` for liveness/readiness probes | None |
| `GET` | `/grpn/versions` | Returns service SHA and build version metadata | None |
| `GET` | `/metrics` | Prometheus metrics scrape endpoint | None |

## Request/Response Patterns

### Common headers

- `User-Agent` — required by the `/suggestions` endpoint per OpenAPI spec

### Error format

FastAPI validation errors return HTTP `422` with the following shape:

```json
{
  "detail": [
    { "loc": ["query", "field_name"], "msg": "error message", "type": "error_type" }
  ]
}
```

### Pagination

> Not applicable. The service uses `query_limit` and `category_limit` parameters for result capping (default and maximum: 10 each) rather than cursor-based pagination.

## Rate Limits

> No rate limiting configured at the application layer. Infrastructure-level rate limiting (if any) is managed by the Groupon ingress/load balancer.

## Versioning

The API does not use URL versioning. The service version is `1.0.0` (as declared in the FastAPI app title and OpenAPI spec). Version information is available at `GET /grpn/versions`.

## OpenAPI / Schema References

- OpenAPI 3.0.3 spec: `doc/openapi.json` (in the service repository)
- OpenAPI schema path registered in `.service.yml`: `doc/openapi.json`
