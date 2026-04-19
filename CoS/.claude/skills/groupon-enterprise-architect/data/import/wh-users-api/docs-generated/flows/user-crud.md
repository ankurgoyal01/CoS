---
service: "wh-users-api"
title: "User CRUD"
generated: "2026-03-03"
type: flow
flow_name: "user-crud"
flow_type: synchronous
trigger: "HTTP request to /wh/v2/user or /wh/v2/user/{uuid} or /wh/v2/user/username/{username}"
participants:
  - "whUsersApiRestControllers"
  - "whUsersApiUserService"
  - "whUsersApiUserDaoRouter"
  - "whUsersApiGroupDaoRouter"
  - "whUsersApiPlatformUserDao"
  - "continuumWhUsersApiPostgresRo"
  - "continuumWhUsersApiPostgresRw"
architecture_ref: "dynamic-wh-users-api-request-lifecycle"
---

# User CRUD

## Summary

This flow covers the full lifecycle of a Wolfhound user entity through the wh-users-api service. Callers can create, search, retrieve by UUID or username, update, and delete users. User creation and retrieval involve group reference validation and denormalized platform-level projections respectively. All write operations go to the PostgreSQL primary; all reads go to the read-only replica.

## Trigger

- **Type**: api-call
- **Source**: Wolfhound CMS client or internal service
- **Frequency**: Per-request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST Resources | Receives HTTP requests; routes to UserDbService | `whUsersApiRestControllers` |
| UserDbService | Validates group reference and `group_id`; orchestrates DAO calls | `whUsersApiUserService` |
| UserDbRouter/UserJdbiDao | Selects RO or RW datasource; executes SQL for user entity | `whUsersApiUserDaoRouter` |
| GroupDbRouter/GroupJdbiDao | Validates group existence during user create/update | `whUsersApiGroupDaoRouter` |
| PlatformUserJdbiDao | Executes user+group join for GET by UUID and GET by username | `whUsersApiPlatformUserDao` |
| PostgreSQL RO | Serves user read queries | `continuumWhUsersApiPostgresRo` |
| PostgreSQL RW | Persists user create/update/delete | `continuumWhUsersApiPostgresRw` |

## Steps

### Create User (POST /wh/v2/user)

1. **Receive create request**: REST Resources receives the POST body with `User` schema (required: `group_id`, `data` with email/locale/name).
   - From: caller
   - To: `whUsersApiRestControllers`
   - Protocol: REST

2. **Validate group reference**: UserDbService calls GroupDbRouter to confirm the `group_id` exists in the database.
   - From: `whUsersApiUserService`
   - To: `whUsersApiGroupDaoRouter` -> `continuumWhUsersApiPostgresRo`
   - Protocol: JDBC

3. **Persist user**: UserDbRouter routes the INSERT to the RW database.
   - From: `whUsersApiUserService` -> `whUsersApiUserDaoRouter`
   - To: `continuumWhUsersApiPostgresRw`
   - Protocol: JDBC

4. **Return 200**: REST Resources returns HTTP 200 on success (409 if UUID already exists, 400 if invalid, 422 if creation fails).

### Find Users (GET /wh/v2/user)

1. **Receive search request**: REST Resources receives optional query parameters (`username`, `locale`, `group_id`, `sort_field`, `sort_order`, `skip`, `limit`).
2. **Query RO database**: UserDbRouter routes a parameterized SELECT to the read-only replica.
   - To: `continuumWhUsersApiPostgresRo`
3. **Return UserListResponse**: Response contains `count` (total matching) and `items` array.

### Get User by UUID (GET /wh/v2/user/{uuid})

1. **Receive UUID lookup**: REST Resources receives UUID path parameter.
2. **Execute platform user join**: UserDbService calls PlatformUserJdbiDao, which queries a denormalized user+group projection from the RO database.
   - To: `continuumWhUsersApiPostgresRo`
3. **Return PlatformUser**: Response includes `id`, `group_id`, `groupName`, `groupResources`, `allowedResources`, `resources`, `platform`, `data`, timestamps. Returns 404 if not found.

### Get User by Username (GET /wh/v2/user/username/{username})

1. **Receive username lookup**: REST Resources receives `username` path parameter and optional `platform` query parameter.
2. **Execute join query**: PlatformUserJdbiDao queries the RO database by username (and platform if provided).
   - To: `continuumWhUsersApiPostgresRo`
3. **Return PlatformUser**: Same response shape as UUID lookup.

### Update User (PUT /wh/v2/user/{uuid})

1. **Receive update request**: REST Resources receives UUID and `User` body.
2. **Validate group reference**: UserDbService validates the `group_id` if changed.
3. **Persist update**: UserDbRouter routes an UPDATE to the RW database.
   - To: `continuumWhUsersApiPostgresRw`
4. **Return 200** on success; 404 if UUID not found; 422 if update fails.

### Delete User (DELETE /wh/v2/user/{uuid})

1. **Receive delete request**: REST Resources receives UUID path parameter.
2. **Execute delete**: UserDbRouter routes a DELETE to the RW database.
   - To: `continuumWhUsersApiPostgresRw`
3. **Return 204** on success; 404 if UUID not found.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User not found | `ResourceNotFoundException` | HTTP 404 |
| UUID already exists | `EntityConflictException` | HTTP 409 |
| Invalid request body | `InvalidRequestException` or Jersey validation | HTTP 400 |
| User could not be created/updated | `UnprocessableEntityException` | HTTP 422 |
| Database unavailable | Unhandled exception | HTTP 500 |

## Sequence Diagram

```
Caller -> REST Resources: POST /wh/v2/user {User body}
REST Resources -> UserDbService: createUser(user)
UserDbService -> GroupDbRouter: findGroup(group_id)
GroupDbRouter -> PostgreSQL RO: SELECT group WHERE id = ?
PostgreSQL RO --> GroupDbRouter: group or not found
GroupDbRouter --> UserDbService: group entity
UserDbService -> UserDbRouter: insertUser(user)
UserDbRouter -> PostgreSQL RW: INSERT INTO users ...
PostgreSQL RW --> UserDbRouter: ok
UserDbRouter --> UserDbService: ok
UserDbService --> REST Resources: ok
REST Resources --> Caller: HTTP 200
```

## Related

- Architecture dynamic view: `dynamic-wh-users-api-request-lifecycle`
- Related flows: [Group CRUD](group-crud.md), [Platform User Lookup](platform-user-lookup.md), [Request Lifecycle](request-lifecycle.md)
