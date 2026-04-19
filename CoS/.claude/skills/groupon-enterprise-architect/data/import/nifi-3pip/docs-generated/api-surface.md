---
service: "nifi-3pip"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, http]
auth_mechanisms: []
---

# API Surface

## Overview

nifi-3pip exposes the standard Apache NiFi REST API on HTTP port 8080 (or HTTPS port 8443 when TLS is configured). The API is used by operators to manage data flow definitions, monitor processor status, and inspect cluster health. In the current deployment configuration, the service runs in HTTP mode (`NIFI_WEB_HTTP_PORT=8080`). No custom application-level API endpoints are defined beyond the standard NiFi REST API surface.

## Endpoints

### NiFi System and Cluster Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/nifi-api/system-diagnostics` | Returns system resource usage diagnostics; used as startup, readiness, and liveness probe endpoint | None (HTTP mode) |
| GET | `/nifi-api/controller/cluster` | Returns cluster membership and per-node connection status; used by the health-check script | None (HTTP mode) |

### NiFi Web UI

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/nifi` | Serves the NiFi browser-based flow management UI | None (HTTP mode) |

> The full NiFi REST API surface (flow management, processor CRUD, provenance queries, etc.) is provided by the Apache NiFi runtime and is not custom-coded in this repository. Refer to the [Apache NiFi REST API documentation](https://nifi.apache.org/docs/nifi-docs/rest-api/index.html) for the complete endpoint catalog.

## Request/Response Patterns

### Common headers

> No evidence found in codebase of custom request headers beyond standard NiFi API conventions.

### Error format

Errors follow standard Apache NiFi REST API error responses — JSON body containing a `message` field and appropriate HTTP status codes (e.g., 400, 404, 503).

### Pagination

> No evidence found in codebase of custom pagination patterns. Standard NiFi API uses query parameters for result limiting where applicable.

## Rate Limits

> No rate limiting configured. The NiFi REST API is accessed internally by operators and health-check scripts only.

## Versioning

The NiFi REST API is versioned by the Apache NiFi release version (2.4.0). No custom API versioning strategy is applied at the application layer. The base URL path `/nifi-api` is the standard NiFi API prefix.

## OpenAPI / Schema References

> No OpenAPI spec or custom schema files exist in this repository. The NiFi 2.4.0 REST API schema is provided by the upstream Apache NiFi project.
