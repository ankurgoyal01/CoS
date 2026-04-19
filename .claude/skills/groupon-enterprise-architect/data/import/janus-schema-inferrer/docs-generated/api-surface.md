---
service: "janus-schema-inferrer"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [none]
auth_mechanisms: [none]
---

# API Surface

## Overview

Janus Schema Inferrer does not expose a public HTTP API to external consumers. It is a scheduled batch worker (Kubernetes CronJob) that runs hourly, consumes message streams, and pushes results to downstream systems. The only HTTP surface exposed is the JTier platform's built-in operational endpoints for health checking and status reporting.

## Endpoints

### JTier Operational Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/status` | Returns service status JSON including git commit SHA | None |
| `GET` | `/grpn/healthcheck` | Returns JTier health check result | None |

> These endpoints are used by Kubernetes readiness probes (pgrep-based `exec` probe) and liveness probes (`cat /var/groupon/jtier/schema_inferrer_health.txt`). The readiness probe checks that the Java process is running; the liveness probe reads the health flag file created at startup.

## Request/Response Patterns

### Common headers

> Not applicable — no consumer-facing API.

### Error format

> Not applicable — no consumer-facing API.

### Pagination

> Not applicable — no consumer-facing API.

## Rate Limits

> No rate limiting configured. The service is a CronJob that runs once per hour.

## Versioning

> Not applicable — no versioned API surface. The service version is tracked via Maven artifact version (`1.0.x`) and Docker image tag.

## OpenAPI / Schema References

A stub OpenAPI descriptor exists at `doc/swagger/swagger.yaml` but contains only the service metadata header (no endpoints defined). The swagger configuration is at `doc/swagger/config.yml`.

```
doc/swagger/swagger.yaml   — stub, no routes defined
doc/swagger/config.yml     — swagger-ui configuration
```
