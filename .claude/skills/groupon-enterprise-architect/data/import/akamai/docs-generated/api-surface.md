---
service: "akamai"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found — this repository contains only YAML service metadata and architecture DSL. The akamai service does not expose any application API endpoints. Akamai itself provides control-plane APIs at `https://control.akamai.com`, but those are owned and operated by Akamai as a SaaS vendor; Groupon does not expose them as its own API surface.

## Endpoints

> Not applicable — no Groupon-owned endpoints are defined in this repository.

## Request/Response Patterns

### Common headers

> Not applicable

### Error format

> Not applicable

### Pagination

> Not applicable

## Rate Limits

> Not applicable — no rate limiting is configured for this service. The Akamai control-plane API has its own vendor-imposed rate limits managed outside this repository.

## Versioning

> Not applicable — no API versioning strategy applies to this service.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema exist in this repository. The status endpoint is explicitly disabled (`status_endpoint.disabled: true` in `.service.yml`).
