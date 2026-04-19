---
service: "afl-3pgw"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

AFL-3PGW is not a customer-serving API service. Its primary processing happens through MBUS event consumption and scheduled Quartz jobs. The service exposes minimal HTTP endpoints inherited from the JTier/Dropwizard framework — primarily health check and status endpoints used by Kubernetes probes and the internal service registry. No public or partner-facing REST API is exposed by this service.

## Endpoints

### JTier Framework Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Kubernetes liveness and readiness probe; returns service health status | None (cluster-internal) |
| GET | `/grpn/status` | Service status endpoint used by the internal service portal | None (cluster-internal) |

> These endpoints are documented in `.service.yml` with `status_endpoint.path: /grpn/status` and `status_endpoint.port: 8080`. The health check path `/grpn/healthcheck` is defined in the deployment framework defaults (`framework-defaults.yml`).

## Request/Response Patterns

### Common headers

> Not applicable — no externally consumed REST API is provided by this service.

### Error format

Errors from health/status endpoints follow the standard JTier/Dropwizard JSON error response format:

```json
{
  "code": 500,
  "message": "<error description>"
}
```

### Pagination

> Not applicable — no paginated endpoints are exposed.

## Rate Limits

> No rate limiting configured on inbound endpoints.

## Versioning

No API versioning strategy — inbound HTTP endpoints are internal-only framework defaults. The service itself is versioned via Maven artifact version (currently `1.0.x`) published to Nexus on each CI build.

## OpenAPI / Schema References

- Swagger YAML: `doc/swagger/swagger.yaml` (minimal — describes service identity only; no operation paths defined)
- Swagger JSON: `doc/swagger/swagger.json`
- Service discovery: `doc/service_discovery/resources.json`

> The swagger spec contains service metadata only (`title`, `description`, `version`, `contact`). No REST operation paths are defined because AFL-3PGW does not expose a consumer-facing API.
