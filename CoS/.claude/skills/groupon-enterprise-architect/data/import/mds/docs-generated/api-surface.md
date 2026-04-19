---
service: "mds"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth]
---

# API Surface

## Overview

MDS exposes two API layers: the JTier API (Java/Dropwizard) providing deal query, filter, division, refresh, and partner integration endpoints, and the original MDS API (Spring Boot) providing merchant-facing deal management, feed generation, and performance reporting endpoints. Both layers serve internal consumers including the Marketing Platform, partner feed systems, and internal analytics tooling.

## Endpoints

### Deal Query and Retrieval (JTier API)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/deals` | Query deals with filtering, pagination, and optional inventory enrichment | Internal service auth |
| `GET` | `/deals/{id}` | Retrieve a single deal with full enrichment | Internal service auth |
| `GET` | `/deals/hot` | Retrieve hot/trending deals | Internal service auth |
| `GET` | `/divisions` | List available deal divisions | Internal service auth |
| `POST` | `/deals/refresh` | Trigger refresh of deal data from upstream sources | Internal service auth |

### Partner Integration (JTier API)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/partners/feeds` | Retrieve partner feed data for external distribution channels | Internal service auth |
| `GET` | `/partners/deals` | Query deals formatted for partner consumption | Internal service auth |

### Merchant Deal Management (MDS API)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/deals/{id}` | Retrieve deal details for merchant context | Internal service auth |
| `POST` | `/deals` | Create a new deal | Internal service auth |
| `PUT` | `/deals/{id}` | Update existing deal | Internal service auth |
| `GET` | `/feeds` | Get feed generation status | Internal service auth |

### Feed Generation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/feeds/generate` | Trigger partner feed generation | Internal service auth |
| `GET` | `/feeds/status` | Check feed generation job status | Internal service auth |

### Performance and Metrics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/performance/merchants/{merchantId}` | Retrieve merchant KPI metrics | Internal service auth |
| `GET` | `/performance/deals/{dealId}` | Retrieve deal performance data | Internal service auth |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — all requests and responses use JSON
- `X-Request-Id` — correlation ID for distributed tracing
- Service discovery headers for internal routing

### Error format

Standard Continuum error response shape:
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable description",
    "details": []
  }
}
```

### Pagination

Deal list queries support offset-based pagination:
- `offset` — starting index (default: 0)
- `limit` — maximum results per page (default: 20, max: 100)
- Response includes `total` count for client-side pagination

## Rate Limits

> No rate limiting configuration was identified in the architecture model. Rate limiting may be handled at the infrastructure/gateway level.

## Versioning

The JTier API layer does not use explicit URL versioning — endpoints are served at the root path. The original MDS API follows the Continuum convention for internal service APIs. Versioning is managed at the service discovery level.

## OpenAPI / Schema References

> OpenAPI specification to be confirmed by the marketing-deals team. Endpoint details are inferred from the architecture model component definitions (Deal API Resources, API Controller).
