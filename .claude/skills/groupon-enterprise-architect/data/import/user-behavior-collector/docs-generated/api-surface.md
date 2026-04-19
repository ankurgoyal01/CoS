---
service: "user-behavior-collector"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

User Behavior Collector does not expose an HTTP API surface to external or internal consumers. It is a scheduled batch job invoked via cron, operating entirely as an outbound process. There is no embedded web server, no REST endpoints, and no gRPC or GraphQL interface defined in this service.

The job is controlled via command-line arguments passed to the JAR at invocation time (see [Configuration](configuration.md) and [Deployment](deployment.md) for the CLI argument schema).

## Endpoints

> Not applicable. This service exposes no inbound HTTP, gRPC, or messaging endpoints.

## Request/Response Patterns

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable. No rate limiting configured; this is not an HTTP service.

## Versioning

> Not applicable. No API versioning strategy; the service is invoked as a standalone JAR.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema found in the repository.
