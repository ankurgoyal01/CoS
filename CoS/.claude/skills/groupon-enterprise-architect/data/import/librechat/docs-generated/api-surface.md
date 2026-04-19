---
service: "librechat"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, websocket]
auth_mechanisms: [oidc, session]
---

# API Surface

## Overview

LibreChat exposes an HTTP API via the `appApiServer` component (Node.js/Express) on port 3080. The API serves both the browser-based React frontend and internal service-to-service calls. Authentication is enforced via Okta OIDC (OpenID Connect) with session-based token reuse. The RAG API exposes a separate HTTP endpoint on port 8000 for retrieval requests originating from the App server.

## Endpoints

### App Server (port 3080)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Liveness and readiness probe | None |
| GET | `/oauth/openid/callback` | OIDC callback URL for Okta SSO login | None (callback) |
| POST | `/api/ask` | Submit a chat prompt to the configured LLM endpoint | OIDC session |
| GET | `/api/convos` | List conversation history for the authenticated user | OIDC session |
| POST | `/api/convos` | Create or update a conversation | OIDC session |
| GET | `/api/search` | Full-text search over indexed content via Meilisearch | OIDC session |
| GET | `/api/user` | Retrieve current user profile | OIDC session |

> The above endpoint paths are inferred from LibreChat's standard open-source routing conventions combined with the configuration evidence (`OPENID_CALLBACK_URL: /oauth/openid/callback`, health probe at `/health`). Exact internal route definitions are in the upstream LibreChat source and were not directly inspectable in this import.

### RAG API (port 8000)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Liveness and readiness probe | None |
| POST | `/query` | Accept a retrieval request from the App server and return context | Internal network (network policy enforced) |

> The RAG API is not publicly exposed. Network policy restricts ingress to pods matching the `librechat` app label only.

### Meilisearch (port 7700)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Liveness and readiness probe | None |
| POST | `/indexes/{index}/search` | Execute full-text search query | Internal network |

> No evidence found in codebase of a public-facing Meilisearch API. Network policy restricts ingress to the librechat app component only.

## Request/Response Patterns

### Common headers
- `Content-Type: application/json` for all JSON API calls
- Session cookie used for auth token continuity (`OPENID_REUSE_TOKENS: "true"`)

### Error format
> No evidence found in codebase of a custom error response schema. LibreChat standard error responses are JSON objects following Express default conventions.

### Pagination
> No evidence found in codebase of a specific pagination scheme documented in deployment configuration.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| Login | 10000 attempts | Configurable (env var `LOGIN_MAX`) |

> Application-level rate limiting beyond `LOGIN_MAX` is not configured in the discovered deployment manifests.

## Versioning

LibreChat application versioning follows an app version tag (`--set appVersion="v0.7.8"` in deploy script). The `librechat.yaml` config references `version: 1.0.8`. No URL-path API versioning prefix is configured.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema were found in this repository. The upstream LibreChat open-source project documentation would be the reference for the full API schema.
