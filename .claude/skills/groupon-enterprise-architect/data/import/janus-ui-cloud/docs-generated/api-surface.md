---
service: "janus-ui-cloud"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, websocket]
auth_mechanisms: [session]
---

# API Surface

## Overview

Janus UI Cloud exposes two classes of HTTP endpoints from the `continuumJanusUiCloudGateway` container. The first is a set of static asset routes that deliver the compiled React SPA to the browser. The second is a transparent proxy at `/api/*` that forwards all Janus metadata API requests to the `continuumJanusWebCloudService` backend. The UI itself does not own any business-logic REST endpoints — all data operations are delegated to the Janus metadata service via the proxy.

The SPA communicates with the gateway exclusively over HTTPS/JSON using `axios` for REST calls and `socket.io` for any real-time update channels.

## Endpoints

### Static Asset Serving

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Serves the SPA entrypoint HTML (`index.html`); triggers SPA bootstrap | Session (browser) |
| GET | `/static/*` | Serves compiled JavaScript bundles, CSS, and image assets | None |
| GET | `/grpn/status` | Health/status endpoint; returns service liveness signal | None |

### Janus API Proxy

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST/PUT/DELETE | `/api/*` | Transparent proxy to the Janus Web Cloud metadata service; all CRUD operations on rules, schemas, attributes, destinations, alerts, etc. are forwarded here | Session (propagated) |

### SPA Client-Side Routes (browser navigation only)

These routes are handled entirely client-side by `react-router-dom` and do not correspond to server endpoints. They are listed here to document the functional modules exposed to users:

| Path | Module | Purpose |
|------|--------|---------|
| `/` | Home | Landing dashboard |
| `/raw` | Raw Schema | Browse and manage raw schemas |
| `/manage/raw-schema` | Raw Manager | Create/edit raw schema definitions |
| `/canonical` | Canonical Schema | Browse canonical schema mappings |
| `/manage/canonical-schema` | Canonical Manager | Create/edit canonical schema mappings |
| `/attributes` | Attribute Manager | List all attribute definitions |
| `/attributes/:attributeName` | Attribute Detail | View and edit a single attribute |
| `/udf` | UDF | Manage User-Defined Functions |
| `/destinations` | Destinations | Manage data output destinations |
| `/subscribers` | Subscribers | Manage event subscribers |
| `/sandbox` | Sandbox | Test and validate rules interactively |
| `/replay` | Replay | Replay data events through Janus |
| `/alerts` | Alerts | Configure and review alert rules |
| `/metrics` | Metrics | View platform metrics charts |
| `/help` | Support | Help and support resources |
| `/users` | Users | User management |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — all `/api/*` proxy requests
- Session cookies are forwarded transparently through the proxy to the Janus metadata service

### Error format

> No evidence found in codebase. Error format is defined by the upstream `continuumJanusWebCloudService` and surfaced directly to the browser through the proxy.

### Pagination

> No evidence found in codebase. Pagination behaviour is governed by the upstream `continuumJanusWebCloudService` API.

## Rate Limits

No rate limiting configured at the gateway layer. Rate limiting, if any, is enforced by the upstream `continuumJanusWebCloudService`.

## Versioning

No API versioning strategy at the gateway layer. The `/api/*` path is a transparent proxy; versioning is the responsibility of the upstream Janus metadata service.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec or GraphQL schema is present in this repository. See `continuumJanusWebCloudService` for backend API schema definitions.
