---
service: "deletion_service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [client-id]
---

# API Surface

## Overview

The Deletion Service exposes a small admin-only REST API over HTTP on port 8080. All endpoints are restricted to the `ADMIN` role via JTier Client-ID authentication. The API allows operators to query the per-service erasure status for one or more customers and to manually submit erasure requests. This API is not intended for end-user consumption; it exists to support operations and compliance workflows.

The OpenAPI specification is available in the repository at `doc/swagger/swagger.yaml` and `doc/swagger/swagger.json`.

## Endpoints

### Customer Erasure

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/customer` | Manually submit erasure requests for one or more customer IDs | Client-ID (`ADMIN` role) |
| `GET` | `/customer/service` | Query per-service erasure status for one or more customer IDs | Client-ID (`ADMIN` role) |

## Request/Response Patterns

### POST /customer

Submits erasure requests for the specified customer IDs. If `force=false` (default), IDs that have already been basted are skipped.

**Query parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `customerId` | `string[]` | No | One or more customer UUIDs to erase |
| `isEmea` | `boolean` | No | Indicates whether the request is for the EMEA region |
| `force` | `boolean` | No | If `true`, re-submits erasure even if the customer is already basted |
| `option` | `string` | No | Erasure option: `DEFAULT` (orders erasure) or `ATTENTIVE` (SMS consent erasure) |

**Response:** Returns the same payload as `GET /customer/service` for the submitted customer IDs.

### GET /customer/service

Returns per-service erasure status for the requested customer IDs.

**Query parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `customerId` | `string[]` | No | One or more customer UUIDs to query |

**Response:** JSON array of erasure service records including service name, status, and timestamps.

### Common headers

- `Content-Type: application/json`
- `Accept: application/json`
- Client-ID credentials are passed per the JTier auth bundle convention.

### Error format

> No evidence found in codebase of a standardised error response envelope beyond Dropwizard defaults. Dropwizard returns HTTP 4xx/5xx with a JSON `{"code": ..., "message": "..."}` body on validation and server errors.

### Pagination

> Not applicable — no pagination is implemented. The API accepts a list of customer IDs as query parameters and returns all matching records.

## Rate Limits

> No rate limiting configured.

## Versioning

No API versioning strategy is implemented. The single version of each endpoint is served at the root path. The service version (`1.0.x`) is reflected in the `info.version` field of the OpenAPI specification.

## OpenAPI / Schema References

- `doc/swagger/swagger.yaml` — OpenAPI 2.0 (Swagger) specification
- `doc/swagger/swagger.json` — JSON equivalent of the OpenAPI specification
- `doc/service_discovery/resources.json` — Service discovery resource descriptor
