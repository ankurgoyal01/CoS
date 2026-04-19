---
service: "subscription_flow"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, cookie]
---

# API Surface

## Overview

Subscription Flow exposes HTML rendering endpoints consumed by Groupon web clients and upstream aggregation layers. Requests arrive via HTTP, are routed through the Controller Layer, processed by the Renderer Pipeline, and returned as rendered HTML fragments or full page responses. This is a server-side rendering service — it does not expose a JSON API.

## Endpoints

### Subscription Modal Rendering

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/subscription_flow/modal` | Renders the subscription acquisition modal HTML | Session / Groupon middleware context |
| GET | `/subscription_flow/assets/*` | Serves static asset files related to subscription modal UI | None (public) |

> Exact endpoint paths are not fully discoverable from the inventory. The paths above reflect the service name and i-tier conventions. Service owner should confirm canonical route definitions.

## Request/Response Patterns

### Common headers

- `Content-Type: text/html` — responses are rendered HTML
- `X-Groupon-Request-Id` — request correlation ID propagated via Groupon middleware
- Standard Groupon i-tier session/cookie headers applied by Groupon Middleware

### Error format

> No evidence found in codebase. Standard Express error handler returns an HTML error page or passes errors to the i-tier error middleware.

### Pagination

> Not applicable — this service renders modal HTML fragments, not paginated data.

## Rate Limits

> No rate limiting configured.

## Versioning

> No evidence found in codebase. The service does not use a versioned URL path prefix. I-tier services are typically versioned by deploying new service versions rather than path versioning.

## OpenAPI / Schema References

> No evidence found in codebase. I-tier HTML rendering services do not typically expose OpenAPI specifications.
