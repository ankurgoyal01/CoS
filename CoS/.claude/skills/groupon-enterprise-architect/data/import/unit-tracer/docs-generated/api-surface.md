---
service: "unit-tracer"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: []
---

# API Surface

## Overview

Unit Tracer exposes three HTTP endpoints on port 8080. Two endpoints are user-facing: a browser-rendered HTML report endpoint and a JSON API endpoint. One endpoint serves the landing page. All endpoints accept unit identifiers (UUID or Groupon code) as a `unitIds` query parameter. The service does not enforce authentication at the resource level; access control is expected at the network or infrastructure layer. An admin port (8081) is exposed for Dropwizard administrative operations and health checks.

The OpenAPI specification is available at `doc/swagger/swagger.yaml` in the repository.

## Endpoints

### Landing Page

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/` | Returns the Unit Tracer landing HTML view (`UnitTracerView`) | None |

### HTML Report

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/unit` | Accepts one or more unit IDs (comma-separated UUIDs or Groupon codes); returns an HTML rendered report (`ReportsView` via Mustache template) | None |

**Query parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `unitIds` | string | Yes (`@NotEmpty`) | Comma-separated list of unit UUIDs or Groupon codes (prefixes: `LG`, `TP`, `VS`, `GL`). Whitespace is stripped. |

**Response:** `200 OK` with `text/html` body containing the aggregated `ReportsView`. The view includes:
- `reports` — list of `UnitReport` objects (one per requested unit ID)
- `unitsWithSuccessfulCaptureMessage` — UUIDs with a successful ledger capture message
- `unitsWithoutCaptureMessage` — UUIDs with no capture message found
- `unitsWithoutMessage2LedgerData` — UUIDs with no message-to-ledger data at all
- `unitsWithoutSuccessfulCaptureMessage` — UUIDs lacking a successful capture message

### JSON API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/unit` | Accepts one or more unit IDs; returns the same aggregated report data serialized as JSON | None |

**Query parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `unitIds` | string | No | Comma-separated list of unit UUIDs or Groupon codes. Whitespace is stripped. |

**Response:** `200 OK` with `application/json` body (Jackson serialization with ISO 8601 date format). On serialization error, returns `200 OK` with the exception message as plain text.

## Request/Response Patterns

### Common headers

- No custom request headers are required.
- `Content-Type: application/json` is set on the JSON API response by the resource manually.

### Error format

Errors encountered during report building are captured in the `UnitReport.errors` array as `ErrorLog` objects:

```json
{
  "step": "<step name, e.g. 'Inventory Service', 'Accounting Service', 'Message2Ledger'>",
  "message": "<error description>"
}
```

No HTTP error codes are returned for failed upstream calls; errors are embedded in the report body. If the `unitIds` parameter is empty or missing on `GET /unit`, a `@NotEmpty` constraint violation is returned by Dropwizard.

### Pagination

> No rate limiting configured.

Batch requests are supported by supplying multiple unit IDs as a comma-separated string in `unitIds`. There is no server-side pagination of report results.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-level API versioning is applied. The service is at version `1.0.x` (controlled by `pom.xml` `<major-minor>1.0</major-minor>`). The JSON API path `/api/unit` is not versioned.

## OpenAPI / Schema References

- Swagger 2.0 spec: `doc/swagger/swagger.yaml`
- Swagger config: `doc/swagger/config.yml`
