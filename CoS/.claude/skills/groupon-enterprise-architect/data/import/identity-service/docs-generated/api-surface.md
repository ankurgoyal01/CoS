---
service: "identity-service"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [jwt]
---

# API Surface

## Overview

identity-service exposes a versioned REST API under the `/v1/identities` prefix. Consumers use it to create, retrieve, update, and erase user identity records. All mutation endpoints require Bearer JWT authentication. Health and status endpoints are unauthenticated. The API is the primary synchronous interface to the service; all async interactions are handled via the Message Bus.

## Endpoints

### Identity Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/identities` | List identities (with filtering) | Bearer JWT |
| POST | `/v1/identities` | Create a new identity record | Bearer JWT |
| GET | `/v1/identities/{uuid}` | Retrieve a single identity by UUID | Bearer JWT |
| PUT | `/v1/identities/{uuid}` | Update an existing identity by UUID | Bearer JWT |
| POST | `/v1/identities/erasure` | Initiate GDPR erasure for an identity | Bearer JWT |

### Health and Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/heartbeat` | Liveness probe — confirms process is running | None |
| GET | `/status` | Readiness/status check — may include dependency health | None |

## Request/Response Patterns

### Common headers

- `Authorization: Bearer <jwt>` — required on all `/v1/identities` endpoints
- `Content-Type: application/json` — required for POST and PUT request bodies
- `Accept: application/json` — standard for all requests

### Error format

Errors follow standard HTTP status codes with a JSON body. The exact error schema is defined by the Sinatra application layer. Common error codes:
- `400 Bad Request` — invalid parameters or missing required fields
- `401 Unauthorized` — missing or invalid Bearer JWT
- `404 Not Found` — identity UUID does not exist
- `422 Unprocessable Entity` — business rule validation failure
- `429 Too Many Requests` — rate limit exceeded (rack-attack)

### Pagination

> No evidence found of a specific pagination scheme. List operations at `GET /v1/identities` may support query parameter filtering; pagination strategy to be confirmed by the service owner.

## Rate Limits

rack-attack is configured to throttle and block abusive request patterns. Specific rate limit tiers and thresholds are managed in the rack-attack configuration and are not documented in the inventory.

| Tier | Limit | Window |
|------|-------|--------|
| Default (rack-attack) | To be confirmed | To be confirmed |

## Versioning

The API uses URL path versioning. All identity management endpoints are under the `/v1/` prefix. No v2 endpoints are documented in the inventory.

## OpenAPI / Schema References

> No OpenAPI spec file is documented in the inventory for this service. Contact the Identity / Account Management team for the current schema definition.
