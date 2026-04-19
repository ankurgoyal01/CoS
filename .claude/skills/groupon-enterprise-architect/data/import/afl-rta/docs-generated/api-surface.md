---
service: "afl-rta"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [http]
auth_mechanisms: []
---

# API Surface

## Overview

AFL RTA does not expose a public REST API for business logic consumption. Its primary integration pattern is event-driven: it consumes from Kafka and publishes to MBus. The service does expose internal JTier framework management endpoints (health check, status, admin) used by the Kubernetes deployment probes and operational tooling.

## Endpoints

### JTier Framework Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Kubernetes liveness and readiness probe | None |
| GET | `/grpn/status` | Service status (disabled per `.service.yml`) | None |

> The `/grpn/status` endpoint is explicitly disabled in `.service.yml` (`status_endpoint.disabled: true`). The `/grpn/healthcheck` endpoint is active and used by the Kubernetes deployment health probes on port `8080`.

## Request/Response Patterns

### Common headers

> Not applicable — no business REST API is exposed by this service.

### Error format

> Not applicable — no business REST API is exposed by this service.

### Pagination

> Not applicable — no business REST API is exposed by this service.

## Rate Limits

> No rate limiting configured. AFL RTA is not an API server; inbound data volume is governed by Kafka consumer throughput.

## Versioning

> Not applicable — no versioned REST API is exposed.

## OpenAPI / Schema References

A Swagger document exists in the repository but describes only the service metadata with no defined paths:

- `doc/swagger/swagger.yaml` — service description only, no business endpoints
- `doc/swagger/swagger.json` — equivalent JSON form
- `doc/service_discovery/resources.json` — service discovery metadata (protocol: `rest`, version: `1.0.local-SNAPSHOT`)
