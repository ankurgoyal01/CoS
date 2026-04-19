---
service: "gdpr"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, agent-id-validation]
---

# API Surface

## Overview

The GDPR service exposes a minimal HTTP API via the Gin web framework. The API serves internal Application Operations agents only — it is not a public-facing service. The primary entry point is a web form that accepts agent and consumer identification details and triggers a synchronous data collection and export pipeline. The resulting ZIP archive is returned as a file download in the same HTTP response.

## Endpoints

### Web UI and Export

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Renders the GDPR manual offboarding web form | None (internal network only) |
| POST | `/data` | Accepts form data, triggers full GDPR data collection, returns ZIP archive as file download, and emails the archive to the agent | Agent ID and email validation (server-side) |
| GET | `/grpn/healthcheck` | Liveness health check — returns `ok` with HTTP 200 | None |

### Static Assets

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/assets/*filepath` | Serves static CSS/JS assets (Bootstrap, jQuery) | None |

## Request/Response Patterns

### Common headers

- `POST /data` accepts `application/x-www-form-urlencoded` form data
- Session management uses a cookie named `flash` backed by a cookie store

### Form fields for `POST /data`

| Field | Description | Required |
|-------|-------------|----------|
| `consumer_uuid` | Groupon consumer UUID | Yes |
| `consumer_email` | Consumer email address | Yes |
| `agent_id` | Cyclops agent ID (NAM or EMEA) | Yes |
| `agent_email` | Agent email address (must contain `groupon`) | Yes |
| `country` | Two-letter country code (e.g., `DE`, `US`) used to scope all downstream API calls | Yes |

### Error format

Validation errors are rendered as flash messages on the HTML index page (`index.html`). Server-side processing errors (e.g., failed downstream API calls) are returned as JSON:

```json
{"Orders error": "<error message>"}
```

HTTP status codes used:
- `200 OK` — successful export (file download) or rendered form
- `400 Bad Request` — not directly surfaced; validation failures re-render the form
- `500 Internal Server Error` — downstream collection or ZIP packaging failures

### Pagination

Pagination is handled internally when fetching orders and reviews from downstream services. The client receives a single complete ZIP archive regardless of how many pages of data are fetched.

- Orders: fetched in pages of 10 via `offset` parameter until `pagination.count` is reached
- Reviews: fetched in pages of 50 via `offset` parameter until `total` is reached

## Rate Limits

No rate limiting configured.

## Versioning

No API versioning strategy. The web endpoint is unversioned. The service is an internal tool and backwards compatibility is managed operationally.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or formal schema definition is present in the repository.
