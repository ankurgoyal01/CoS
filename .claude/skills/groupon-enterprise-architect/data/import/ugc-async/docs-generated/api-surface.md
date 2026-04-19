---
service: "ugc-async"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: []
---

# API Surface

## Overview

ugc-async is a background worker service and does not expose a public REST API for consumer or service-to-service use. Its only HTTP endpoints are internal operational endpoints provided by the Dropwizard framework. The service description in `doc/swagger/swagger.yaml` and `doc/service_discovery/resources.json` declares the service name and version but lists no application-level REST resources.

## Endpoints

### Operational / Health Endpoints (Dropwizard built-in)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/status` | Service status (configured but disabled in `.service.yml`) | None |
| GET | `http://<host>:9001/healthcheck` | Dropwizard admin health check (returns result of `UgcAsyncHealthCheck`) | None |
| GET | `http://<host>:9001/metrics` | Dropwizard metrics endpoint | None |
| GET | `http://<host>:9001/ping` | Dropwizard ping | None |
| GET | `/var/groupon/jtier/heartbeat.txt` | File-based heartbeat for infrastructure liveness | None |

> No application-level REST endpoints are defined. All processing is triggered via MBus event consumption and internal Quartz scheduling.

## Request/Response Patterns

### Common headers

> Not applicable — no application REST endpoints exposed.

### Error format

> Not applicable — no application REST endpoints exposed.

### Pagination

> Not applicable — no application REST endpoints exposed.

## Rate Limits

> No rate limiting configured on exposed endpoints.

## Versioning

The service version (`0.2.1-SNAPSHOT`) is declared in `pom.xml` and reflected in `doc/swagger/swagger.yaml` and `doc/service_discovery/resources.json`. No URL-based API versioning is applied because the service does not expose versioned REST resources.

## OpenAPI / Schema References

- `doc/swagger/swagger.yaml` — Swagger 2.0 document; declares service metadata only (no paths defined)
- `doc/swagger/swagger.json` — JSON equivalent
- `doc/service_discovery/resources.json` — Service discovery descriptor
