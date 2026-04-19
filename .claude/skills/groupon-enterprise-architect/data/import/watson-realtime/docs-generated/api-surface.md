---
service: "watson-realtime"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> Not applicable

watson-realtime exposes no REST, gRPC, GraphQL, or WebSocket API. All workers are headless Kafka Streams applications. The only liveness signal is a file-based health probe (exec health check) used by the container orchestrator to verify each worker process is running.

## Endpoints

> No evidence found

No HTTP endpoints are defined. There are no REST controllers, route handlers, or protocol servers in this service.

## Request/Response Patterns

### Common headers

> Not applicable — no HTTP interface.

### Error format

> Not applicable — no HTTP interface.

### Pagination

> Not applicable — no HTTP interface.

## Rate Limits

> No rate limiting configured.

## Versioning

> Not applicable — no API surface to version.

## OpenAPI / Schema References

No OpenAPI spec, proto files, or GraphQL schema exist for this service. Event schema definitions are managed externally by the Janus Metadata Service (`janusMetadataService_4d1e`).
