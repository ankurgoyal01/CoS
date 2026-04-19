---
service: "darwin-indexer"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [http-admin]
auth_mechanisms: []
---

# API Surface

## Overview

darwin-indexer is a scheduled indexing service and does not expose a public-facing REST API. It exposes only the Dropwizard admin interface on port 9001, which provides operational endpoints for health checking, metrics scraping, and thread-dump inspection. No external consumers call into this service over HTTP.

## Endpoints

### Dropwizard Admin Interface (port 9001)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/healthcheck` | Reports liveness and dependency health (Elasticsearch, PostgreSQL, upstream services) | None |
| GET | `/metrics` | Exposes Dropwizard Metrics in JSON format for scraping | None |
| GET | `/ping` | Simple liveness ping returning `pong` | None |
| GET | `/threads` | Returns a thread dump for debugging | None |
| POST | `/tasks/gc` | Triggers a JVM garbage collection cycle | None |

> These are standard Dropwizard admin endpoints. Custom task endpoints specific to darwin-indexer are managed by the service owner and are not discoverable from the architecture model alone.

## Request/Response Patterns

### Common headers

> Not applicable — no public REST API. The admin interface does not enforce custom request headers.

### Error format

> Not applicable — no public REST API.

### Pagination

> Not applicable — no public REST API.

## Rate Limits

> No rate limiting configured. The admin port is intended for internal operational use only and is not exposed externally.

## Versioning

> Not applicable — no public REST API. The admin interface follows standard Dropwizard versioning tied to the framework version (1.3.25).

## OpenAPI / Schema References

> No evidence found. darwin-indexer does not expose an OpenAPI spec, proto files, or GraphQL schema. Index document schemas are managed internally and published implicitly through Elasticsearch index mappings.
