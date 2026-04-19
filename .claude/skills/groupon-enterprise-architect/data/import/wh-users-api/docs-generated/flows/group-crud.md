---
service: "wh-users-api"
title: "Group CRUD"
generated: "2026-03-03"
type: flow
flow_name: "group-crud"
flow_type: synchronous
trigger: "HTTP request to /wh/v2/group or /wh/v2/group/{uuid}"
participants:
  - "whUsersApiRestControllers"
  - "whUsersApiGroupService"
  - "whUsersApiGroupDaoRouter"
  - "continuumWhUsersApiPostgresRo"
  - "continuumWhUsersApiPostgresRw"
architecture_ref: "dynamic-wh-users-api-request-lifecycle"
---

# Group CRUD

## Summary

This flow covers the lifecycle of a Wolfhound group entity. Groups are collections associated with a platform name and an optional set of resource references. They serve as the primary grouping mechanism for Wolfhound users. All write operations route to the PostgreSQL primary; all reads route to the read-only replica.

## Trigger

- **Type**: api-call
- **Source**: Wolfhound CMS client or internal service
- **Frequency**: Per-request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST Resources | Receives HTTP requests; routes to GroupDbService | `whUsersApiRestControllers` |
| GroupDbService | Implements group CRUD business logic | `whUsersApiGroupService` |
| GroupDbRouter/GroupJdbiDao | Selects RO or RW datasource; executes SQL for group entities | `whUsersApiGroupDaoRouter` |
| PostgreSQL RO | Serves group read queries | `continuumWhUsersApiPostgresRo` |
| PostgreSQL RW | Persists group create/update/delete | `continuumWhUsersApiPostgresRw` |

## Steps

### Create Group (POST /wh/v2/group)

1. **Receive create request**: REST Resources receives the POST body with `Group` schema (required: `name`, `platform`; optional: `resources` array).
   - From: caller
   - To: `whUsersApiRestControllers`
   - Protocol: REST

2. **Persist group**: GroupDbService delegates to GroupDbRouter, which routes INSERT to the RW database.
   - From: `whUsersApiGroupService` -> `whUsersApiGroupDaoRouter`
   - To: `continuumWhUsersApiPostgresRw`
   - Protocol: JDBC

3. **Return 200** on success; 409 if UUID already exists; 400 if invalid; 422 if creation fails.

### List Groups (GET /wh/v2/group)

1. **Receive list request**: REST Resources receives optional `skip` (default 0) and `limit` (default 20, max 1000) query parameters.
2. **Query RO database**: GroupDbRouter routes a paginated SELECT to the read-only replica.
   - To: `continuumWhUsersApiPostgresRo`
3. **Return GroupListResponse**: Response contains `count` (total) and `items` array of `Group` objects.

### Get Group by UUID (GET /wh/v2/group/{uuid})

1. **Receive UUID lookup**: REST Resources receives UUID path parameter.
2. **Query RO database**: GroupDbRouter queries the read-only replica by UUID.
   - To: `continuumWhUsersApiPostgresRo`
3. **Return Group**: Response includes `id`, `name`, `platform`, `resources`, `createdAt`, `updatedAt`. Returns 404 if not found.

### Update Group (PUT /wh/v2/group/{uuid})

1. **Receive update request**: REST Resources receives UUID and `Group` body.
2. **Execute update**: GroupDbRouter routes UPDATE to the RW database.
   - To: `continuumWhUsersApiPostgresRw`
3. **Return 200** on success; 404 if UUID not found; 422 if update fails.

### Delete Group (DELETE /wh/v2/group/{uuid})

1. **Receive delete request**: REST Resources receives UUID path parameter.
2. **Execute delete**: GroupDbRouter routes DELETE to the RW database.
   - To: `continuumWhUsersApiPostgresRw`
3. **Return 204** on success; 404 if UUID not found.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Group not found | `ResourceNotFoundException` | HTTP 404 |
| UUID already exists | `EntityConflictException` | HTTP 409 |
| Invalid group body | `InvalidRequestException` | HTTP 400 |
| Group could not be created/updated | Unprocessable exception | HTTP 422 |
| Database unavailable | Unhandled exception | HTTP 500 |

## Sequence Diagram

```
Caller -> REST Resources: GET /wh/v2/group?skip=0&limit=20
REST Resources -> GroupDbService: listGroups(skip, limit)
GroupDbService -> GroupDbRouter: findAll(skip, limit)
GroupDbRouter -> PostgreSQL RO: SELECT * FROM groups LIMIT ? OFFSET ?
PostgreSQL RO --> GroupDbRouter: ResultSet
GroupDbRouter --> GroupDbService: List<Group>
GroupDbService --> REST Resources: GroupListResponse
REST Resources --> Caller: HTTP 200 {count, items}
```

## Related

- Architecture dynamic view: `dynamic-wh-users-api-request-lifecycle`
- Related flows: [User CRUD](user-crud.md), [Resource CRUD](resource-crud.md), [Request Lifecycle](request-lifecycle.md)
