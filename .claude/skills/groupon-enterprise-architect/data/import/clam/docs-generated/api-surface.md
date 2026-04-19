---
service: "clam"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

CLAM exposes no HTTP, gRPC, or GraphQL API surface. The `status_endpoint` is explicitly disabled in `.service.yml` (`status_endpoint.disabled: true`). All interaction with CLAM is through Kafka topics — upstream producers write to the input histogram topic and downstream consumers read from the output aggregates topic. See [Events](events.md) for the full topic inventory.

## Endpoints

> Not applicable. CLAM is a headless streaming job with no inbound HTTP endpoints.

## Request/Response Patterns

### Common headers
> Not applicable.

### Error format
> Not applicable.

### Pagination
> Not applicable.

## Rate Limits

> Not applicable. No rate limiting configured.

## Versioning

> Not applicable. No API versioning strategy — CLAM has no HTTP API.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema exists in the repository. The Kafka message schema is an InfluxDB line-protocol string encoding of TDigest data; the JSON histogram input format is described in [Events](events.md).
