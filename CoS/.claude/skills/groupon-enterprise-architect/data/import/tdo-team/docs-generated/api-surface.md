---
service: "tdo-team"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

The tdo-team service exposes no inbound HTTP endpoints. All containers are Kubernetes CronJobs that run on schedule and make outbound calls only. The `.service.yml` file explicitly sets `status_endpoint: disabled: true` and `schema: disabled`. There is no REST API, gRPC interface, GraphQL schema, or any other inbound service interface defined in this repository.

## Endpoints

> Not applicable. This service has no inbound endpoints.

## Request/Response Patterns

> Not applicable.

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable. No rate limiting configured; the service makes outbound calls only.

## Versioning

> Not applicable. No API versioning strategy defined.

## OpenAPI / Schema References

> Not applicable. No OpenAPI spec, proto files, or GraphQL schema exist in this repository.
