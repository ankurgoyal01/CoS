---
service: "product-bundling-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

The Product Bundling Service exposes a REST API under the `/v1/bundles` path prefix. Consumers use it to read bundle records for a given deal, create or replace bundles of a specific type, delete bundles, and trigger scheduled refresh jobs manually. Authentication is enforced via a `clientId` query parameter backed by a PostgreSQL client ID registry (JTier `jtier-auth-bundle`).

## Endpoints

### Bundle Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/bundles/{dealUuid}` | Retrieve all bundle records for a deal UUID | clientId param |
| `POST` | `/v1/bundles/{dealUuid}/{bundleType}` | Create (replace) all bundles for a deal UUID and bundle type | clientId param |
| `DELETE` | `/v1/bundles/{dealUuid}/{bundleType}` | Delete all bundles for a deal UUID and bundle type | clientId param |

### Refresh / Admin

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/bundles/refresh/{refreshType}` | Trigger a manual bundle refresh job for the given refresh type | clientId param |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST requests with a body
- `Accept: application/json` — expected for GET responses

### Error format

Standard HTTP status codes are used. Error body format follows the Dropwizard default JSON error structure:

| Status | Meaning |
|--------|---------|
| `200` | Success |
| `400` | Bad request (invalid `bundleType`, invalid `bundledProductId`, invalid products list) |
| `403` | Forbidden — no config found for bundle type, or no creative contents found for bundled product ID |
| `404` | No bundles found for the deal (GET) or no bundles found for deal + type (DELETE) |
| `422` | Unprocessable entity — `products` list in request body is empty |
| `500` | Internal server error |

### Pagination

> Not applicable — bundle sets per deal are returned in full with no pagination.

## Rate Limits

> No rate limiting configured. Concurrency is bounded by `maxRequestsPerHost: 10` and `maxConcurrentRequests: 10` on the downstream DCS client (OkHttp pool).

## Versioning

API is versioned via URL path prefix `/v1/`. No additional versioning headers are used.

## OpenAPI / Schema References

- OpenAPI 2.0 (Swagger) spec: `doc/swagger/swagger.yaml` and `doc/swagger/swagger.json`
- Service discovery resource manifest: `doc/service_discovery/resources.json`
- Base URL (production snc1): `http://product-bundling-service-vip.snc1`
- Base URL (staging snc1): `http://product-bundling-service-staging-vip.snc1`
- Base URL (production GCP): `https://product-bundling-service.us-central1.conveyor.prod.gcp.groupondev.com`
