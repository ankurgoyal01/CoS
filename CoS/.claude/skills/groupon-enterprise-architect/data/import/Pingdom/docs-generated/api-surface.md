---
service: "pingdom"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase. The Pingdom service registry entry does not expose any HTTP, gRPC, or other API surface of its own. It is a service metadata and SRE operational endpoint rather than an application server.

The external Pingdom SaaS REST API (`https://api.pingdom.com/api/2.1`) is consumed by integrating Groupon services — see [Integrations](integrations.md) for details. That API is not owned by this service.

## Endpoints

> No evidence found in codebase. No endpoints are defined or exposed by the Pingdom service portal.

The `.service.yml` explicitly sets `status_endpoint: disabled: true` and `schema: disabled`.

## Request/Response Patterns

### Common headers

> Not applicable

### Error format

> Not applicable

### Pagination

> Not applicable

## Rate Limits

> Not applicable. No rate limiting configured on this service.

## Versioning

> Not applicable. No versioning strategy applies to this service metadata endpoint.

## OpenAPI / Schema References

> Not applicable. No OpenAPI spec, proto files, or GraphQL schema exist in this repository. Schema generation is explicitly disabled (`schema: disabled` in `.service.yml`).
