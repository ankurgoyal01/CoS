---
service: "transporter-itier"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, http-html]
auth_mechanisms: [oauth2, csrf-token, x-grpn-username-header]
---

# API Surface

## Overview

Transporter I-Tier exposes an HTTP server-rendered web application. Most endpoints return `text/html` pages built with Preact. The service is intended exclusively for internal Groupon employees. User identity is established from the `x-grpn-username` header injected by the Hybrid Boundary / Okta proxy. One middleware route (`/jtier-upload-proxy`) accepts a `multipart/form-data` POST and proxies the CSV binary to transporter-jtier over plain HTTP. The full OpenAPI specification is at `doc/openapi.yml`.

## Endpoints

### Page Routes (Server-rendered HTML)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Renders the paginated upload job list (division mapping page) with filter controls | `x-grpn-username` header (Okta) |
| GET | `/new-upload` | Renders the CSV upload form; validates user in jtier first; redirects to Salesforce OAuth if user is not registered | `x-grpn-username` header + jtier user validation |
| GET | `/job-description` | Renders the detail view for a specific upload job | `x-grpn-username` header |
| GET | `/sfdata` | Renders the Salesforce read-only home page with an object type selector | `x-grpn-username` header |
| GET | `/sfdata/{object}/{objectId}` | Renders field-level detail of a specific Salesforce record | `x-grpn-username` header |
| GET | `/oauth2/callback` | Receives Salesforce OAuth2 authorization code; forwards to jtier `/auth` for token exchange; redirects to `/new-upload` on success | None (OAuth2 public callback) |

**Query parameters for `/` and `/page-num`:**

| Parameter | Type | Purpose |
|-----------|------|---------|
| `page` | string | Page number (1-based in the UI; converted to 0-based `pageIndex` when calling jtier) |
| `pageSize` | string | Records per page (default: 10) |
| `action` | string | Filter by Salesforce operation type (insert, update, delete) |
| `object` | string | Filter by Salesforce object name |
| `user` | string | Filter by submitting username |
| `status` | string | Filter by job status |

**Query parameters for `/job-description`:**

| Parameter | Type | Purpose |
|-----------|------|---------|
| `jobId` | string | Unique identifier of the upload job |

**Query parameters for `/oauth2/callback`:**

| Parameter | Type | Purpose |
|-----------|------|---------|
| `code` | string | Salesforce authorization code issued after login |

**Path parameters for `/sfdata/{object}/{objectId}`:**

| Parameter | Type | Purpose |
|-----------|------|---------|
| `object` | string | Salesforce object API name (e.g., `Opportunity`, `Case`) |
| `objectId` | string | Salesforce record ID |

### Data / AJAX Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/page-num` | Returns paginated upload job data as JSON for client-side page updates | `x-grpn-username` header |
| GET | `/get-aws-csv-file` | Retrieves a CSV file (source, success, or error) from S3 via jtier and streams it to the browser | `x-grpn-username` header |
| POST | `/jtier-upload-proxy` | Accepts a multipart CSV upload from the browser and proxies it to `transporter-jtier /v0/upload` | CSRF token |

**Query parameters for `/get-aws-csv-file`:**

| Parameter | Type | Purpose |
|-----------|------|---------|
| `Key` | string | S3 object key of the file to download |

**Form fields for POST `/jtier-upload-proxy` (`multipart/form-data`):**

| Field | Purpose |
|-------|---------|
| `myFile` | CSV file binary content |
| `userName` | Authenticated Groupon username |
| `s3Key` | User-supplied filename / S3 key |
| `object` | Target Salesforce object name |
| `action` | Operation type: `insert`, `update`, or `delete` |
| `batchSize` | Number of records per Salesforce bulk batch |
| `recordsCount` | Total row count parsed client-side by papaparse |

## Request/Response Patterns

### Common headers

- `x-grpn-username`: Injected by Hybrid Boundary / Okta proxy. Read by all modules to identify the current user for jtier calls and audit purposes. Falls back to `test-user` if absent (development mode only).
- `x-csrf-token`: Required on the POST `/jtier-upload-proxy` request. Token is generated server-side and embedded in the upload page HTML.

### Error format

HTML error pages are returned on failures via `itier-error-page`. The `/jtier-upload-proxy` route propagates the upstream jtier HTTP status code and response headers directly to the browser. The `/page-num` endpoint returns JSON on success or propagates jtier error codes on failure.

### Pagination

The `/` and `/page-num` endpoints use query-parameter-based pagination. The UI sends 1-based page numbers; the server converts these to 0-based `pageIndex` values before passing them to jtier's `GET /getUploads` endpoint.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL versioning is applied to the I-Tier web application endpoints. The upstream jtier API is called at the `/v0` path prefix (e.g., `http://transporter-jtier.production.service/v0`).

## OpenAPI / Schema References

- OpenAPI 3.0.0 specification: `doc/openapi.yml` in the repository root
- Contact: sfint-dev@groupon.com
- Production server: `https://transporter-itier.production.service`
- Staging server: `https://transporter-itier.staging.service`
