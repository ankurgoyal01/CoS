---
service: "akamai-cdn"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["https"]
auth_mechanisms: ["api-key"]
---

# API Surface

## Overview

> No evidence found of a service-owned API surface. Akamai CDN is a managed SaaS configuration unit. Groupon's interaction with it occurs through the Akamai Control Center web UI (`https://control.akamai.com`) and the Akamai OPEN APIs, not through a service-owned endpoint. Groupon does not expose its own HTTP API for this service.

The Akamai Control Center (`https://control.akamai.com`) provides the primary management interface. The Akamai OPEN API (accessed via HTTPS with EdgeGrid API key authentication) is used programmatically to apply property rules and configuration changes.

## Endpoints

> Not applicable — this service does not expose its own HTTP endpoints. All management operations are performed against the Akamai Control Center and OPEN API at `https://control.akamai.com`.

## Request/Response Patterns

### Common headers

> Not applicable — no service-owned API.

### Error format

> Not applicable — no service-owned API.

### Pagination

> Not applicable — no service-owned API.

## Rate Limits

> No rate limiting configured on a service-owned API. Akamai OPEN API enforces its own rate limits per Akamai account and contract.

## Versioning

> Not applicable — no service-owned API.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema exist in this repository. Akamai OPEN API documentation is available at `https://techdocs.akamai.com/`.
