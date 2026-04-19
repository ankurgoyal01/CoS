---
service: "transporter-jtier"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [oauth2, salesforce-token]
---

# API Surface

## Overview

Transporter JTier exposes a REST API consumed exclusively by `transporter-itier`. The API handles Salesforce user authentication, CSV upload submission, upload job status queries, and Salesforce object enumeration. All endpoints are prefixed with `/v0/`. The service runs on port `8080` (HTTP) with an admin port on `8081`.

The OpenAPI specification is located at `doc/swagger/swagger.yaml` in the repository.

## Endpoints

### Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v0/auth` | Exchange Salesforce auth code from connected app to obtain access token | None (presents auth code) |
| `GET` | `/v0/userInfo` | Check if user exists and validate whether the Salesforce access token is valid | Salesforce token |
| `GET` | `/v0/validUser` | Check if user exists and validate whether the Salesforce access token is valid | Salesforce token |

### File Access

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v0/getAWSFile` | Retrieve a CSV file from the configured AWS S3 bucket | Salesforce token |

### Salesforce Object Discovery

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v0/sfObjects` | Return a list of available Salesforce objects for the read-only Transporter UI page | Salesforce token |
| `GET` | `/v0/getSfObject` | Return a JSON representation of a specific Salesforce object | Salesforce token |

### Upload Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v0/upload` | Submit a CSV upload job for bulk Salesforce processing | Salesforce token |
| `GET` | `/v0/getUploads` | Retrieve the list of all upload jobs | Salesforce token |
| `GET` | `/v0/getUploadsById` | Retrieve a single upload job record by ID | Salesforce token |

### Service Root

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/` | Root endpoint; returns plain text response | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for JSON responses
- `Content-Type: text/csv` for `POST /v0/upload` request body

### Error format

> No evidence found in codebase. Standard Dropwizard error responses are used (JSON envelope with `code` and `message` fields per JAX-RS defaults).

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

All endpoints are versioned under the `/v0/` path prefix. There is no header- or query-param-based versioning in evidence.

## OpenAPI / Schema References

OpenAPI 2.0 (Swagger) specification: `doc/swagger/swagger.yaml` in the repository root.
Config: `doc/swagger/config.yml` — resource scanner targets `com.groupon.salesforce.transporter_jtier.resources`.
