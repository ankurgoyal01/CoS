---
service: "merchant-deal-management"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: []
---

# API Surface

## Overview

The `continuumDealManagementApi` container exposes a versioned REST API for deal lifecycle management. Consumers submit deal creation and update requests via JSON payloads; the API validates inputs, orchestrates downstream writes, and may enqueue asynchronous jobs for long-running operations. The API is built with Rails Controllers and follows Continuum-standard HTTP/JSON conventions.

## Endpoints

### Deal Management

> No specific endpoint paths are resolvable from the architecture DSL or available inventory files. The architecture model confirms the service exposes versioned REST endpoints for synchronous and asynchronous deal management requests via Rails Controllers. Specific paths (e.g., `/v1/deals`, `/v2/deals/:id`) are not documented in the available codebase inventory.

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| — | `/deals` (versioned) | Create, read, update deal entities | Not specified |
| — | `/deals/:id` (versioned) | Individual deal operations | Not specified |

## Request/Response Patterns

### Common headers

> No evidence found in codebase for specific required headers. Standard Continuum HTTP/JSON conventions apply.

### Error format

> No evidence found in codebase for a documented error response shape.

### Pagination

> No evidence found in codebase for a pagination pattern.

## Rate Limits

The API uses Redis for rate limiting (confirmed by architecture DSL relationship: `continuumDealManagementApi -> continuumDealManagementApiRedis "Uses queues, rate-limiting, and cache state"`). Specific rate limit tiers and thresholds are not resolvable from the available inventory.

| Tier | Limit | Window |
|------|-------|--------|
| — | Not specified | Redis-backed |

## Versioning

The API uses URL-path versioning. The architecture DSL references "Versioned REST controllers" via Rails Controllers in the `dmapiHttpApi` component. Specific version numbers (e.g., v1, v2) are not resolvable from the available inventory.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema were found in the repository inventory.
