---
service: "custom-fields-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

Custom Fields Service exposes a RESTful JSON API versioned under `/v1/`. Consumers use it to create field templates, retrieve localized field definitions (optionally prepopulated with purchaser data), merge multiple field sets, and validate filled-in field values. A separate admin-only deletion endpoint is protected by an API key supplied in the `X-API-KEY` header.

## Endpoints

### Field Templates (Unlocalized)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/field_templates/{uuid}` | Retrieve unlocalized template by UUID | None |

### Fields (Localized)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/fields` | List all field sets with pagination and optional `templateType` filter | None |
| `POST` | `/v1/fields` | Create a new custom field set from a template definition | None |
| `GET` | `/v1/fields/{uuid}` | Retrieve localized field set by UUID, optionally prefilled with purchaser data | None |
| `DELETE` | `/v1/fields/{uuid}` | Delete a custom field template by UUID | `X-API-KEY` header required |
| `POST` | `/v1/fields/{uuid}/validate` | Validate a filled-in field set against the template | None |
| `GET` | `/v1/fields/{uuid}/noop` | No-op health probe endpoint | None |

### Merged Fields

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/merged_fields` | Retrieve and merge multiple field sets by comma-separated `ids` parameter | None |
| `POST` | `/v1/merged_fields/validate` | Validate filled-in fields against a merged field set | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST request bodies
- `X-API-KEY` — required for `DELETE /v1/fields/{uuid}` admin operations
- `X-Request-Id` — forwarded to upstream Users Service calls for tracing

### Query parameters

| Parameter | Endpoints | Description | Default |
|-----------|-----------|-------------|---------|
| `locale` | `GET /v1/fields/{uuid}`, `POST /v1/fields/{uuid}/validate`, `GET /v1/merged_fields`, `POST /v1/merged_fields/validate` | BCP 47 locale for label translation | `en_US` |
| `purchaserId` | `GET /v1/fields/{uuid}`, `GET /v1/merged_fields` | Purchaser UUID for field prefill from Users Service | None |
| `offset` | `GET /v1/fields` | Pagination offset | `0` |
| `limit` | `GET /v1/fields` | Page size (max 50) | `50` |
| `templateType` | `GET /v1/fields` | Filter by `COMMON` or `PRIVATE` template type | None |
| `ids` | `GET /v1/merged_fields`, `POST /v1/merged_fields/validate` | Comma-separated list of `uuid:prefix:quantity` or `uuid:prefix` entries | Required |
| `separator` | `GET /v1/merged_fields`, `POST /v1/merged_fields/validate` | Separator character between prefix and property name | `.` |

### Field types

Fields support the following `type` values: `GROUP`, `TEXT`, `EMAIL`, `PHONE`, `BOOLEAN`, `NUMBER`, `MESSAGE`

### Prepopulation sources

Fields with a `prepopulationSource` are prefilled when `purchaserId` is provided: `firstName`, `lastName`, `email`, `phone`

### Error format

```json
{
  "httpCode": 404,
  "message": "custom field not found"
}
```

Validation errors on `POST /v1/fields/{uuid}/validate` and `POST /v1/merged_fields/validate` return:

```json
{
  "fieldsId": "21e342d8-588d-465f-8c2e-09f47c1edda0",
  "fields": [
    {
      "refersTo": "email",
      "code": "CHECKOUT_FIELD_PATTERN_MISMATCH",
      "message": "The value does not match the required pattern"
    }
  ]
}
```

Validation error codes: `CHECKOUT_FIELD_MUST_BE_TRUE`, `CHECKOUT_FIELD_REQUIRED`, `CHECKOUT_FIELD_PATTERN_MISMATCH`, `CHECKOUT_FIELD_MIN_LENGTH_FAILED`, `CHECKOUT_FIELD_MAX_LENGTH_FAILED`, `CHECKOUT_FIELD_MIN_VALUE_FAILED`, `CHECKOUT_FIELD_MAX_VALUE_FAILED`

### Pagination

`GET /v1/fields` supports offset-based pagination via `offset` (default: 0) and `limit` (default: 50, max: 50) query parameters.

## Rate Limits

> No rate limiting configured.

## Versioning

All endpoints are prefixed with `/v1/`. Version is embedded in the URL path.

## OpenAPI / Schema References

- OpenAPI 2.0 (Swagger) spec: `doc/swagger/swagger.yaml` and `doc/swagger/swagger.json`
- Service discovery resource descriptor: `doc/service_discovery/resources.json`
- Swagger UI published at: `http://custom-fields-staging-vip.snc1/swagger`
