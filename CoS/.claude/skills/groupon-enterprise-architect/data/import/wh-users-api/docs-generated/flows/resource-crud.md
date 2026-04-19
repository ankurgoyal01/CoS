---
service: "wh-users-api"
title: "Resource CRUD"
generated: "2026-03-03"
type: flow
flow_name: "resource-crud"
flow_type: synchronous
trigger: "HTTP request to /wh/v2/resource or /wh/v2/resource/{uuid}"
participants:
  - "whUsersApiRestControllers"
  - "whUsersApiResourceService"
  - "whUsersApiResourceDaoRouter"
  - "continuumWhUsersApiPostgresRo"
  - "continuumWhUsersApiPostgresRw"
architecture_ref: "dynamic-wh-users-api-request-lifecycle"
---

# Resource CRUD

## Summary

This flow covers the lifecycle of a Wolfhound resource entity. Resources are named permission objects that can be associated with users and groups to define access levels within the Wolfhound CMS. The resource API follows the same CRUD pattern as users and groups, with all writes routed to the PostgreSQL primary and reads to the read-only replica.

## Trigger

- **Type**: api-call
- **Source**: Wolfhound CMS client or internal service
- **Frequency**: Per-request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST Resources | Receives HTTP requests; routes to ResourceDbService | `whUsersApiRestControllers` |
| ResourceDbService | Implements resource CRUD business logic | `whUsersApiResourceService` |
| ResourceDbRouter/ResourceJdbiDao | Selects RO or RW datasource; executes SQL for resource entities | `whUsersApiResourceDaoRouter` |
| PostgreSQL RO | Serves resource read queries | `continuumWhUsersApiPostgresRo` |
| PostgreSQL RW | Persists resource create/update/delete | `continuumWhUsersApiPostgresRw` |

## Steps

### Create Resource (POST /wh/v2/resource)

1. **Receive create request**: REST Resources receives the POST body with `Resource` schema (required: `name`).
   - From: caller
   - To: `whUsersApiRestControllers`
   - Protocol: REST

2. **Persist resource**: ResourceDbService delegates to ResourceDbRouter, which routes INSERT to the RW database.
   - From: `whUsersApiResourceService` -> `whUsersApiResourceDaoRouter`
   - To: `continuumWhUsersApiPostgresRw`
   - Protocol: JDBC

3. **Return 200** on success; 409 if UUID already exists; 400 if invalid; 422 if creation fails.

### List Resources (GET /wh/v2/resource)

1. **Receive list request**: REST Resources receives optional `skip` (default 0) and `limit` (default 20, max 1000) query parameters.
2. **Query RO database**: ResourceDbRouter routes a paginated SELECT to the read-only replica.
   - To: `continuumWhUsersApiPostgresRo`
3. **Return ResourceListResponse**: Response contains `count` (total) and `items` array of `Resource` objects.

### Get Resource by UUID (GET /wh/v2/resource/{uuid})

1. **Receive UUID lookup**: REST Resources receives UUID path parameter.
2. **Query RO database**: ResourceDbRouter queries the read-only replica by UUID.
   - To: `continuumWhUsersApiPostgresRo`
3. **Return Resource**: Response includes `id`, `name`, `createdAt`, `updatedAt`. Returns 404 if not found.

### Update Resource (PUT /wh/v2/resource/{uuid})

1. **Receive update request**: REST Resources receives UUID and `Resource` body.
2. **Execute update**: ResourceDbRouter routes UPDATE to the RW database.
   - To: `continuumWhUsersApiPostgresRw`
3. **Return 200** on success; 404 if UUID not found; 422 if update fails.

### Delete Resource (DELETE /wh/v2/resource/{uuid})

1. **Receive delete request**: REST Resources receives UUID path parameter.
2. **Execute delete**: ResourceDbRouter routes DELETE to the RW database.
   - To: `continuumWhUsersApiPostgresRw`
3. **Return 204** on success; 404 if UUID not found.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Resource not found | `ResourceNotFoundException` | HTTP 404 |
| UUID already exists | `EntityConflictException` | HTTP 409 |
| Invalid resource body | `InvalidRequestException` | HTTP 400 |
| Resource could not be created/updated | Unprocessable exception | HTTP 422 |
| Database unavailable | Unhandled exception | HTTP 500 |

## Sequence Diagram

```
Caller -> REST Resources: POST /wh/v2/resource {Resource body}
REST Resources -> ResourceDbService: createResource(resource)
ResourceDbService -> ResourceDbRouter: insert(resource)
ResourceDbRouter -> PostgreSQL RW: INSERT INTO resources ...
PostgreSQL RW --> ResourceDbRouter: ok
ResourceDbRouter --> ResourceDbService: ok
ResourceDbService --> REST Resources: ok
REST Resources --> Caller: HTTP 200
```

## Related

- Architecture dynamic view: `dynamic-wh-users-api-request-lifecycle`
- Related flows: [User CRUD](user-crud.md), [Group CRUD](group-crud.md), [Request Lifecycle](request-lifecycle.md)
