---
service: "service-portal"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, api-key]
---

# API Surface

## Overview

Service Portal exposes a versioned JSON REST API consumed by engineering teams, CI pipelines, and internal tooling. The primary version is v2, covering service CRUD, metadata sub-resources, check results, dependencies, and cost data. A legacy v1 API exists for service attribute management. A validation endpoint serves CI pipelines that need to verify `service.yml` files. A webhook processor endpoint receives push events from GitHub Enterprise.

## Endpoints

### Services (v2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v2/services` | List all registered services | session / api-key |
| POST | `/api/v2/services` | Register a new service | session / api-key |
| GET | `/api/v2/services/{id}` | Retrieve a single service record | session / api-key |
| PUT/PATCH | `/api/v2/services/{id}` | Update a service record | session / api-key |
| DELETE | `/api/v2/services/{id}` | Deregister a service | session / api-key |
| GET | `/api/v2/services/{id}/metadata` | Retrieve metadata for a service | session / api-key |
| PUT/PATCH | `/api/v2/services/{id}/metadata` | Update metadata for a service | session / api-key |
| GET | `/api/v2/services/{id}/check_results` | List latest check results for a service | session / api-key |
| GET | `/api/v2/services/{id}/dependencies` | List dependencies declared by a service | session / api-key |
| POST | `/api/v2/services/{id}/dependencies` | Declare a dependency for a service | session / api-key |
| GET | `/api/v2/services/{id}/costs` | Retrieve cost records for a service | session / api-key |

### Checks (v2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v2/checks` | List all check definitions | session / api-key |
| GET | `/api/v2/checks/{id}` | Retrieve a single check definition | session / api-key |

### Service Attributes (v1 — legacy)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/service_attributes` | List legacy service attribute records | session / api-key |
| POST | `/api/v1/service_attributes` | Create a legacy service attribute | session / api-key |
| GET | `/api/v1/service_attributes/{id}` | Retrieve a legacy service attribute | session / api-key |
| PUT/PATCH | `/api/v1/service_attributes/{id}` | Update a legacy service attribute | session / api-key |
| DELETE | `/api/v1/service_attributes/{id}` | Delete a legacy service attribute | session / api-key |

### Validation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/validation/service.yml/validate` | Validate an uploaded `service.yml` file; returns pass/fail with errors | api-key |

### GitHub Webhook Processor

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/processor` | Receive and process GitHub Enterprise webhook events (push, PR) | HMAC signature (X-Hub-Signature-256) |

### Reports

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/reports/*` | Serve inactivity and cost reports | session |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST/PUT/PATCH requests
- `Accept: application/json` — expected on all API requests
- `X-Hub-Signature-256` — required on `/processor` requests (GitHub HMAC webhook signature)

### Error format

> No evidence found for a standardized error response envelope. Standard Rails JSON error rendering is assumed (HTTP status code + JSON body with `error` or `errors` key).

### Pagination

> No evidence found for a specific pagination scheme. List endpoints may use Rails default query parameters (`page`, `per_page`).

## Rate Limits

> No rate limiting configured.

## Versioning

The API uses URL path versioning. The current primary version is `/api/v2/`. The legacy version `/api/v1/` is maintained for backward compatibility with existing consumers of service attribute endpoints.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema were found in the service inventory.
