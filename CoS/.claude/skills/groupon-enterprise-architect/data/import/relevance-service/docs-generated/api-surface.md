---
service: "relevance-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth]
---

# API Surface

## Overview

The Relevance API (RAPI) serves as the primary search and browse aggregation gateway for the Continuum Platform. Consumer-facing applications and the API Proxy call RAPI to execute search queries, browse categories, and retrieve relevance-ranked deal results. The API follows synchronous REST patterns and returns JSON responses with ranked deal listings.

## Endpoints

### Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/search` | Execute a search query and return relevance-ranked deal results | Internal service auth |
| GET | `/browse` | Browse deals by category with relevance ranking applied | Internal service auth |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Service health check endpoint | None |

> Exact endpoint paths and parameters are derived from the service's role as a search aggregation API. See the source repository for the complete OpenAPI specification.

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` -- all responses are JSON
- `X-Request-Id` -- correlation ID for distributed tracing
- Standard Groupon internal service authentication headers

### Error format

Errors follow the standard Continuum error response shape with an error code, message, and optional detail fields:

```json
{
  "error": {
    "code": "SEARCH_ERROR",
    "message": "Description of the failure",
    "details": {}
  }
}
```

### Pagination

Search and browse results support offset-based pagination with `offset` and `limit` query parameters. Default page size is determined by the calling context.

## Rate Limits

No explicit rate limiting is configured at the RAPI layer. Rate limiting is enforced upstream at the API Proxy / API gateway level.

## Versioning

API versioning is managed via URL path prefix (e.g., `/v1/search`). The exact versioning strategy is defined in the source repository.

## OpenAPI / Schema References

The OpenAPI specification, if available, resides in the source repository. Refer to the `relevance-service` source codebase for contract definitions.
