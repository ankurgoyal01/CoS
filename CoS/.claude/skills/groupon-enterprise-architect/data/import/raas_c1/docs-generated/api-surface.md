---
service: "raas_c1"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

RAAS C1 is a Service Portal registration entry and does not expose any API endpoints of its own. The service exists solely as an identity record for internal tooling. The status endpoint is explicitly disabled in `.service.yml` (`status_endpoint.disabled: true`). Consumers interacting with Redis clusters in the C1 colos should reference the `raas` platform API surface.

## Endpoints

> Not applicable — this service has no deployable application and exposes no endpoints.

## Request/Response Patterns

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable — no API endpoints are exposed.

## Versioning

> Not applicable — no API is versioned.

## OpenAPI / Schema References

> Not applicable — no OpenAPI spec, proto files, or GraphQL schema exist for this Service Portal entry.
