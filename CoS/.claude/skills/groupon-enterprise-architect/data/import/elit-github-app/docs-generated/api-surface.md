---
service: "elit-github-app"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [hmac-sha256-webhook-signature, github-app-jwt]
---

# API Surface

## Overview

The ELIT GitHub App exposes a single inbound HTTP endpoint that receives webhook event payloads from GitHub Enterprise. The endpoint is not a general-purpose public API — it is exclusively called by GitHub's webhook delivery mechanism. All inbound requests must carry a valid HMAC-SHA256 signature in the `X-Hub-Signature-256` header. The service does not expose any read endpoints for external consumers.

## Endpoints

### Webhook Receiver

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/elit-github-app/webhook` | Receives GitHub App webhook events (check suite and check run lifecycle events) | HMAC-SHA256 webhook signature (`X-Hub-Signature-256`) |

### Admin / Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/status` | JTier standard health and status endpoint (reports `commitId`) | None (internal) |

## Request/Response Patterns

### Common headers

- `X-Hub-Signature-256` — HMAC-SHA256 signature of the request body, computed using the configured webhook secret. Required on all calls to `/elit-github-app/webhook`. The `MessageAuthenticationFilter` rejects requests without a valid signature with HTTP 401.
- `X-GitHub-Event` — Event type header sent by GitHub (e.g., `check_suite`, `check_run`). Processed by the action handler to route the event.
- `Content-Type: application/json` — All webhook payloads from GitHub are JSON.

### Development override

In development mode (`github.development: true`), requests with the header `x-override-auth: true` bypass signature validation. This is explicitly disabled in production.

### Webhook payload shape

The root payload model is `GitHubAction`, which contains:

| Field | Type | Description |
|-------|------|-------------|
| `action` | string | Event action type (e.g., `requested`, `rerequested`, `created`) |
| `installation` | object | GitHub App installation context (`id`) |
| `sender` | object | GitHub user who triggered the event (`id`, `login`) |
| `check_suite` | object | Present on check suite events; contains `app`, `head_sha`, `id`, `pull_requests` |
| `check_run` | object | Present on check run events; same structure as `check_suite` |
| `repository` | object | Repository context (`id`, `name`, `url`, `commits_url`) |
| `pull_request` | object | PR context when applicable (`id`, `number`, `state`, `title`, `url`, `merge_commit_sha`) |
| `comment` | object | Comment context when applicable (`id`, `body`, `user`) |
| `issue` | object | Issue context when applicable (`id`, `number`, `title`) |

### Error format

- HTTP 401 — Returned by `MessageAuthenticationFilter` when the webhook signature is missing or invalid.
- HTTP 500 — Returned by `GitHubAppResource` when an unhandled exception occurs during event processing. The response body is `{"message": "Error processing request"}`.

### Pagination

> Not applicable — The webhook endpoint accepts a single event payload per request.

## Rate Limits

> No rate limiting configured on the inbound webhook endpoint.

## Versioning

No explicit API versioning strategy. The endpoint path `/elit-github-app/webhook` has remained constant. GitHub's webhook retry mechanism handles transient failures.

## OpenAPI / Schema References

- Swagger 2.0 spec: `doc/swagger/swagger.yaml` (generated from source)
- OpenAPI 3 source spec: `src/main/resources/openapi3.yml` (used at build time for model generation via `swagger-codegen-maven-plugin`)
