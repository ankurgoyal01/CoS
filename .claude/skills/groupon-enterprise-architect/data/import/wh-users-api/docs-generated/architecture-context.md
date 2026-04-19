---
service: "wh-users-api"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumWhUsersApi", "continuumWhUsersApiPostgresRw", "continuumWhUsersApiPostgresRo"]
---

# Architecture Context

## System Context

`wh-users-api` is a backend container within the `continuumSystem`. It sits at the user-management layer of the Wolfhound CMS, exposing a REST API on the `/wh/v2/` prefix. Internal Wolfhound CMS tools and services call this API to manage users, groups, and resources. The service owns a dedicated DaaS-managed PostgreSQL database (shared between NA and EMEA regions), with separate read-write and read-only endpoints to distribute load.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| WH Users API | `continuumWhUsersApi` | Backend service | Java 17, Dropwizard, JDBI | 1.0.x | Dropwizard/JTier service that manages Wolfhound users, groups, and resources over REST |
| WH Users API Postgres RW | `continuumWhUsersApiPostgresRw` | Database | PostgreSQL | (DaaS-managed) | Primary transactional PostgreSQL for wh-users-api writes |
| WH Users API Postgres RO | `continuumWhUsersApiPostgresRo` | Database | PostgreSQL | (DaaS-managed) | Read-only PostgreSQL endpoint for wh-users-api queries |

## Components by Container

### WH Users API (`continuumWhUsersApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| REST Resources (`whUsersApiRestControllers`) | JAX-RS resources: UserResource, GroupResource, ResourceResource — receives HTTP requests and dispatches to services | Dropwizard Jersey |
| UserDbService (`whUsersApiUserService`) | Implements user business rules and orchestration; validates group references and username+platform uniqueness before persisting | Service |
| GroupDbService (`whUsersApiGroupService`) | Implements group CRUD behavior | Service |
| ResourceDbService (`whUsersApiResourceService`) | Implements resource CRUD behavior | Service |
| UserDbRouter/UserJdbiDao (`whUsersApiUserDaoRouter`) | Routes user reads to the RO database and writes to the RW database | DAO, JDBI |
| GroupDbRouter/GroupJdbiDao (`whUsersApiGroupDaoRouter`) | Routes group reads to the RO database and writes to the RW database | DAO, JDBI |
| ResourceDbRouter/ResourceJdbiDao (`whUsersApiResourceDaoRouter`) | Routes resource reads to the RO database and writes to the RW database | DAO, JDBI |
| PlatformUserJdbiDao (`whUsersApiPlatformUserDao`) | Provides user+group join lookups for UUID and username/platform queries | DAO, JDBI |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumWhUsersApi` | `continuumWhUsersApiPostgresRo` | Reads users, groups, resources, and joined platform views via JDBI | JDBC/PostgreSQL |
| `continuumWhUsersApi` | `continuumWhUsersApiPostgresRw` | Creates, updates, and deletes users, groups, and resources via JDBI | JDBC/PostgreSQL |
| `whUsersApiRestControllers` | `whUsersApiUserService` | Handles user endpoints | Direct (in-process) |
| `whUsersApiRestControllers` | `whUsersApiGroupService` | Handles group endpoints | Direct (in-process) |
| `whUsersApiRestControllers` | `whUsersApiResourceService` | Handles resource endpoints | Direct (in-process) |
| `whUsersApiUserService` | `whUsersApiUserDaoRouter` | Persists and searches users | Direct (in-process) |
| `whUsersApiUserService` | `whUsersApiGroupDaoRouter` | Validates group references | Direct (in-process) |
| `whUsersApiUserService` | `whUsersApiPlatformUserDao` | Reads denormalized user+group projection | Direct (in-process) |
| `whUsersApiGroupService` | `whUsersApiGroupDaoRouter` | Persists and retrieves groups | Direct (in-process) |
| `whUsersApiResourceService` | `whUsersApiResourceDaoRouter` | Persists and retrieves resources | Direct (in-process) |

## Architecture Diagram References

- Component diagram: `components-continuum-wh-users-api`
- Dynamic / request lifecycle: `dynamic-wh-users-api-request-lifecycle`
