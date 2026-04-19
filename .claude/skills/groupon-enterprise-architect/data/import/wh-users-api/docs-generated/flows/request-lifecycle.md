---
service: "wh-users-api"
title: "Request Lifecycle"
generated: "2026-03-03"
type: flow
flow_name: "request-lifecycle"
flow_type: synchronous
trigger: "Inbound HTTP request on any /wh/v2/ endpoint"
participants:
  - "whUsersApiRestControllers"
  - "whUsersApiUserService"
  - "whUsersApiGroupService"
  - "whUsersApiResourceService"
  - "whUsersApiUserDaoRouter"
  - "whUsersApiGroupDaoRouter"
  - "whUsersApiResourceDaoRouter"
  - "whUsersApiPlatformUserDao"
  - "continuumWhUsersApiPostgresRo"
  - "continuumWhUsersApiPostgresRw"
architecture_ref: "dynamic-wh-users-api-request-lifecycle"
---

# Request Lifecycle

## Summary

This flow describes the end-to-end path of any inbound HTTP request through the wh-users-api service. A request enters via a JAX-RS REST resource, is dispatched to the appropriate domain service, and the service delegates to a DAO router that selects either the read-only or read-write PostgreSQL endpoint based on the operation type. The result is serialized to JSON and returned to the caller.

## Trigger

- **Type**: api-call
- **Source**: Wolfhound CMS client or internal service calling `http://<vip>/wh/v2/<entity>/...`
- **Frequency**: Per-request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST Resources | Receives the inbound HTTP request; validates path and query parameters; routes to the correct service | `whUsersApiRestControllers` |
| UserDbService / GroupDbService / ResourceDbService | Applies business rules; orchestrates DAO calls | `whUsersApiUserService`, `whUsersApiGroupService`, `whUsersApiResourceService` |
| DB Router (User/Group/Resource) | Selects the RO datasource for reads and the RW datasource for writes | `whUsersApiUserDaoRouter`, `whUsersApiGroupDaoRouter`, `whUsersApiResourceDaoRouter` |
| PlatformUserJdbiDao | Executes join queries for platform user lookups | `whUsersApiPlatformUserDao` |
| PostgreSQL RO | Serves read queries | `continuumWhUsersApiPostgresRo` |
| PostgreSQL RW | Serves write operations | `continuumWhUsersApiPostgresRw` |

## Steps

1. **Receive request**: The Dropwizard Jersey container accepts the HTTP request on port 8080.
   - From: external caller
   - To: `whUsersApiRestControllers`
   - Protocol: REST (HTTP/JSON)

2. **Route to domain service**: The REST resource method dispatches the call to the appropriate service (UserDbService, GroupDbService, or ResourceDbService) based on the endpoint.
   - From: `whUsersApiRestControllers`
   - To: `whUsersApiUserService` / `whUsersApiGroupService` / `whUsersApiResourceService`
   - Protocol: Direct (in-process)

3. **Apply business logic**: The domain service validates inputs, checks referential integrity (e.g., UserDbService validates the `group_id` by querying GroupDbRouter), and prepares the DAO call.
   - From: `whUsersApiUserService`
   - To: `whUsersApiGroupDaoRouter` (for group reference validation) or own DAO router
   - Protocol: Direct (in-process)

4. **Select data source**: The DB router directs the call to either the RO or RW JDBI instance based on operation type (read = RO, write = RW).
   - From: `whUsersApiUserDaoRouter` / `whUsersApiGroupDaoRouter` / `whUsersApiResourceDaoRouter`
   - To: `continuumWhUsersApiPostgresRo` (reads) or `continuumWhUsersApiPostgresRw` (writes)
   - Protocol: JDBC/PostgreSQL

5. **Execute SQL**: The JDBI DAO executes the SQL query or mutation and returns the result.
   - From: PostgreSQL instance
   - To: DB router / DAO
   - Protocol: JDBC/PostgreSQL

6. **Return response**: The service returns the entity or list; the REST resource serializes it to JSON and sends the HTTP response.
   - From: `whUsersApiRestControllers`
   - To: external caller
   - Protocol: REST (HTTP/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Entity not found | `ResourceNotFoundException` caught by `ResourceNotFoundExceptionMapper` | HTTP 404 with `ErrorMessage` body |
| UUID conflict on create | `EntityConflictException` caught by `EntityConflictExceptionMapper` | HTTP 409 with `ErrorMessage` body |
| Invalid request body | `InvalidRequestException` / Jersey `ValidationException` caught by respective mappers | HTTP 400 or 422 with `ErrorMessage` body |
| Unhandled exception | `CommonExceptionMapper` / `WebExceptionMapper` | HTTP 500 with `ErrorMessage` body |
| Database unavailable | Exception propagates; no circuit breaker | HTTP 500; pod does NOT restart (health check for DB is disabled) |

## Sequence Diagram

```
Caller -> REST Resources: HTTP request (GET/POST/PUT/DELETE /wh/v2/...)
REST Resources -> DomainService: dispatch(entity, operation)
DomainService -> DBRouter: read(query) or write(mutation)
DBRouter -> PostgreSQL RO: SQL SELECT (reads)
DBRouter -> PostgreSQL RW: SQL INSERT/UPDATE/DELETE (writes)
PostgreSQL RO --> DBRouter: ResultSet
PostgreSQL RW --> DBRouter: rows affected
DBRouter --> DomainService: entity or void
DomainService --> REST Resources: entity or void
REST Resources --> Caller: HTTP 200/204/4xx/5xx + JSON body
```

## Related

- Architecture dynamic view: `dynamic-wh-users-api-request-lifecycle`
- Related flows: [User CRUD](user-crud.md), [Group CRUD](group-crud.md), [Resource CRUD](resource-crud.md), [Platform User Lookup](platform-user-lookup.md)
