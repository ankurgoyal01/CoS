---
service: "badges-trending-calculator"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

Badges Trending Calculator has no inbound HTTP API surface. It is a pure consumer/producer service: it reads from Kafka and writes computed rankings to Redis. The only inbound interface is the Kafka topic `janus-tier1`.

The `.service.yml` declares a status endpoint (`/grpn/status` on port `8070`) that is provided by the CDE Job Framework base image, but no application-level REST endpoints are defined in the codebase.

## Endpoints

### Status (Framework-provided)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/status` | Framework health/status check (CDE Job Framework) | None |

> No application-defined REST, gRPC, or GraphQL endpoints exist in this service.

## Request/Response Patterns

### Common headers

> Not applicable — no inbound HTTP API.

### Error format

> Not applicable — no inbound HTTP API.

### Pagination

> Not applicable — no inbound HTTP API.

## Rate Limits

> No rate limiting configured.

## Versioning

> Not applicable — no inbound HTTP API.

## OpenAPI / Schema References

> No evidence found in codebase.
