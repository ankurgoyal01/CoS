---
service: "webhooks-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, webhook]
auth_mechanisms: [hmac-signature]
---

# API Surface

## Overview

The Webhooks Service exposes a minimal HTTP API intended to be called exclusively by GitHub Enterprise webhook delivery. Consumers do not call this service directly — it is configured as a webhook endpoint in GitHub organization or repository settings. The primary endpoint (`/uber`) receives all GitHub event types and dispatches them to the appropriate hook implementations. Two utility endpoints (`/heartbeat`, `/debug`) support health checking and local development.

## Endpoints

### Webhook Receiver

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/uber` | Receives all inbound GitHub webhook events; verifies HMAC-SHA1 signature; dispatches to hook router | HMAC-SHA1 signature in `X-Hub-Signature` header |
| `GET` | `/heartbeat` | Health check endpoint; returns `200 ok`; writes a Steno heartbeat event | None |
| `GET` | `/debug` | Debug utility for local development; exercises GitHub, Jira, Slack, and CI clients; accepts query param overrides for service URLs | None (not exposed in production) |

## Request/Response Patterns

### Common headers

Inbound requests to `/uber` must include the following GitHub-standard headers:

- `X-GitHub-Event` — event type name (e.g., `pull_request`, `status`, `push`)
- `X-GitHub-Delivery` — unique event delivery UUID used for idempotency logging
- `X-Hub-Signature` — HMAC-SHA1 of the request body using the shared webhook secret

### Error format

The service responds with HTTP `200` on successful processing and HTTP `500` if one or more hooks fail during execution. The response body is plain text (`text/plain`). Error details are written to the structured log (Steno format), not returned in the response body.

### Pagination

> Not applicable. This service does not expose paginated endpoints; it is a receiver, not a data API.

## Rate Limits

> No rate limiting configured. The service relies on GitHub Enterprise's delivery rate and the SLA expectation of handling at minimum 1,000 webhook events per hour.

## Versioning

No API versioning strategy is applied. The `/uber` endpoint is a fixed path registered in GitHub organization webhook settings. Configuration changes are deployed without URL version bumps.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema are present. The inbound payload schema is governed by the GitHub Enterprise webhook event specifications (handled via `@octokit/webhooks-types`).
