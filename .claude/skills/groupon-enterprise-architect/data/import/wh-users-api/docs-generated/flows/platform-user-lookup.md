---
service: "wh-users-api"
title: "Platform User Lookup"
generated: "2026-03-03"
type: flow
flow_name: "platform-user-lookup"
flow_type: synchronous
trigger: "HTTP GET to /wh/v2/user/{uuid} or /wh/v2/user/username/{username}"
participants:
  - "whUsersApiRestControllers"
  - "whUsersApiUserService"
  - "whUsersApiPlatformUserDao"
  - "continuumWhUsersApiPostgresRo"
architecture_ref: "dynamic-wh-users-api-request-lifecycle"
---

# Platform User Lookup

## Summary

The platform user lookup is a specialized read flow that returns a denormalized projection of a Wolfhound user combined with their group membership data. Rather than returning just the raw user entity, this flow joins the user record with its associated group to produce a `PlatformUser` response that includes group name, group resources, and the user's individually allowed resources. This projection supports platform-level access control checks by consumers. Lookups can be performed by UUID or by username (with an optional `platform` qualifier).

## Trigger

- **Type**: api-call
- **Source**: Wolfhound CMS client or internal service requiring a complete user-plus-group view
- **Frequency**: Per-request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST Resources | Receives GET request; routes to UserDbService | `whUsersApiRestControllers` |
| UserDbService | Delegates platform user lookups to PlatformUserJdbiDao | `whUsersApiUserService` |
| PlatformUserJdbiDao | Executes denormalized user+group join query against the RO database | `whUsersApiPlatformUserDao` |
| PostgreSQL RO | Serves the join query | `continuumWhUsersApiPostgresRo` |

## Steps

### Lookup by UUID (GET /wh/v2/user/{uuid})

1. **Receive UUID lookup**: REST Resources extracts the UUID path parameter and passes it to UserDbService.
   - From: caller
   - To: `whUsersApiRestControllers`
   - Protocol: REST

2. **Delegate to PlatformUserJdbiDao**: UserDbService calls `PlatformUserJdbiDao` with the UUID. No RO/RW routing needed — all platform user reads go to the read-only replica.
   - From: `whUsersApiUserService`
   - To: `whUsersApiPlatformUserDao`
   - Protocol: Direct (in-process)

3. **Execute join query**: PlatformUserJdbiDao runs a SQL query that joins the users table with the groups table to assemble the `PlatformUser` projection.
   - From: `whUsersApiPlatformUserDao`
   - To: `continuumWhUsersApiPostgresRo`
   - Protocol: JDBC/PostgreSQL

4. **Return PlatformUser**: The assembled response includes:
   - `id`, `group_id`, `platform`
   - `groupName`, `groupResources` (from the joined group)
   - `allowedResources` (user-level overrides)
   - `resources` (effective resource list)
   - `data` (user data: email, locale, name, username)
   - `createdAt`, `updatedAt`

5. **Return HTTP 200** with `PlatformUser` JSON; returns HTTP 404 if no user found for the UUID.

### Lookup by Username (GET /wh/v2/user/username/{username})

1. **Receive username lookup**: REST Resources extracts the `username` path parameter and optional `platform` query parameter.
   - From: caller
   - To: `whUsersApiRestControllers`
   - Protocol: REST

2. **Delegate to PlatformUserJdbiDao**: UserDbService calls `PlatformUserJdbiDao` with the username and optional platform qualifier.
   - From: `whUsersApiUserService`
   - To: `whUsersApiPlatformUserDao`
   - Protocol: Direct (in-process)

3. **Execute filtered join query**: PlatformUserJdbiDao runs a SQL query filtering on username (and platform if provided) and joining with groups.
   - From: `whUsersApiPlatformUserDao`
   - To: `continuumWhUsersApiPostgresRo`
   - Protocol: JDBC/PostgreSQL

4. **Return PlatformUser**: Same response shape as UUID lookup.

5. **Return HTTP 200** with `PlatformUser` JSON; returns HTTP 404 if no user found for the username.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User not found by UUID | `ResourceNotFoundException` | HTTP 404 |
| User not found by username | `ResourceNotFoundException` | HTTP 404 |
| Database unavailable | Unhandled exception | HTTP 500 |

## Sequence Diagram

```
Caller -> REST Resources: GET /wh/v2/user/username/{username}?platform=...
REST Resources -> UserDbService: getByUsername(username, platform)
UserDbService -> PlatformUserJdbiDao: findByUsername(username, platform)
PlatformUserJdbiDao -> PostgreSQL RO: SELECT u.*, g.name, g.resources FROM users u JOIN groups g ON u.group_id = g.id WHERE u.username = ? AND u.platform = ?
PostgreSQL RO --> PlatformUserJdbiDao: ResultSet (user+group join)
PlatformUserJdbiDao --> UserDbService: PlatformUser
UserDbService --> REST Resources: PlatformUser
REST Resources --> Caller: HTTP 200 {PlatformUser}
```

## Related

- Architecture dynamic view: `dynamic-wh-users-api-request-lifecycle`
- Related flows: [User CRUD](user-crud.md), [Request Lifecycle](request-lifecycle.md)
