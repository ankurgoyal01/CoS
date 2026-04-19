---
service: "autocomplete"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

The autocomplete service exposes a small REST API over HTTP. Consumer Apps call the primary autocomplete endpoint to retrieve ranked suggestion cards and deal recommendation cards as the user types. A secondary health check endpoint allows monitoring infrastructure and DataBreakers dependency validation. All responses are synchronous; there is no streaming or WebSocket interface.

## Endpoints

### Autocomplete Suggestions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/suggestions/v1/autocomplete` | Returns ranked suggestion and deal recommendation cards for a given search query | Internal |

### Health Checks

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/healthcheck/client/databreakers` | Validates connectivity and health of the DataBreakers dependency | Internal |

## Request/Response Patterns

### Common headers

> No evidence found in codebase. Standard Dropwizard/JAX-RS headers are expected (e.g., `Content-Type: application/json`, `Accept: application/json`).

### Error format

> No evidence found in codebase. Standard Dropwizard error responses apply — JSON body with `code` and `message` fields.

### Pagination

> Not applicable. The autocomplete endpoint returns a bounded set of suggestion cards per request; no pagination is required.

## Rate Limits

> No rate limiting configured. Rate limiting, if applied, is enforced at the API gateway / load balancer layer outside this service.

## Versioning

The API uses URL path versioning. The autocomplete endpoint is versioned at `/suggestions/v1/`. No v2 path is defined in the current model.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec or proto file is present in the `architecture/` module of this repository.
