---
service: "mergebot"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, webhook]
auth_mechanisms: [hmac-sha256-webhook-signature]
---

# API Surface

## Overview

Mergebot exposes two HTTP endpoints. The primary endpoint receives inbound GitHub webhook events (POST) and is protected by HMAC-SHA256 signature verification. The secondary endpoint is a health check used by the Kubernetes liveness/readiness probe. Mergebot does not expose a public or developer-facing REST API — all calls are initiated by GitHub Enterprise.

## Endpoints

### Webhook Events

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/events/issue_comments` | Receives GitHub `issue_comment` and `pull_request_review` webhook events; validates signature and dispatches merge processing | HMAC-SHA256 via `X-Hub-Signature-256` header and `WEBHOOK_SECRET` env var |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/heartbeat` | Health check; returns `"ok ok ok"` as JSON | None |

## Request/Response Patterns

### Common headers

- `X-Hub-Signature-256`: Required on all webhook POSTs. Format: `sha256=<hex>`. Computed by GitHub using the shared `WEBHOOK_SECRET`. Mergebot verifies this with `OpenSSL::HMAC.hexdigest` and `Rack::Utils.secure_compare` before processing any payload.
- `X-GitHub-Event`: GitHub event type header. Mergebot ignores `ping` events and processes all others.

### Webhook payload structure

The POST body is a GitHub webhook JSON payload. Key fields consumed by Mergebot:

| Field | Purpose |
|-------|---------|
| `repository.full_name` | Identifies the repository (`org/repo`) |
| `issue.number` / `pull_request.number` | PR number |
| `comment.body` / `review.body` | Comment or review text evaluated against ship/block word lists |
| `comment.user.id` / `review.user.id` | Commenter identity for uniqueness checks |
| `issue.pull_request.html_url` | Distinguishes PR issues from plain issues |

### Error format

- `403 Forbidden` — returned when the `X-Hub-Signature-256` signature does not match.
- `200 OK` with body `"ok"` — returned for all successfully processed webhook payloads (regardless of merge outcome). Merge failures are communicated via Slack, not HTTP response codes.

### Pagination

> Not applicable. Mergebot receives single-event webhook POSTs. Outbound GitHub API calls use `Octokit` with `auto_paginate: true` to transparently handle pagination of comments, commits, and reviews.

## Rate Limits

> No rate limiting configured on Mergebot's own endpoints. Mergebot is subject to GitHub Enterprise API rate limits for outbound calls made with the `ci` user's `GITHUB_TOKEN`.

## Versioning

No API versioning strategy. The `/api/events/issue_comments` path has been stable; breaking changes would require coordinating GitHub App webhook reconfiguration.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI, proto, or GraphQL schema files are present. The webhook payload schema is defined by GitHub Enterprise.
