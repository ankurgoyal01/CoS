---
service: "ingestion-jtier"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

ingestion-jtier exposes a REST API over HTTP (JAX-RS / Dropwizard) for triggering feed ingestion runs, managing deal state, querying availability, and performing bulk operations. All endpoints are intended for internal callers — Jenkins pipelines, ops tooling, and scheduled Quartz triggers. The API is versioned at the path level (`/v1`).

## Endpoints

### Ingestion Triggers

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/ingest/v1/start` | Triggers a full partner feed extraction and ingestion run | internal |
| POST | `/ingest/v1/availability/start` | Triggers an availability synchronization run for existing deals | internal |
| POST | `/ingest/v1/availability/bulk/start` | Triggers a bulk availability synchronization run across multiple partners | internal |
| POST | `/ingest/v1/offer` | Submits a single offer for ingestion processing | internal |
| POST | `/ingest/v1/deal_deletion_processor` | Triggers processing of pending deal deletions | internal |

### Deal State Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| PUT | `/deals/v1/pause` | Pauses one or more active deals | internal |
| PUT | `/deals/v1/unpause` | Resumes one or more paused deals | internal |
| PUT | `/deals/v1/addAdditionalPlace` | Associates an additional place/location with an existing deal | internal |

### Partner Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| PUT | `/partner/v1/pause` | Pauses all active deals for a given partner | internal |
| GET | `/partner/v1/feed/availability` | Returns current feed availability status for a partner | internal |
| GET | `/partner/v1/stats/availabilitySegment` | Returns availability segment statistics for a partner | internal |

### Offer Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| PUT | `/offer/v1/blacklist` | Adds an offer to the blacklist, preventing future ingestion | internal |

### Distribution Constraints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| PUT | `/distributionConstraint/v1/bulkUpdate` | Bulk-updates distribution constraints across deals | internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all POST/PUT requests with a body
- `Accept: application/json` — expected on GET requests

### Error format

Standard Dropwizard error response shape:

```json
{
  "code": 422,
  "message": "Unable to process entity"
}
```

HTTP status codes follow REST conventions: `200 OK`, `202 Accepted` for async triggers, `400 Bad Request` for validation failures, `422 Unprocessable Entity` for business rule violations, `500 Internal Server Error` for unexpected failures.

### Pagination

> No evidence found of pagination on current endpoints. Bulk operations accept array payloads in the request body.

## Rate Limits

> No rate limiting configured. All endpoints are internal and rely on caller discipline and Kubernetes resource limits.

## Versioning

URL path versioning is used throughout. All current endpoints are at `/v1`. Path prefix indicates the resource group (`/ingest`, `/deals`, `/partner`, `/offer`, `/distributionConstraint`).

## OpenAPI / Schema References

> No OpenAPI spec file found in the service inventory. Schema is defined implicitly by JAX-RS resource classes and Jackson-annotated request/response DTOs.
