---
service: "arbitration-service"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth]
---

# API Surface

## Overview

The Arbitration Service exposes a synchronous REST API consumed by marketing delivery clients during campaign send workflows. The API surface covers three operational domains: campaign decisioning (best-for and arbitrate), campaign revoke, and delivery rule administration. A separate group of endpoints handles experiment configuration management. All request and response bodies use JSON encoding.

## Endpoints

### Campaign Decisioning

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/best-for` | Filter and rank eligible campaigns for a user | Internal service auth |
| POST | `/arbitrate` | Apply quota enforcement and select single winner campaign | Internal service auth |
| POST | `/revoke` | Revoke a previously committed campaign send | Internal service auth |

### Delivery Rule Administration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/delivery-rules` | List all delivery rules | Internal service auth |
| POST | `/delivery-rules` | Create a new delivery rule | Internal service auth |
| PUT | `/delivery-rules/:id` | Update an existing delivery rule by ID | Internal service auth |
| DELETE | `/delivery-rules/:id` | Delete a delivery rule by ID | Internal service auth |

### Experiment Configuration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/experiment-config` | Fetch current experiment configuration | Internal service auth |
| POST | `/experiment-config/refresh` | Trigger re-fetch of Optimizely experiment definitions | Internal service auth |

### Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Liveness and readiness health check | None |
| GET | `/metrics` | Expose service metrics | Internal |

## Request/Response Patterns

### Common headers

> No evidence found in codebase for specific required headers beyond standard `Content-Type: application/json`.

### Error format

> No evidence found in codebase for a standardized error response schema. Errors are expected to return appropriate HTTP status codes (4xx for client errors, 5xx for server errors) with a JSON body.

### Pagination

> No evidence found in codebase for pagination on list endpoints. `GET /delivery-rules` is assumed to return all records.

## Rate Limits

> No rate limiting configured at the application layer. Quota enforcement is applied at the business logic level (frequency caps) rather than as an HTTP rate limiter.

## Versioning

No API versioning strategy found in the inventory. The API uses unversioned URL paths.

## OpenAPI / Schema References

> No evidence found in codebase of an OpenAPI spec, proto files, or schema definitions committed to the repository.
