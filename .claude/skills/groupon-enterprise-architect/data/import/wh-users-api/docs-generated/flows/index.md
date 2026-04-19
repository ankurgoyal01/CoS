---
service: "wh-users-api"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Wolfhound Users API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [User CRUD](user-crud.md) | synchronous | HTTP request to `/wh/v2/user` or `/wh/v2/user/{uuid}` or `/wh/v2/user/username/{username}` | Create, read, update, and delete user entities; includes group reference validation and username+platform uniqueness enforcement |
| [Group CRUD](group-crud.md) | synchronous | HTTP request to `/wh/v2/group` or `/wh/v2/group/{uuid}` | Create, read, update, and delete group entities; reads routed to RO, writes to RW |
| [Resource CRUD](resource-crud.md) | synchronous | HTTP request to `/wh/v2/resource` or `/wh/v2/resource/{uuid}` | Create, read, update, and delete resource entities; reads routed to RO, writes to RW |
| [Platform User Lookup](platform-user-lookup.md) | synchronous | GET `/wh/v2/user/{uuid}` or GET `/wh/v2/user/username/{username}` | Returns a denormalized PlatformUser projection joining user and group data from the RO database |
| [Request Lifecycle](request-lifecycle.md) | synchronous | Inbound HTTP request on any `/wh/v2/` endpoint | End-to-end path of a request through REST resource, domain service, DB router, and PostgreSQL |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The dynamic view `dynamic-wh-users-api-request-lifecycle` in the central architecture model captures the request path between `continuumWhUsersApi` and its PostgreSQL containers (`continuumWhUsersApiPostgresRo` and `continuumWhUsersApiPostgresRw`). No cross-service flows involving other Continuum services are modelled in this repository's DSL.
