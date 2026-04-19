---
service: "orders_mbus_client"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [http]
auth_mechanisms: []
---

# API Surface

## Overview

Orders Mbus Client is a worker service. It does not expose a public REST API intended for external consumers. The embedded Dropwizard HTTP server provides only internal operational endpoints (health check and admin). All domain logic is driven by MBus event subscriptions and Quartz-scheduled jobs.

The service does expose a Swagger UI stub (configured against `com.groupon.jorders.ordersmbusclient.resources`), but no custom resource classes are present in the codebase — the Swagger title is `OrdersMbusClient v1.0.0` and the contact is `JOrders@groupon.com`.

## Endpoints

### Health and Admin (Dropwizard built-in)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/healthcheck` | JTier health check — verifies `heartbeat.txt` exists and math health check passes | None |
| GET | `/metrics` | Dropwizard/Codahale metrics dump | None (admin port 9001) |
| GET | `/quartz` | Quartz scheduler admin page | None (admin port 9001) |

> Application port: **9000** (cloud: 8080). Admin port: **9001** (cloud: 8081).

## Request/Response Patterns

### Common headers

> Not applicable — the service does not expose a consumer-facing HTTP API.

### Error format

> Not applicable — the service does not expose a consumer-facing HTTP API.

### Pagination

> Not applicable — the service does not expose a consumer-facing HTTP API.

## Rate Limits

> No rate limiting configured on the service's own HTTP surface.

## Versioning

The Swagger configuration declares version `1.0.0`. There is no versioned URL prefix for the service's own endpoints. Outbound calls to the Orders service use versioned paths (`/v2/...`, `/tps/v1/...`).

## OpenAPI / Schema References

- Swagger config: `src/main/resources/config/development.yml` (section `swagger`)
- Swagger JSON stub: `doc/swagger/swagger.json` (symlinked from `src/main/resources/swagger.json`)
- Swagger YAML stub: `doc/swagger/swagger.yaml`

> The Swagger spec is a template stub with no custom resource paths defined.
