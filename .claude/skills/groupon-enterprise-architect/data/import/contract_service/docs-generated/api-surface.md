---
service: "contract_service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [none-documented]
---

# API Surface

## Overview

Contract Service exposes a versioned REST JSON API under the `/v1` path prefix. All endpoints accept and return `application/json`. The API covers two resource groups: **contract definitions** (templates and schemas) and **contracts** (instantiated, optionally-signed agreements). Consumers include the merchant self-service engine and the CLO campaign service. The service also exposes health and heartbeat endpoints for infrastructure monitoring.

## Endpoints

### Health and Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/status.json` | Returns service status (OK), current time, and deployed SHA | None |
| GET | `/heartbeat` | Returns heartbeat file contents; 404 if file absent | None |

### Contract Definitions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/contract_definitions.json` | Returns list of all contract definitions with schemas and templates | None documented |
| GET | `/v1/contract_definitions/{id}.json` | Returns a specific contract definition by UUID or name (optionally filtered by `?version=`) | None documented |
| POST | `/v1/contract_definitions` | Creates a new contract definition with locale, name, schema, sample data, and templates | None documented |
| DELETE | `/v1/contract_definitions/{id}` | Deletes a contract definition (blocked if contracts reference it) | None documented |
| GET | `/v1/contract_definitions/{id}/example` | Renders an example contract using the definition's `sample_data`; supports `.json`, `.html`, `.pdf`, `.txt` formats | None documented |

### Contracts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/contracts?salesforce_id={sfid}` | Searches for a contract by Salesforce opportunity ID (converts 15-char IDs to 18-char) | None documented |
| GET | `/v1/contracts/{id}.json` | Returns contract data including user_data, version history, signature, and definition reference | None documented |
| GET | `/v1/contracts/{id}.html` | Renders the contract as HTML using the definition's HTML template | None documented |
| GET | `/v1/contracts/{id}.pdf` | Renders the contract as PDF via PDFKit (falls back to HTML template if no PDF template) | None documented |
| GET | `/v1/contracts/{id}.txt` | Renders the contract as plain text (uses txt template or strips HTML) | None documented |
| POST | `/v1/contracts` | Creates a new contract from `user_data`, `contract_definition` UUID, and optional Salesforce ID | None documented |
| PUT | `/v1/contracts/{id}` | Updates `user_data` on an existing unsigned contract; bumps version history | None documented |
| DELETE | `/v1/contracts/{id}` | Deletes an unsigned contract | None documented |
| POST | `/v1/contracts/{id}/sign` | Signs a contract using an identity object (acceptance or electronic); captures IP address | None documented |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for POST/PUT request bodies
- `X-Request-Id` propagated via `sonoma-request-id` middleware for distributed tracing

### Error format

Errors are returned as standard Rails JSON error hashes with HTTP status codes:
- `422 Unprocessable Entity` — validation failures (e.g., schema mismatch, duplicate signature, attempt to modify signed contract)
- `400 Bad Request` — missing required query parameters (e.g., `salesforce_id` absent on index)
- `404 Not Found` — resource not found by UUID or name

### Pagination

> No evidence found in codebase. The index endpoints return full collections without pagination.

## Rate Limits

> No rate limiting configured.

## Versioning

URL path versioning. All business endpoints are prefixed with `/v1/`. The health endpoints (`/status.json`, `/heartbeat`) are unversioned.

Contract definitions themselves carry an integer `version` field that auto-increments on each new definition with the same `name`. Lookup supports `?version=` to retrieve a specific version.

## OpenAPI / Schema References

A Swagger schema is referenced at `doc/swagger/swagger.json` (path within the repo) and published at `https://services.groupondev.com/services/cicero/open_api_schemas/latest`. A service-discovery annotation format is embedded in controller comments and can be converted via the `schema_generator` / `convert_to_swagger` toolchain referenced in the README.
