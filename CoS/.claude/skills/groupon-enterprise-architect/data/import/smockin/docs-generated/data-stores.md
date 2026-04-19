---
service: "smockin"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "smockinDb"
    type: "postgresql"
    purpose: "Primary store for users, projects, mock definitions, server configuration, and stateful mock state"
  - id: "h2-local"
    type: "h2"
    purpose: "Embedded database used for local and H2-mode deployments"
---

# Data Stores

## Overview

sMockin uses a single relational database as its primary data store. In production and staging environments this is a PostgreSQL instance. A bundled H2 embedded database is used for local development and for the H2-mode launch path (`launch.sh` starts an H2 TCP server on port 9092 as a fallback). All mock definitions, user accounts, project groupings, server configuration, stateful JSON state, and key/value pairs are persisted here. There is no separate cache or search store.

## Stores

### Smockin Database (`smockinDb`)

| Property | Value |
|----------|-------|
| Type | postgresql (production / staging) |
| Architecture ref | `smockinDb` |
| Purpose | Stores users, projects, mocks, configuration, and state for the mock server |
| Ownership | owned |
| Migrations path | Managed by Hibernate DDL auto (`spring.jpa.hibernate.ddl-auto=create`); no separate migrations directory observed |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Users (`smockin_user`) | Stores admin user accounts | username, password (encrypted), role, JWT token |
| Projects | Groups mock endpoints into named workspaces | name, owner user |
| REST Mocks (`restful_mock`) | Defines HTTP mock endpoints and their responses | path, method, mock type, response rules |
| Mock Rules | Ordered rule sets for conditional response selection | conditions, response body, status code, headers |
| Stateful Mock State | In-database JSON state cache for stateful REST mocks | extId, JSON payload, auto-generated ID |
| Key/Value Data | Named key/value pairs used in response variable substitution | key name, value, owner user |
| Server Config | Mock server engine configuration per server type | port, auto-start flag, proxy settings |
| JMS Queue Mocks | Queue endpoint definitions for the embedded ActiveMQ simulation | queue name, response payload |

#### Access Patterns

- **Read**: Mock definitions are loaded at server start and on every incoming request to the mock server engine. Server config is read at startup and on restart.
- **Write**: Mock definitions and rules are written via the admin API. Stateful mock state is written on every POST/PUT/PATCH/DELETE to a stateful endpoint. Key/value data and user records are written via admin API calls.
- **Indexes**: No explicit index definitions visible in the source; Hibernate DDL auto-create manages the schema.

### H2 Embedded Database (local mode)

| Property | Value |
|----------|-------|
| Type | h2 |
| Architecture ref | `smockinDb` (local variant) |
| Purpose | Embedded TCP-mode H2 database for local development without an external PostgreSQL instance |
| Ownership | owned |
| Migrations path | `install/h2-1.4.194.jar`, `install/db.properties` |

#### Access Patterns

- **Read/Write**: Same entity set as production PostgreSQL. Used only in local or CI environments.

## Caches

> No evidence found in codebase. sMockin does not use Redis, Memcached, or any separate caching layer. Stateful mock state is persisted directly to the database.

## Data Flows

All data flows through the JDBC connection pool (HikariCP) from `smockinApp` to `smockinDb`. There is no CDC, ETL, or replication between data stores. The H2 TCP server started by `launch.sh` is a local development convenience and is not used in production.
