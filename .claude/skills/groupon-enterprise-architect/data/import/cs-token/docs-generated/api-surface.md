---
service: "cs-token"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, token]
---

# API Surface

## Overview

CS Token Service exposes a REST/JSON API used by CS tooling (Cyclops, AppOps) to create scoped authorization tokens and to verify them before passing to downstream services. All business endpoints are versioned under `/api/v1/:country_code/`. The service also provides health and status endpoints for infrastructure use.

## Endpoints

### Token Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/api/v1/:country_code/token` | Create a new scoped auth token for a customer/agent pair | `X-API-KEY` header (when `api_key_authentication_for_token_creation_enabled` is `true`) |
| `GET` | `/api/v1/:country_code/verify_auth` | Verify an existing token; returns customer and agent identity if valid | Bearer token in `Authorization` header; optional `client_id` param |
| `POST` | `/api/v1/:country_code/token/create_token` | Create a test token with 30-day TTL (gated by `test_enabled` setting) | None (environment-gated) |

### Infrastructure

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/heartbeat.txt` | Load balancer health check; returns `200` when service is alive | None |
| `GET` | `/status` | Service status and Git revision | None |

## Request/Response Patterns

### Common headers

- `Authorization: OAuth <token>` — required on `GET /verify_auth`; the `OAuth` prefix is stripped before Redis lookup
- `X-API-KEY: <key>` — required on `POST /token` when feature flag `api_key_authentication_for_token_creation_enabled` is enabled
- `Content-Type: application/json` — expected on all `POST` requests

### POST /api/v1/:country_code/token — Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `method` | string | yes | Action name scoping the token (e.g., `view_voucher`, `create_order`) |
| `consumer_id` | string | yes | UUID of the customer |
| `customer_email` | string | yes | Email address of the customer (PII class2) |
| `agent_id` | string | yes | ID of the CS agent performing the action |
| `agent_email` | string | yes | Email address of the CS agent |

### POST /api/v1/:country_code/token — Response Body (200)

```json
{
  "token": "<hex-64-char-string>",
  "tokenExpiration": "2026-03-03T12:00:00Z",
  "status": 200,
  "http_code": 200
}
```

### GET /api/v1/:country_code/verify_auth — Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `method` | string | yes | Action the token was issued for |
| `consumer_id` | string | yes | UUID of the customer |
| `client_id` | string | conditional | Required when `client_id_validation_for_tokenizer_enabled` is enabled |

### GET /api/v1/:country_code/verify_auth — Response Body (200)

```json
{
  "accountId": "<consumer_id>",
  "email": "<customer_email>",
  "csAgentId": "<agent_id>",
  "csAgentEmail": "<agent_email>",
  "tokenExpiration": "2026-03-03T12:00:00Z",
  "status": 200,
  "http_code": 200
}
```

### Error format

All errors return JSON with `status` and `http_code` fields:

```json
{ "message": "<error description>", "status": 400, "http_code": 400 }
```

| HTTP Status | Condition |
|-------------|-----------|
| 400 | Missing or invalid request parameters |
| 401 | Invalid or expired token; missing Authorization; invalid X-API-KEY; invalid client_id |
| 503 | Heartbeat file missing (load balancer removes instance from pool) |

### Pagination

> Not applicable — all responses return a single token object.

## Rate Limits

> No rate limiting configured.

## Versioning

URL path versioning: all endpoints use the `/api/v1/` prefix. The `:country_code` segment allows country-scoped routing but does not change the API contract.

## OpenAPI / Schema References

- OpenAPI 2.0 (Swagger) spec: `doc/swagger/swagger.yaml` in the source repository
- Service Discovery spec: `doc/service_discovery/resources.json`
- Published API docs: `https://services.groupondev.com/services/cs-token-service#endpoint_documentation`
