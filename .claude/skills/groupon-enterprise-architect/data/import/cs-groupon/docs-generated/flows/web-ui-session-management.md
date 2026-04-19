---
service: "cs-groupon"
title: "Web UI Session Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "web-ui-session-management"
flow_type: synchronous
trigger: "CS agent navigates to the cyclops login page"
participants:
  - "continuumCsWebApp"
  - "continuumCsRedisCache"
  - "continuumCsAppDb"
architecture_ref: "dynamic-cs-groupon"
---

# Web UI Session Management

## Summary

cyclops uses Warden (v1.0.5) as its authentication middleware and CanCan (v1.6.5) for role-based authorization. When a CS agent logs in, Warden authenticates credentials against the CS application database, creates a session stored in Redis, and sets a session cookie. On every subsequent request, the session cookie is validated against Redis before CanCan checks whether the agent has permission to perform the requested action.

## Trigger

- **Type**: user-action
- **Source**: CS agent submits login credentials at the cyclops login page
- **Frequency**: Per agent login session; session validation occurs on every authenticated request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CS Web App | Hosts login UI; runs Warden middleware; enforces CanCan authorization | `continuumCsWebApp` |
| CS Redis Cache | Stores session data; session lookup on each request | `continuumCsRedisCache` |
| CS App Database | Stores CS agent credentials and role assignments | `continuumCsAppDb` |

## Steps

### Login

1. **Agent submits credentials**: CS agent POSTs username and password to the login endpoint.
   - From: `agent browser`
   - To: `continuumCsWebApp`
   - Protocol: HTTP POST

2. **Warden authenticates**: Warden middleware validates credentials against agent records in `continuumCsAppDb`.
   - From: `continuumCsWebApp`
   - To: `continuumCsAppDb`
   - Protocol: ActiveRecord / MySQL

3. **Session created**: On successful authentication, Warden writes session data to Redis.
   - From: `continuumCsWebApp`
   - To: `continuumCsRedisCache`
   - Protocol: Redis

4. **Session cookie set**: Web App returns HTTP response with session cookie to agent browser.
   - From: `continuumCsWebApp`
   - To: `agent browser`
   - Protocol: HTTP (Set-Cookie header)

5. **Agent redirected to CS home**: Browser follows redirect to the main CS dashboard.
   - From: `agent browser`
   - To: `continuumCsWebApp`
   - Protocol: HTTP GET

### Per-Request Authorization

6. **Session validated**: On each authenticated request, Warden reads the session cookie and looks up session data in Redis.
   - From: `continuumCsWebApp`
   - To: `continuumCsRedisCache`
   - Protocol: Redis

7. **CanCan authorization check**: CanCan evaluates the agent's role and permissions for the requested action.
   - From: `continuumCsWebApp` (CanCan within the request lifecycle)
   - To: `continuumCsAppDb` (loads agent role/permissions if not cached)
   - Protocol: ActiveRecord / MySQL

8. **Request processed or rejected**: If authorized, the request proceeds to the appropriate controller and action. If not, a 403 response is returned.
   - From: `continuumCsWebApp`
   - To: `agent browser`
   - Protocol: HTTP

### Logout

9. **Agent logs out**: CS agent clicks logout; Warden destroys the session.
   - From: `agent browser`
   - To: `continuumCsWebApp`
   - Protocol: HTTP DELETE / POST

10. **Session deleted from Redis**: Warden removes the session entry from `continuumCsRedisCache`.
    - From: `continuumCsWebApp`
    - To: `continuumCsRedisCache`
    - Protocol: Redis DEL

11. **Session cookie cleared**: Web App returns response clearing the session cookie.
    - From: `continuumCsWebApp`
    - To: `agent browser`
    - Protocol: HTTP (Set-Cookie: max-age=0)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid credentials | Warden returns authentication failure | Agent shown login error; no session created |
| Redis unavailable | Warden cannot read/write session | All authenticated requests fail; agents cannot log in or access the app |
| Session expired | Redis TTL causes key expiry; Warden detects missing session | Agent redirected to login page |
| Unauthorized action | CanCan raises `CanCan::AccessDenied` | Agent shown 403 page; action not executed |

## Sequence Diagram

```
Agent -> continuumCsWebApp: POST /login (credentials)
continuumCsWebApp -> continuumCsAppDb: Validate agent credentials
continuumCsWebApp -> continuumCsRedisCache: Write new session
continuumCsWebApp --> Agent: 302 Redirect + Set-Cookie

Agent -> continuumCsWebApp: GET /cs/dashboard (with session cookie)
continuumCsWebApp -> continuumCsRedisCache: Validate session
continuumCsWebApp -> continuumCsAppDb: Load agent role (CanCan)
continuumCsWebApp --> Agent: 200 CS Dashboard HTML

Agent -> continuumCsWebApp: POST /logout
continuumCsWebApp -> continuumCsRedisCache: Delete session
continuumCsWebApp --> Agent: 302 Redirect to login (cookie cleared)
```

## Related

- Architecture dynamic view: `dynamic-cs-groupon`
- Related flows: [Customer Issue Resolution](customer-issue-resolution.md)
