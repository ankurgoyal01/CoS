---
service: "deal-book-service"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, session]
---

# API Surface

## Overview

Deal Book Service exposes a versioned REST API consumed primarily by Deal Wizard and other deal creation tools. The API provides fine print clause recommendations, clause compilation, and persistence of fine print sets. Four API versions are supported (V1 through V4), with progressive refinement of clause retrieval and fine print management capabilities. All responses are JSON.

## Endpoints

### V1 Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/entries` | List fine print entries (V1 compatibility) | API key |
| GET | `/v1/fine_print_clauses` | List fine print clauses for a given geo/taxonomy | API key |
| POST | `/v1/fine_print_clauses` | Create a new fine print clause | API key |
| POST | `/v1/compile` | Compile a set of clause IDs into a single fine print document | API key |
| POST | `/v1/persisted_fine_prints` | Create and persist a fine print set for a deal | API key |

### V2 Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/fine_print_clauses` | List fine print clauses (V2 schema) | API key |
| POST | `/v2/compile` | Compile clauses into fine print (V2 schema) | API key |
| POST | `/v2/persisted_fine_prints` | Create a persisted fine print set | API key |
| PUT | `/v2/persisted_fine_prints/:id` | Update a persisted fine print set | API key |
| DELETE | `/v2/persisted_fine_prints/:id` | Delete a persisted fine print set | API key |

### V3 Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v3/fine_print_clauses` | List fine print clauses (V3 schema) | API key |

### V4 Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v4/fine_print_clauses` | List fine print clauses (V4 schema, latest) | API key |

### Content Version

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/content_version` | Returns the current content version identifier for fine print data | API key |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Service liveness check | None |
| GET | `/heartbeat` | Alternative health check endpoint | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for all request/response bodies
- API key header (specific header name not discoverable from inventory)
- `Accept: application/json`

### Error format

Standard Rails JSON error responses. Specific error envelope shape not discoverable from inventory.

### Pagination

Fine print clause list endpoints support pagination. Pagination parameters follow Rails conventions. Specific parameter names not discoverable from inventory.

## Rate Limits

> No rate limiting configured.

## Versioning

URL path versioning: `/v1/`, `/v2/`, `/v3/`, `/v4/`. Each version may have different request/response schemas for fine print clauses and compilation. V1 and V2 support full CRUD for persisted fine prints; V3 and V4 are clause retrieval only.

## OpenAPI / Schema References

> No evidence found in codebase.
