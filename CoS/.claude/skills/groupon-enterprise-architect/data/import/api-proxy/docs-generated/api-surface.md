---
service: "api-proxy"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, client-id]
---

# API Surface

## Overview

API Proxy exposes a single HTTP surface to all Groupon client applications. The primary purpose is transparent proxying: the catch-all route (`/*`) receives every inbound request, resolves the matching backend destination via route configuration, applies the filter chain, and forwards the request. A small set of dedicated paths serve health, status, and administrative operations.

## Endpoints

### Health and Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/heartbeat` | Lightweight liveness probe; returns 200 when the process is accepting traffic | None |
| GET | `/grpn/status` | Detailed service status including component health indicators | None |
| GET | `/grpn/healthcheck` | Full health check including downstream dependency reachability | None |

### Admin / Configuration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/config/*` | Reads current in-memory route and policy configuration | Internal / restricted |
| POST | `/config/*` | Triggers an immediate configuration reload or applies an override | Internal / restricted |

### Catch-all Proxy

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET / POST / PUT / DELETE / PATCH | `/*` | Routes inbound request to resolved backend destination after filter chain evaluation | Enforced by filter chain (client-id, reCAPTCHA where configured) |

## Request/Response Patterns

### Common headers

- `X-Client-Id` — client identifier used by the Client ID Loader for policy resolution and rate-limit bucketing
- `X-Forwarded-For` — propagated downstream for origin IP tracking
- Standard `Authorization` header forwarded to backend destinations unchanged

### Error format

Error responses follow the format returned by the backend destination service when proxying fails gracefully. For gateway-level rejections (rate limit exceeded, reCAPTCHA failure, unresolvable route), the proxy returns a standard HTTP error status with a JSON body. Exact error schema is defined by the filter chain configuration.

### Pagination

> Not applicable — API Proxy transparently forwards pagination parameters to backend services without modification.

## Rate Limits

Rate limiting is enforced per-client using counters stored in `continuumApiProxyRedis`. Limits and windows are loaded dynamically from `continuumClientIdService` and the route configuration; no single fixed global tier is defined in the architecture model.

| Tier | Limit | Window |
|------|-------|--------|
| Client-level | Configured per client ID via `continuumClientIdService` | Per route configuration |
| Global | Configured via route config | Per route configuration |

## Versioning

API Proxy does not impose versioning on proxied requests. Version routing (e.g., `/v1/`, `/v2/`) is handled through route configuration rules that map path prefixes to destination services.

## OpenAPI / Schema References

> No evidence found — API Proxy does not expose an OpenAPI spec in the architecture model. Backend destination contract schemas are owned by individual destination services.
