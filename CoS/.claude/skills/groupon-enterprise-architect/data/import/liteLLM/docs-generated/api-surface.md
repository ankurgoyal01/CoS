---
service: "liteLLM"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

LiteLLM exposes an OpenAI-compatible REST API on port 4000. Internal consumers use it identically to the OpenAI API — the same request/response shapes and header conventions apply. This allows any client that supports the OpenAI SDK to point at LiteLLM without code changes. An admin UI and management API are exposed on port 8081.

## Endpoints

### Inference (OpenAI-Compatible)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/chat/completions` | Submit a chat completion request; routed to configured LLM provider | API key |
| POST | `/completions` | Submit a text completion request | API key |
| GET | `/models` | List available configured models | API key |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health/readiness` | Kubernetes readiness probe — confirms service is ready to accept traffic | None |
| GET | `/health/liveliness` | Kubernetes liveness probe — confirms service process is alive | None |

### Admin

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `/` (port 8081) | Admin UI and management API for model configuration, virtual keys, and spend tracking | Admin key |

## Request/Response Patterns

### Common headers

- `Authorization: Bearer <api-key>` — required for inference endpoints; key validated against LiteLLM virtual key store.
- `Content-Type: application/json` — all request bodies are JSON.

### Error format

LiteLLM follows the OpenAI error response format:

```json
{
  "error": {
    "message": "<description>",
    "type": "<error_type>",
    "code": "<code>"
  }
}
```

HTTP status codes follow OpenAI conventions (400 for client errors, 429 for rate limits, 500/502/503 for upstream or internal errors).

### Pagination

> Not applicable — list endpoints (e.g., `/models`) return all results in a single response. No pagination is used.

## Rate Limits

> No rate limiting configured at the gateway level. Upstream LLM provider rate limits apply and are reflected as 429 responses propagated to callers. The README identifies upstream provider API rate limits as a known bottleneck.

## Versioning

No URL-path or header-based API versioning is used. The LiteLLM version is controlled via the `appVersion` field in `common.yml` and is applied at the container image level.

## OpenAPI / Schema References

> No evidence found in codebase of a committed OpenAPI spec or proto file. The LiteLLM open-source project publishes an OpenAPI spec at [https://github.com/BerriAI/litellm](https://github.com/BerriAI/litellm).
