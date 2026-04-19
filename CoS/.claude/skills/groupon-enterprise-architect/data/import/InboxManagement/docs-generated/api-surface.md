---
service: "inbox_management_platform"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

InboxManagement exposes a REST API via the `continuumInboxManagementAdminUi` container (Java/Jetty). The API is an operational control plane used by administrators and tooling to inspect queue state, manage runtime configuration, adjust throttle rates, toggle daemon active flags, and manage circuit breakers. It is not a public-facing consumer API.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Liveness and readiness health check for all daemon containers | Internal |

### Admin Configuration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/im/admin/config/{key}` | Read a specific runtime config key | Internal |
| GET | `/im/admin/config` | List all runtime config keys and their current values | Internal |
| POST | `/im/admin/config/{key}` | Create or update a runtime config key | Internal |
| PUT | `/im/admin/config/{key}` | Update a specific runtime config key | Internal |
| DELETE | `/im/admin/config/{key}` | Remove a runtime config key | Internal |

Config keys include: throttle rates, daemon active flags, and circuit breaker settings.

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for POST/PUT request bodies

### Error format

> No evidence found of a standardized error response schema from the available architecture model. Operational procedures to be defined by service owner.

### Pagination

> Not applicable — config key sets are small and returned in full.

## Rate Limits

> No rate limiting configured on the admin API. Access is restricted to internal network/cluster.

## Versioning

No URL versioning. The `/im/admin/config/*` path prefix is the stable contract. Breaking changes are managed through deployment coordination.

## OpenAPI / Schema References

> No OpenAPI spec file discovered in the architecture model. Schema documentation to be added by service owner.
