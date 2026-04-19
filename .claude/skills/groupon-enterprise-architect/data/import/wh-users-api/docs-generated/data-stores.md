---
service: "wh-users-api"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumWhUsersApiPostgresRw"
    type: "postgresql"
    purpose: "Primary transactional store for user, group, and resource writes"
  - id: "continuumWhUsersApiPostgresRo"
    type: "postgresql"
    purpose: "Read-only replica for user, group, and resource queries"
---

# Data Stores

## Overview

wh-users-api owns a single DaaS-managed PostgreSQL database cluster with two connection endpoints: a read-write primary and a read-only replica. All writes (create, update, delete) are routed to the primary. All reads (list, get by UUID, get by username) are routed to the replica. Schema migrations are applied via Flyway on service startup using the DBA database user. The database is hosted in `us-central1` (GCP) and shared between NA and EMEA traffic.

## Stores

### WH Users API Postgres RW (`continuumWhUsersApiPostgresRw`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumWhUsersApiPostgresRw` |
| Purpose | Primary transactional store for all create, update, and delete operations on users, groups, and resources |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration` (managed via `jtier-migrations` / Flyway) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `users` | Stores Wolfhound user records | `id` (uuid PK), `group_id` (FK to groups), `data` (user payload including email, locale, name, username, password), `resources`, `created_at`, `updated_at` |
| `groups` | Stores Wolfhound group records | `id` (uuid PK), `name`, `platform`, `resources`, `created_at`, `updated_at` |
| `resources` | Stores Wolfhound resource records | `id` (uuid PK), `name`, `created_at`, `updated_at` |

#### Access Patterns

- **Read**: Reads are routed to the read-only replica (`continuumWhUsersApiPostgresRo`). Patterns include: list with pagination (`skip`/`limit`), lookup by UUID, lookup by username and platform, and a denormalized join of user+group for `PlatformUser` responses.
- **Write**: Writes go to the primary (`continuumWhUsersApiPostgresRw`). Patterns include: insert on create, update by UUID, hard delete by UUID.
- **Indexes**: Not directly visible from source; standard UUID primary key indexes expected. The username+platform lookup via `PlatformUserJdbiDao` suggests a compound index on username and platform columns.

---

### WH Users API Postgres RO (`continuumWhUsersApiPostgresRo`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumWhUsersApiPostgresRo` |
| Purpose | Read-only replica endpoint for all query operations, reducing load on the primary |
| Ownership | owned |
| Migrations path | N/A — schema managed via RW primary |

#### Access Patterns

- **Read**: All GET-family operations in UserDbService, GroupDbService, and ResourceDbService are directed here via the respective DB router components.
- **Write**: Not applicable — read-only endpoint.

## Caches

> No evidence found in codebase.

No caching layer (Redis, Memcached, or in-memory cache) is configured in this service.

## Data Flows

Writes flow from REST Resources to a service layer, then through a DB router component that selects the RW datasource, and are committed to the PostgreSQL primary. Reads follow the same path but the DB router selects the RO datasource (read-only replica). The service builds two separate JDBI instances at startup — one bound to the RW connection pool and one to the RO connection pool — via `WhUsersApiConfiguration.getOrCreateDataAccessor()`. Database connectivity health checks are intentionally disabled to prevent pod restarts during a database outage (5xx responses are returned instead).
