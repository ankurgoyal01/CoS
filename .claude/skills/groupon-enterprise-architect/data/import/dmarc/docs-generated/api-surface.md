---
service: "dmarc"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [http]
auth_mechanisms: []
---

# API Surface

## Overview

The DMARC service exposes a minimal internal HTTP server (`net/http`, port `8080`) solely for Kubernetes health probing. It does not expose a public or internal REST API for other services. All DMARC report data flows outward through structured log files, not HTTP responses.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Kubernetes liveness and readiness probe. Returns `200 OK` with body `OK\n`. | None |
| GET | `/` | Catch-all handler. Returns `200 OK` with body `OK\n` for any unmatched path. | None |

## Request/Response Patterns

### Common headers

> No evidence found in codebase.

### Error format

> No evidence found in codebase. The health endpoints return a plain-text `OK\n` response only.

### Pagination

> Not applicable. The service does not serve paginated resources.

## Rate Limits

> No rate limiting configured on the internal health HTTP server.

## Versioning

> Not applicable. No versioned API is exposed.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema exist in this repository.
