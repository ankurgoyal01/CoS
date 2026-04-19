---
service: "emailsearch-dataloader"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: []
---

# API Surface

## Overview

The Email Search Dataloader exposes a small REST API (JAX-RS) for querying campaign performance data. The API is primarily used internally by other Rocketman platform services and operators. The two published endpoints allow callers to retrieve performance data for a single campaign by UTM campaign identifier or to bulk-query performances for multiple campaigns. The service also exposes a standard JTier health check endpoint.

## Endpoints

### Campaign Performance

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/campaign_performance/{utm_campaign}` | Retrieve overall performance data for a single UTM campaign | Not documented in codebase |
| POST | `/campaign_performances` | Retrieve performance data for multiple UTM campaigns (bulk) | Not documented in codebase |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Kubernetes readiness and liveness probe; returns service health status | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST requests
- `Accept: application/json` — expected for all responses

### Error format

> No evidence found in codebase of a custom error response envelope beyond standard JAX-RS HTTP error responses.

### Pagination

> No evidence found in codebase of pagination support on the campaign performance endpoints.

### GET /campaign_performance/{utm_campaign}

- **Path parameter**: `utm_campaign` — the UTM campaign string identifying a specific treatment send (classified as personal data CLASS4 per JTier annotation)
- **Response**: JSON object containing campaign performance metrics (click, open, send counts, GP)

### POST /campaign_performances

- **Request body**: `ListPerformancesRequest` JSON object containing a list of UTM campaign identifiers
- **Response**: JSON object containing a list of `CampaignPerformance` objects

## Rate Limits

> No rate limiting configured. The API is an internal service-to-service interface.

## Versioning

The API is versioned implicitly by artifact version (`1.0.x`). No URL path versioning or API header versioning is implemented. The OpenAPI spec (`doc/swagger/swagger.yaml`) contains only the version stub (`1.0.local-SNAPSHOT`) with no endpoint definitions.

## OpenAPI / Schema References

- Swagger config: `doc/swagger/config.yml`
- Swagger spec: `doc/swagger/swagger.yaml` (minimal stub — endpoint definitions are code-generated via `CampaignPerformanceApi.java`)
- Generated API interface: `src/main/java/com/groupon/rocketman/emailsearch/api/CampaignPerformanceApi.java`
- Request model: `src/main/java/com/groupon/rocketman/emailsearch/api/model/ListPerformancesRequest.java`
- Response model: `src/main/java/com/groupon/rocketman/emailsearch/api/model/CampaignPerformances.java`
