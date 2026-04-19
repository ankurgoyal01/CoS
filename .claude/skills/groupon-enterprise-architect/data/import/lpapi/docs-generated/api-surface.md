---
service: "lpapi"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

LPAPI exposes a REST API over HTTP/HTTPS via the `continuumLpapiApp` Dropwizard/JTier process. It is an internal-only service used by SEO tooling, CMS operators, and automated pipelines to manage landing page records, routes, crosslinks, attribute types, and auto-index configuration. All endpoints share the `/lpapi` path prefix.

## Endpoints

### Attribute Types

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/lpapi/attribute-types` | List all attribute types | Internal |
| POST | `/lpapi/attribute-types` | Create a new attribute type | Internal |
| GET | `/lpapi/attribute-types/{id}` | Retrieve a single attribute type | Internal |
| PUT | `/lpapi/attribute-types/{id}` | Update an attribute type | Internal |
| DELETE | `/lpapi/attribute-types/{id}` | Delete an attribute type | Internal |
| GET | `/lpapi/attribute-types/autocomplete` | Autocomplete search over attribute types | Internal |
| POST | `/lpapi/attribute-types/batch` | Batch create or update attribute types | Internal |

### Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/lpapi/pages` | List landing pages | Internal |
| POST | `/lpapi/pages` | Create a landing page record | Internal |
| GET | `/lpapi/pages/{id}` | Retrieve a landing page | Internal |
| PUT | `/lpapi/pages/{id}` | Update a landing page | Internal |
| DELETE | `/lpapi/pages/{id}` | Delete a landing page | Internal |

### Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/lpapi/routes` | List URL route mappings | Internal |
| POST | `/lpapi/routes` | Create a route mapping | Internal |
| GET | `/lpapi/routes/{id}` | Retrieve a route | Internal |
| PUT | `/lpapi/routes/{id}` | Update a route | Internal |
| DELETE | `/lpapi/routes/{id}` | Delete a route | Internal |

### Crosslinks

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/lpapi/crosslinks` | List crosslink relationships | Internal |
| POST | `/lpapi/crosslinks` | Create a crosslink | Internal |
| GET | `/lpapi/crosslinks/{id}` | Retrieve a crosslink | Internal |
| PUT | `/lpapi/crosslinks/{id}` | Update a crosslink | Internal |
| DELETE | `/lpapi/crosslinks/{id}` | Delete a crosslink | Internal |

### Locations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/lpapi/locations` | List geographic locations | Internal |
| POST | `/lpapi/locations` | Create a location | Internal |
| GET | `/lpapi/locations/{id}` | Retrieve a location | Internal |
| PUT | `/lpapi/locations/{id}` | Update a location | Internal |

### Divisions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/lpapi/divisions` | List divisions | Internal |
| POST | `/lpapi/divisions` | Create a division | Internal |
| GET | `/lpapi/divisions/{id}` | Retrieve a division | Internal |
| PUT | `/lpapi/divisions/{id}` | Update a division | Internal |

### Auto Indexer

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/lpapi/autoindex/config` | Retrieve auto-index configuration | Internal |
| PUT | `/lpapi/autoindex/config` | Update auto-index configuration | Internal |
| GET | `/lpapi/autoindex/jobs` | List auto-index job records | Internal |
| POST | `/lpapi/autoindex/jobs` | Trigger an auto-index job | Internal |
| GET | `/lpapi/autoindex/jobs/{id}` | Retrieve a specific job | Internal |
| GET | `/lpapi/autoindex/results` | List indexability analysis results | Internal |
| GET | `/lpapi/autoindex/results/{id}` | Retrieve a specific analysis result | Internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all write operations
- `Accept: application/json` — expected on all requests

### Error format

Standard Dropwizard JSON error envelope:

```json
{
  "code": 422,
  "message": "Unprocessable Entity",
  "errors": ["field: validation message"]
}
```

### Pagination

> No evidence found for a specific pagination scheme. List endpoints likely support `limit` and `offset` query parameters per Dropwizard conventions.

## Rate Limits

> No rate limiting configured. LPAPI is an internal service with no externally-facing rate limit policies documented.

## Versioning

No URL-based versioning scheme is in use. The service uses a single path prefix `/lpapi`. Breaking changes are coordinated with internal consumers directly.

## OpenAPI / Schema References

> No OpenAPI spec or proto files were found in the federated architecture module. Schema references are managed within the service repository.
