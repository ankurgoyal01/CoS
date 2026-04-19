---
service: "reporting-service"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, api-key]
---

# API Surface

## Overview

The reporting service exposes a REST API that merchant portal clients and internal tools use to trigger report generation, download completed reports, upload bulk redemption files, query deal cap audit trails, and manage VAT invoices. All endpoints are versioned in the URL path. The service acts as a WAR deployed behind an HTTP load balancer and does not expose gRPC or GraphQL surfaces.

## Endpoints

### Report Generation and Download

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/reports/v1/reports` | Submit a report generation request; returns a report ID | session / api-key |
| GET | `/reports/v1/reports/{id}` | Download a completed report artifact by ID | session / api-key |

### Bulk Redemption

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/bulkredemption/v1/uploadcsvfile` | Upload a CSV file for bulk voucher redemption processing | session / api-key |

### Deal Cap Audit

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/dealcap/v1/audit` | Retrieve deal cap audit log entries | session / api-key |

### VAT Invoicing

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/vat/v1/invoices` | List VAT invoices | session / api-key |
| POST | `/vat/v1/invoices` | Create or trigger a VAT invoice | session / api-key |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for JSON request bodies
- `Content-Type: multipart/form-data` for CSV file uploads (`/bulkredemption/v1/uploadcsvfile`)
- `Accept: application/json` for JSON responses; report download endpoints return binary file content with appropriate MIME type (e.g., `application/vnd.ms-excel`, `text/csv`, `application/pdf`)

### Error format

> No evidence found in the federated architecture model for a standard error response schema. Error format to be confirmed with service owner.

### Pagination

> No evidence found in the federated architecture model for pagination parameters. Confirm with service owner for list endpoints such as `GET /dealcap/v1/audit` and `GET /vat/v1/invoices`.

## Rate Limits

> No rate limiting configured. No rate limit evidence found in the architecture model.

## Versioning

URL path versioning is used throughout. All current endpoints are prefixed with `/v1/` within their respective resource paths (e.g., `/reports/v1/`, `/bulkredemption/v1/`, `/dealcap/v1/`, `/vat/v1/`).

## OpenAPI / Schema References

> Not applicable. No OpenAPI spec, proto files, or GraphQL schema files are present in the federated architecture model. Schema to be sourced from the service repository.
