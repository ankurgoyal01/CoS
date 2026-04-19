---
service: "partner-service"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth]
---

# API Surface

## Overview

Partner Service exposes a versioned REST API (JAX-RS / Dropwizard) under the `/partner-service` context path. Consumers use the API to manage partner-to-deal mappings, deal divisions, product-place associations, and audit logs. A simulator sub-API supports integration testing without touching live systems. All endpoints return JSON.

## Endpoints

### Partner Mappings

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/partner-service/v1/partners/{id}/mappings` | Retrieve mapping records for a given partner | Internal service auth |
| POST | `/partner-service/v1/partners/{id}/mappings` | Create or update a mapping for a partner | Internal service auth |

### Deal Divisions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/partner-service/v1/deals/{id}/divisions` | Retrieve division assignments for a deal | Internal service auth |
| POST | `/partner-service/v1/deals/{id}/divisions` | Assign divisions to a deal | Internal service auth |

### Product Places

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/partner-service/v1/products/{id}/places` | Retrieve place associations for a product | Internal service auth |
| POST | `/partner-service/v1/products/{id}/places` | Associate places with a product | Internal service auth |

### Audit Log

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/partner-service/v1/auditlog` | Query audit log entries for partner operations | Internal service auth |

### Simulator

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/partner-service/v1/simulator/*` | Trigger simulated partner integration flows for testing | Internal service auth |
| GET | `/partner-service/v1/simulator/*` | Retrieve simulator state and results | Internal service auth |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all write requests
- `Accept: application/json` — expected on all requests

### Error format

Standard Dropwizard error response:

```json
{
  "code": 422,
  "message": "Validation failed",
  "errors": ["field: error description"]
}
```

### Pagination

> No evidence found in the inventory. Assume endpoint-specific query parameters if pagination is supported.

## Rate Limits

> No rate limiting configured.

## Versioning

URL path versioning is used: all production endpoints are under `/v1/`. The `partnerSvc_apiResources` component exposes both v1 and v2 endpoint groups per the component description; v2 paths were not individually enumerated in the inventory.

## OpenAPI / Schema References

Swagger is listed as a key library, indicating OpenAPI spec generation at runtime. Swagger UI is typically available at `/partner-service/swagger` when the service is running. No static schema file path was identified in the inventory.
