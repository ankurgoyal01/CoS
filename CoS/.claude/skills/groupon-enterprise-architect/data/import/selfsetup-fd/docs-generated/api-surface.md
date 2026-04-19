---
service: "selfsetup-fd"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest, http]
auth_mechanisms: [session]
---

# API Surface

## Overview

selfsetup-fd exposes a small HTTP surface served by the Zend Framework FrontController on Apache (port `8080`). The surface is divided into a JSON API endpoint used by internal UI/integration consumers, a queue processing endpoint, and the main FrontController entry point that handles all UI page requests. The service is employee-internal; no public or partner-facing API is exposed.

## Endpoints

### Opportunity Lookup API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/getopportunity` | Retrieves a Salesforce opportunity and associated merchant details for display and validation in the setup wizard | Session (employee login) |

### Queue Processing

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST/GET | `/queue/*` | Receives and processes queue job actions (enqueue, status, callback) | Session / internal |

### FrontController (UI)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `/` | Zend FrontController entry point; routes all UI wizard requests to the appropriate Zend MVC controller action | Session (employee login) |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for `/api/*` responses
- Session cookie required for authenticated routes

### Error format

> No evidence found of a standardised JSON error envelope in the inventory. Error handling follows Zend Framework default exception rendering.

### Pagination

> Not applicable — opportunity lookup returns a single record per request.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-based or header-based versioning strategy is in use. The single `/api/getopportunity` endpoint is unversioned.

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec, proto file, or GraphQL schema in the repository.
