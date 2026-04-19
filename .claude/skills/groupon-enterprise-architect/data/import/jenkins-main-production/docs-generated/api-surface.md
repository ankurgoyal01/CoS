---
service: "cloud-jenkins-main"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, webhook]
auth_mechanisms: [saml, api-key, crumb-csrf]
---

# API Surface

## Overview

Cloud Jenkins Main exposes the standard Jenkins HTTP API and a small set of plugin-provided webhook endpoints. The primary consumers are engineering pipelines (via the Jenkins UI and CLI), the smoke-test suite, the Metrics plugin, and external webhook senders (GitHub Enterprise push events via the Conveyor Build Plugin). Authentication is enforced via Okta SAML SSO for browser access and per-request API tokens or CRUMB tokens for programmatic access.

## Endpoints

### Health and Metrics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/metrics/<METRICS_KEY>/ping` | Health liveness check — returns `pong` | metrics API key (`/plugins/metrics/token`) |
| `GET` | `/metrics/<METRICS_KEY>/healthcheck` | Deep health check — validates plugins, disk-space, temp-space, thread-deadlock | metrics API key |

### Webhook / Build Trigger

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/ghe-seed/` | Receives GitHub Enterprise push events; seeds or triggers pipeline jobs | `X-Hub-Signature` HMAC header (sha1) + `X-Github-Event` header |

### Standard Jenkins REST API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/json` | Returns controller status and job list | Session / API token |
| `POST` | `/job/<folder>/<job>/build` | Triggers a build | Session + CRUMB or API token |
| `GET` | `/job/<folder>/<job>/<build>/api/json` | Returns build status and metadata | Session / API token |
| `GET` | `/computer/api/json` | Lists all nodes and their status | Session / API token |

## Request/Response Patterns

### Common headers

- `X-Github-Event`: required for the `/ghe-seed/` webhook endpoint to identify the event type.
- `X-Hub-Signature`: HMAC-SHA1 signature for webhook payload verification (credential id `githubapp-secret`).
- `Content-Type: application/json`: required for all JSON payloads.

### Error format

> No evidence found in codebase. Jenkins uses its standard HTML error pages and JSON error responses from the REST API (`{"_class":"...","message":"...","url":"..."}`).

### Pagination

> No evidence found in codebase. Jenkins REST API uses `tree` query parameter for field selection; pagination is not formally defined.

## Rate Limits

> No rate limiting configured. The Jenkins metrics endpoint restricts access by API key but does not define explicit rate limits.

## Versioning

No API versioning strategy is applied. The Jenkins REST API is unversioned; compatibility follows the Jenkins controller version.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema are present. Webhook payload schema is documented via `smoke-tests/resources/push.json` (sample GitHub push event payload).
