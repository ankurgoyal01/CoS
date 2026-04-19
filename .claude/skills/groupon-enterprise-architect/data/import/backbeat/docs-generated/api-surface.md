---
service: "backbeat"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: []
---

# API Surface

## Overview

Backbeat exposes a REST API via its `continuumBackbeatApiRuntime` (Rack/Grape) web process. Consumers use the API to create and manage workflows, submit activity and decision events, monitor queue health, and inspect workflow state. The API is consumed internally by Continuum services, primarily the Accounting Service.

## Endpoints

### Workflow Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v2/workflows` | Create a new workflow | Internal |
| GET | `/v2/workflows/:id` | Retrieve workflow state | Internal |
| PUT | `/v2/workflows/:id/signal/:signal` | Signal a workflow state change | Internal |

### Activity and Decision Events

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v2/workflows/:id/signal/retry_node` | Retry a failed node | Internal |
| PUT | `/v2/workflows/:id/nodes/:node_id` | Update node status (activity/decision result) | Internal |

### Health and Observability

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Service liveness check | None |
| GET | `/heartbeat` | Heartbeat endpoint for uptime monitors | None |
| GET | `/v2/sidekiq` | Sidekiq queue statistics | Internal |

> Endpoint paths are inferred from the `bbWebApi` component description ("workflows, activities, debug, heartbeat, health, and Sidekiq stats") and standard Grape/Backbeat conventions. Confirm exact paths against the Grape route definitions in the service source.

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — all request and response bodies are JSON

### Error format

> No evidence found in DSL inventory. Confirm error envelope format from Grape API source.

### Pagination

> No evidence found in DSL inventory.

## Rate Limits

> No rate limiting configured.

## Versioning

URL path versioning — endpoints are prefixed with `/v2/`.

## OpenAPI / Schema References

> No OpenAPI spec or schema file identified in the architecture inventory. Confirm with service owners.
