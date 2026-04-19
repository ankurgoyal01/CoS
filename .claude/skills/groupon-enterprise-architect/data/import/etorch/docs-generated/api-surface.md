---
service: "etorch"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

eTorch exposes a synchronous REST API over HTTP/HTTPS. The API is split into two versioned namespaces: the `/getaways/v2/extranet` namespace serves merchant-facing hotel management operations (accounting, contacts, reference data), and the `/v1/getaways/extranet/jobs` namespace provides a job trigger endpoint used internally for batch deal updates. All endpoints are generated with Swagger for discoverability.

## Endpoints

### Accounting

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/getaways/v2/extranet/hotels/{uuid}/accounting/statements` | Retrieve accounting statements for a hotel | API key |
| GET | `/getaways/v2/extranet/hotels/{uuid}/accounting/payments` | Retrieve payment records for a hotel | API key |

### Reference Data

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/getaways/v2/extranet/cities` | List supported cities | API key |
| GET | `/getaways/v2/extranet/countries` | List supported countries | API key |
| GET | `/getaways/v2/extranet/channel_managers` | List registered channel managers | API key |

### Contacts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/getaways/v2/extranet/contacts` | List hotel contacts | API key |
| POST | `/getaways/v2/extranet/contacts` | Create a new hotel contact | API key |
| GET | `/getaways/v2/extranet/contact_roles` | List available contact roles | API key |

### Inventory Updates

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/getaways/v2/extranet/recent_auto_updates` | Retrieve recent automatic inventory updates for a hotel | API key |

### Job Trigger

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/getaways/extranet/jobs/deal_update` | Trigger a deal update batch job | Internal / API key |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all POST/PUT requests
- `Accept: application/json` — expected on all requests
- Authorization header carrying API key credentials

### Error format

Errors follow a standard JSON envelope. HTTP status codes are used semantically (400 for bad input, 401/403 for auth failures, 404 for unknown hotel UUID, 500 for internal errors). Swagger-generated documentation provides the full response schema.

### Pagination

> No evidence found for a standardized pagination mechanism. Individual listing endpoints may return full collections.

## Rate Limits

> No rate limiting configured.

## Versioning

URL path versioning is used. The primary merchant-facing API is versioned under `/getaways/v2/extranet/`. The job endpoint uses the `/v1/` prefix under `/v1/getaways/extranet/jobs/`. Both versions are maintained concurrently.

## OpenAPI / Schema References

Swagger is included as a dependency and generates an OpenAPI specification at runtime. The spec is available via the running service's Swagger UI endpoint.
