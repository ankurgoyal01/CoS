---
service: "wh-users-api"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 1
---

# Integrations

## Overview

wh-users-api has a minimal integration footprint. It owns its own PostgreSQL database (two endpoints) and depends on `tsd_aggregator` for metrics aggregation. No external SaaS integrations, message brokers, or third-party HTTP APIs are present. Upstream consumers call the service over REST; the service's only outbound network calls go to the database.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| DaaS PostgreSQL (RW) | JDBC | Persist user, group, and resource entities | yes | `continuumWhUsersApiPostgresRw` |
| DaaS PostgreSQL (RO) | JDBC | Read user, group, and resource entities | yes | `continuumWhUsersApiPostgresRo` |

### DaaS PostgreSQL (RW) Detail

- **Protocol**: JDBC over PostgreSQL wire protocol (port 5432)
- **Base URL / SDK**: Configured via `postgres` key in JTier YAML config; connection pool built by `jtier-daas-postgres`
- **Auth**: DBA user (for Flyway migrations on startup); app user (for runtime read-write operations); credentials stored in `wh-users-api-secrets` repository
- **Purpose**: All create, update, and delete operations on users, groups, and resources
- **Failure mode**: Service returns HTTP 5xx errors; pods do not restart (health check for DB is intentionally disabled per `WhUsersApiConfiguration`)
- **Circuit breaker**: Not configured

### DaaS PostgreSQL (RO) Detail

- **Protocol**: JDBC over PostgreSQL wire protocol (port 5432)
- **Base URL / SDK**: Configured via `readOnlyPostgres` key in JTier YAML config; falls back to RW config if `readOnlyPostgres` is not specified
- **Auth**: App user (read-only); credentials stored in `wh-users-api-secrets` repository
- **Purpose**: All list and get operations on users, groups, and resources
- **Failure mode**: Service returns HTTP 5xx errors
- **Circuit breaker**: Not configured

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| tsd_aggregator | metrics push | Time-series metrics aggregation | not modelled in DSL |

> The `tsd_aggregator` dependency is declared in `.service.yml` under `dependencies`. No further integration detail is discoverable from the source code.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

The service is consumed by Wolfhound CMS tools and other internal services within the Continuum platform that require user, group, or resource data. No specific upstream consumers are enumerated in this repository.

## Dependency Health

Database connectivity health checks are deliberately disabled in `WhUsersApiConfiguration` to prevent Kubernetes pod restarts during a database outage. When the database is unavailable, the service returns HTTP 5xx responses rather than failing health probes. This is a conscious operational trade-off documented in the configuration source.
