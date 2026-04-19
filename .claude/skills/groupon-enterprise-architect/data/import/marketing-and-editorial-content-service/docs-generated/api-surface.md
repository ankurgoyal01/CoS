---
service: "marketing-and-editorial-content-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

MECS exposes a JSON REST API under the `/mecs` base path on HTTP port 8080. All resource endpoints require ClientId authentication (a Groupon-internal API key mechanism). Internal consumers use the API to manage editorial content records — images, text blocks, and tags — that feed marketing and merchandising workflows. CORS is enabled for all origins to support browser-based tools such as Merch UI.

## Endpoints

### Image Content (`/mecs/image`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mecs/image` | Search and return a collection of image records (with pagination and filters) | ClientId |
| GET | `/mecs/image/{uuid}` | Retrieve a single image record by UUID | ClientId |
| POST | `/mecs/image` | Create (upload) a new image; accepts multipart/form-data with image file and JSON content field | ClientId |
| PUT | `/mecs/image` | Replace an existing image record by UUID (full update) | ClientId |
| DELETE | `/mecs/image/{uuid}` | Delete an image record by UUID; requires `username` query parameter for audit | ClientId |
| PATCH | `/mecs/image/{uuid}` | Apply JSON Patch (RFC 6902) operations to a single image record; supports `dryRun` query parameter | ClientId |
| PATCH | `/mecs/image` | Apply JSON Patch operations to a collection of images identified by UUID list; supports `dryRun` | ClientId |

### Text Content (`/mecs/text`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mecs/text` | Search and return a collection of text content records (with pagination and filters) | ClientId |
| GET | `/mecs/text/{uuid}` | Retrieve a single text content record by UUID | ClientId |
| POST | `/mecs/text` | Create a new text content record; profanity check is applied before save | ClientId |
| PUT | `/mecs/text` | Replace an existing text content record by UUID (full update); profanity check applied | ClientId |
| DELETE | `/mecs/text/{uuid}` | Delete a text content record by UUID; requires `username` query parameter for audit | ClientId |
| PATCH | `/mecs/text/{uuid}` | Apply JSON Patch operations to a single text record; supports `dryRun` | ClientId |
| PATCH | `/mecs/text` | Apply JSON Patch operations to a collection of text records; supports `dryRun` | ClientId |

### Tags (`/mecs/tag`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mecs/tag` | List all available content classification tags | ClientId |

### Enums (`/mecs/enum`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mecs/enum/{type}` | Return the valid string values for a given enum type | ClientId |

Supported `{type}` values: `PROJECT`, `LOCALE`, `IMAGE_TYPE`, `AUDIT_ACTION`, `LOCATION_TYPE`, `TEXT_COMPONENT`, `TEXT_CONTENT_TYPE`, `ORDER_BY`

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for JSON endpoints
- `Content-Type: multipart/form-data` — required for `POST /mecs/image`
- `clientId` — query parameter carrying the API key credential (or `adminId` for admin operations)

### Error format

Standard Dropwizard `ErrorMessage` JSON object:

```json
{
  "code": 404,
  "message": "No image found with UUID: ..."
}
```

HTTP status codes returned:
- `200 OK` — successful GET or PATCH (returns entity)
- `201 Created` — successful POST; `Location` header contains URI of new resource
- `204 No Content` — successful PUT
- `400 Bad Request` — constraint violation
- `401 Unauthorized` — missing or invalid ClientId
- `403 Forbidden` — ClientId lacks required permission
- `404 Not Found` — resource not found by UUID
- `422 Unprocessable Entity` — validation failure or profanity detected
- `500 Internal Server Error` — unexpected server error

### Pagination

Search endpoints accept pagination parameters via `PaginationParam` bean:
- `limit` — maximum number of records to return
- `offset` — record offset for paging

### Field filtering

Search and get endpoints support a `show` query parameter (a comma-separated set of field names) that limits which JSON fields are included in responses, implemented via `JacksonResponseFilter`.

## Rate Limits

> No rate limiting configured. Access is controlled by ClientId authentication only.

## Versioning

No URL-based API versioning. The API is unversioned; the base path `/mecs` is stable.

## OpenAPI / Schema References

A ReDoc UI is served at `/redoc/index.html` via an AssetsBundle. Swagger annotations are present on all resources (`io.swagger.annotations`) and generate an OpenAPI spec accessible through the Dropwizard Swagger integration.
