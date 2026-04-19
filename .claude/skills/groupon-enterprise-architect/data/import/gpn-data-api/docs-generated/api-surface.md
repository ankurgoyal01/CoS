---
service: "gpn-data-api"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-network]
---

# API Surface

## Overview

GPN Data API exposes a single REST resource group under `/attribution/orders`. Consumers submit order identifiers and a date range to retrieve marketing attribution records from Google BigQuery. The API supports three response formats: JSON list, paginated JSON, and CSV download. All endpoints use HTTP POST with a JSON request body.

## Endpoints

### Attribution Orders

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/attribution/orders` | Retrieve full attribution details for one or more orders | Internal network |
| `POST` | `/attribution/orders/paginated` | Retrieve attribution details with cursor-based pagination | Internal network |
| `POST` | `/attribution/orders/csv` | Download attribution details as a CSV file | Internal network |

#### `POST /attribution/orders`

Returns all attribution detail records matching the supplied order identifiers and date window. Results are returned as a JSON array without pagination.

**Request body** (`application/json`):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `orderIdType` | string (enum) | Yes | Identifier type: `LEGACY_ID`, `SUPPORT_ID`, or `PROMO_CODE` |
| `orderIds` | array of string | Yes | List of order identifiers matching the selected type |
| `fromDate` | string | Yes | Start of date window (inclusive), format `YYYY-MM-DD` |
| `toDate` | string | Yes | End of date window (inclusive), format `YYYY-MM-DD` |

**Response** (`application/json`): Array of attribution detail objects.

#### `POST /attribution/orders/paginated`

Returns attribution detail records page by page using a BigQuery job token. Supports re-using an existing BigQuery job to iterate pages without re-running the query.

**Request body** (`application/json`):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `orderIdType` | string (enum) | Yes | `LEGACY_ID`, `SUPPORT_ID`, or `PROMO_CODE` |
| `orderIds` | array of string | Yes | Order identifiers matching the selected type |
| `fromDate` | string | Yes | Start date, format `YYYY-MM-DD` |
| `toDate` | string | Yes | End date, format `YYYY-MM-DD` |
| `pagination.pageSize` | integer | No | Page size; range 1–1000; defaults to 100 |
| `pagination.pageToken` | string | No | Token for the next page (returned by previous response) |
| `pagination.jobId` | string | No | BigQuery job ID to reuse (avoids re-running the query) |

**Response** (`application/json`): Paginated wrapper with `data`, `nextPageToken`, `totalCount`, `hasNextPage`, `pageSize`.

#### `POST /attribution/orders/csv`

Returns the same data as `POST /attribution/orders` but serialized as `text/csv`. Produces a flat key-value CSV with all attribution fields as columns.

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all POST requests
- `Accept: application/json` or `Accept: text/csv` — for the CSV endpoint

### Error format

Errors use standard Dropwizard JAX-RS error responses:

| HTTP Status | Condition |
|-------------|-----------|
| `200 OK` | Successful response with data (may be empty array) |
| `429 Too Many Requests` | Daily query limit exceeded (`MaximumQueryLimitReachedException`) |
| `500 Internal Server Error` | BigQuery error or unexpected exception |

The `429` response body contains a plain-text message: `"Maximum Query Limit reached for the user"`.

### Pagination

The paginated endpoint (`/attribution/orders/paginated`) uses cursor-based pagination backed by BigQuery job tokens:

1. First request: omit `pagination.pageToken` and `pagination.jobId`. The service creates a new BigQuery job and returns `nextPageToken` and `jobId` in the response.
2. Subsequent pages: supply both `pagination.pageToken` and `pagination.jobId` to reuse the existing query job and advance the cursor.
3. `hasNextPage: false` indicates the last page.

Default page size is 100 rows. Maximum page size is 1,000 rows.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| Global (all callers combined) | Configurable via `attribution_properties` table (`attribution_teradata` key) | Per calendar day |

The daily limit is read from the MySQL `attribution_properties` table at runtime. When the limit is exceeded the service returns HTTP 429.

## Versioning

No URL versioning. The API is currently at version `1.0` as declared in `pom.xml`. No API version header is required or enforced.

## OpenAPI / Schema References

OpenAPI 2.0 (Swagger) specification: `doc/swagger/swagger.yaml`

Swagger UI config: `doc/swagger/config.yml`
